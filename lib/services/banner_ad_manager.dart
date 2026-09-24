import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/consent_manager.dart';
import 'package:wallrio/services/packages/export.dart';

/// Ownership state of a single [BannerAd] instance tracked by [BannerAdManager].
///
/// Every BannerAd we ever create must be in exactly one of these states.
/// This exists specifically to make AdMob's server-side banner auto-refresh
/// safe: auto-refresh re-fires [BannerAdListener.onAdLoaded]/`onAdImpression`
/// on an ad instance we already own (whether it's sitting in the ready queue
/// or currently displayed), and those re-fires must never be mistaken for a
/// brand-new preloaded instance.
enum _BannerOwnership {
  /// `.load()` has been called; the network response hasn't landed yet.
  loading,

  /// Successfully loaded and sitting in [BannerAdManager._readyQueue],
  /// not yet handed to a widget.
  ready,

  /// Popped from the queue via [BannerAdManager.acquireBanner] and currently
  /// owned/displayed by a widget.
  active,

  /// Released/failed/discarded. Terminal state — never reused.
  disposed,
}

class _QueuedBanner {
  const _QueuedBanner(this.ad, this.adUnitId);

  final BannerAd ad;
  final String adUnitId;
}

/// Centralized Banner Ad Manager maintaining a 4-item preloaded queue
/// with lightweight performance telemetry, instantaneous consumption, and automatic replenishment.
class BannerAdManager {
  BannerAdManager._internal();
  static final BannerAdManager instance = BannerAdManager._internal();

  // --- DIAGNOSTIC ONLY: singleton verification ---
  // Increments every time `BannerAdManager._internal()` is constructed.
  // Only `instance` above ever constructs one, so this must stay 1 for the
  // life of the app. Used to prove there is exactly one manager instance.
  static int _constructedInstanceCount = 0;
  final int instanceId = ++_constructedInstanceCount;

  static const int _targetQueueSize = 4;
  static const int _maxQueueSize = 4;

  static const String _defaultBannerAdUnitId =
      'ca-app-pub-4861691653340010/8536832813';
  final String _iosBannerAdUnitId = Platform.isIOS
      ? 'ca-app-pub-4861691653340010/2292486372'
      : _defaultBannerAdUnitId;

  final List<_QueuedBanner> _readyQueue = <_QueuedBanner>[];
  final Set<BannerAd> _activeInUse = <BannerAd>{};
  final Map<BannerAd, String> _adUnitIds = <BannerAd, String>{};
  final Map<String, int> _inFlightByUnit = <String, int>{};
  int _inFlightCount = 0;
  int _consecutiveFailures = 0;
  Timer? _retryTimer;
  bool _isWarmedUp = false;

  // Single source of truth for "what state is this exact BannerAd instance
  // in right now". Keyed by object identity (BannerAd does not override
  // == / hashCode, so Map/Set lookups here are already identity-based —
  // this is intentionally NOT relying on hashCode alone as an ownership
  // proxy; it is a per-instance state record consulted before every
  // queue/active-set mutation).
  final Map<BannerAd, _BannerOwnership> _ownership =
      <BannerAd, _BannerOwnership>{};

  // --- Telemetry Metrics ---
  int _totalLoadTimeMs = 0;
  int _successfulLoadsCount = 0;
  int _failedLoadsCount = 0;
  int _emptyQueueEventsCount = 0;
  int _requestedCount = 0;
  int _displayedCount = 0;
  int _impressionCount = 0;
  int _disposedCount = 0;
  int _disposedBeforeImpressionCount = 0;

  // DIAGNOSTIC ONLY: counters for the explicit lifecycle-safety events.
  int _duplicateInsertAttempts = 0;
  int _queueOverflowAttempts = 0;
  int _refreshCallbackCount = 0;

  final Set<BannerAd> _impressedAds = <BannerAd>{};

  /// Current number of ready preloaded banners in the queue.
  int get readyCount => _readyQueue.length;

  /// Rolling average banner load time in milliseconds.
  int get averageLoadTimeMs => _successfulLoadsCount > 0
      ? (_totalLoadTimeMs / _successfulLoadsCount).round()
      : 0;

  int get successfulLoadsCount => _successfulLoadsCount;
  int get failedLoadsCount => _failedLoadsCount;
  int get emptyQueueEventsCount => _emptyQueueEventsCount;
  int get requestedCount => _requestedCount;
  int get displayedCount => _displayedCount;
  int get impressionCount => _impressionCount;
  int get disposedCount => _disposedCount;
  int get disposedBeforeImpressionCount => _disposedBeforeImpressionCount;

  // DIAGNOSTIC ONLY.
  int get inFlightCount => _inFlightCount;
  int get duplicateInsertAttempts => _duplicateInsertAttempts;
  int get queueOverflowAttempts => _queueOverflowAttempts;
  int get refreshCallbackCount => _refreshCallbackCount;

  /// Preload banners in the background upon app launch or initialization.
  void warmUp() {
    if (_isWarmedUp ||
        UserProfile.plusMember ||
        !ConsentManager.instance.canRequestAds) {
      return;
    }
    _isWarmedUp = true;
    _logTelemetry(
        'Queue Warm-up started (Target queue depth: $_targetQueueSize)');
    _replenishQueue(adUnitId: _defaultBannerAdUnitId, source: 'warmUp');
  }

  /// Acquires a unique, ready-to-display [BannerAd] from the preload queue.
  /// - Returns a ready [BannerAd] instantly (0ms) if available and marks it in use.
  /// - Returns `null` immediately if the queue is empty (never blocks the UI thread).
  /// - Triggers asynchronous background queue replenishment.
  ///
  /// [source] is a DIAGNOSTIC-ONLY tag identifying the calling code path
  /// (e.g. 'initState', 'widgetRetry#1', 'widgetRetry#2'). It has no effect
  /// on queue/concurrency behavior — it is only threaded into telemetry so
  /// requests can be attributed to their origin.
  BannerAd? acquireBanner({
    String screen = 'UnknownScreen',
    String placement = 'Banner',
    String source = 'acquire',
    String adUnitId = _defaultBannerAdUnitId,
  }) {
    _requestedCount++;
    _logTelemetry(
      'Banner Requested',
      screen: screen,
      placement: placement,
      source: source,
    );

    if (UserProfile.plusMember || !ConsentManager.instance.canRequestAds) {
      return null;
    }

    // 1. Pop from ready queue if available (Instantaneous 0ms return)
    while (_readyQueue.isNotEmpty) {
      final entryIndex = _readyQueue
          .indexWhere((entry) => entry.adUnitId == _resolveUnitId(adUnitId));
      if (entryIndex < 0) {
        break;
      }
      final entry = _readyQueue.removeAt(entryIndex);
      final ad = entry.ad;
      // Ownership guard: only a banner genuinely in the `ready` state may be
      // handed out. This is the single-owner check — it rejects an ad that
      // is somehow already active, already disposed, or (defensively)
      // still loading, rather than trusting queue membership alone.
      if (_ownership[ad] != _BannerOwnership.ready ||
          _activeInUse.contains(ad)) {
        _duplicateInsertAttempts++;
        _logTelemetry(
          'DUPLICATE_BANNER_INSERT (acquire skipped stale ready-queue entry, ownership=${_ownership[ad]})',
          screen: screen,
          placement: placement,
          source: source,
        );
        continue;
      }
      _ownership[ad] = _BannerOwnership.active;
      _activeInUse.add(ad);
      _displayedCount++;
      _logTelemetry(
        'Banner Displayed',
        screen: screen,
        placement: placement,
        source: source,
      );
      // Immediately schedule background replenishment
      _replenishQueue(adUnitId: adUnitId, source: 'acquire(hit)');
      return ad;
    }

    // 2. Queue empty: return null immediately and trigger background refill
    _emptyQueueEventsCount++;
    _logTelemetry(
      'Empty Queue Event (Returned null immediately, triggering background refill)',
      screen: screen,
      placement: placement,
      source: source,
    );
    _replenishQueue(adUnitId: adUnitId, source: 'acquire(miss)');
    return null;
  }

  /// Disposes an acquired banner when its widget is unmounted.
  /// Each banner is used only once and never recycled into the widget tree.
  void releaseBanner(
    BannerAd? ad, {
    String screen = 'UnknownScreen',
    String placement = 'Banner',
  }) {
    if (ad == null) return;
    if (_ownership[ad] == _BannerOwnership.disposed) {
      // Already disposed via a failed-load/overflow/refresh path — never
      // dispose the same instance twice.
      return;
    }
    final bool hadImpression = _impressedAds.remove(ad);
    if (!hadImpression) {
      _disposedBeforeImpressionCount++;
    }
    _activeInUse.remove(ad);
    _readyQueue.removeWhere((entry) => entry.ad == ad);
    _ownership[ad] = _BannerOwnership.disposed;
    _disposedCount++;
    _logTelemetry(
      hadImpression
          ? 'Banner Disposed (Impression recorded)'
          : 'Banner Disposed BEFORE Impression',
      screen: screen,
      placement: placement,
      source: 'release',
    );

    try {
      ad.dispose();
    } catch (e) {
      debugPrint('[BannerTelemetry] Error disposing banner: $e');
    }
    _replenishQueue(adUnitId: _adUnitIds[ad], source: 'release');
  }

  /// Automatically fills the preload queue up to [_targetQueueSize].
  /// Throttles concurrent in-flight loads to max 2 to prevent server-side request starvation.
  ///
  /// [source] is DIAGNOSTIC-ONLY: identifies which caller triggered this
  /// replenish pass (warmUp / acquire(hit) / acquire(miss) / release /
  /// onLoaded-chain / manager-backoff). Does not alter queue/concurrency logic.
  void _replenishQueue({String? adUnitId, String source = 'unknown'}) {
    if (UserProfile.plusMember || !ConsentManager.instance.canRequestAds) {
      clear();
      return;
    }

    final unit = _resolveUnitId(adUnitId ?? _defaultBannerAdUnitId);
    final readyForUnit =
        _readyQueue.where((entry) => entry.adUnitId == unit).length;
    final inFlightForUnit = _inFlightByUnit[unit] ?? 0;
    final int remainingCapacity =
        _targetQueueSize - (readyForUnit + inFlightForUnit);
    if (remainingCapacity <= 0 ||
        readyForUnit + inFlightForUnit >= _maxQueueSize) {
      return;
    }

    // Strict throttle: maximum 2 concurrent in-flight requests to prevent server starvation
    final int toLoad = min(remainingCapacity, max(0, 2 - _inFlightCount));
    if (toLoad <= 0) {
      return;
    }

    for (int i = 0; i < toLoad; i++) {
      _loadPreloadBanner(adUnitId: unit, source: source);
    }
  }

  void _loadPreloadBanner({
    String adUnitId = _defaultBannerAdUnitId,
    String source = 'unknown',
  }) {
    final unit = _resolveUnitId(adUnitId);
    final readyForUnit =
        _readyQueue.where((entry) => entry.adUnitId == unit).length;
    final inFlightForUnit = _inFlightByUnit[unit] ?? 0;
    if (readyForUnit + inFlightForUnit >= _maxQueueSize ||
        !ConsentManager.instance.canRequestAds) {
      return;
    }

    _inFlightCount++;
    _inFlightByUnit[unit] = inFlightForUnit + 1;
    final stopwatch = Stopwatch()..start();
    // DIAGNOSTIC ONLY: full identification of this specific load() call.
    debugPrint(
      '[BannerTelemetry][LOAD_CALL] ts=${DateTime.now().toIso8601String()} '
      'instanceId=$instanceId source=$source queueDepth=${_readyQueue.length}/$_targetQueueSize '
      'inFlight=$_inFlightCount(afterIncrement)',
    );

    BannerAd? banner;
    banner = BannerAd(
      adUnitId: unit,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final bannerAd = ad as BannerAd;
          final ownership = _ownership[bannerAd];

          // AdMob's ad-unit-level auto-refresh re-fires onAdLoaded on an
          // ad instance we already own (ready or active), on its own
          // timer, with no corresponding `.load()` call from us. Only the
          // FIRST onAdLoaded for a given instance (while it is still
          // `loading`) represents a genuine new preload — every subsequent
          // fire is a refresh callback and must never touch the queue,
          // in-flight count, or success counters again, or the same ad
          // ends up duplicated into _readyQueue on every refresh cycle.
          if (ownership != _BannerOwnership.loading) {
            _refreshCallbackCount++;
            _logTelemetry(
              'BANNER_REFRESH_CALLBACK (ownership=$ownership, ignored for queue/counters — '
              'ad refreshed its creative in place, no new preload)',
              source: source,
            );
            return;
          }

          stopwatch.stop();
          _inFlightCount = max(0, _inFlightCount - 1);
          _inFlightByUnit[unit] = max(0, (_inFlightByUnit[unit] ?? 1) - 1);
          _consecutiveFailures = 0;
          _successfulLoadsCount++;
          _totalLoadTimeMs += stopwatch.elapsedMilliseconds;

          if (_readyQueue.any((entry) => entry.ad == bannerAd)) {
            // Defensive: should be unreachable given the ownership check
            // above, but never insert the same instance twice.
            _duplicateInsertAttempts++;
            _logTelemetry(
              'DUPLICATE_BANNER_INSERT (already present in ready queue)',
              source: source,
            );
            return;
          }

          if (_readyQueue.length >= _maxQueueSize) {
            // Defensive: capacity was checked before dispatching this load,
            // but never let a late-arriving load push the queue past its cap.
            _queueOverflowAttempts++;
            _ownership[bannerAd] = _BannerOwnership.disposed;
            _logTelemetry(
              'QUEUE_OVERFLOW_ATTEMPT (queue already at $_maxQueueSize, discarding extra banner)',
              source: source,
            );
            try {
              bannerAd.dispose();
            } catch (_) {}
            return;
          }

          _ownership[bannerAd] = _BannerOwnership.ready;
          _adUnitIds[bannerAd] = unit;
          _readyQueue.add(_QueuedBanner(bannerAd, _resolveUnitId(adUnitId)));
          _logTelemetry(
            'Banner Loaded in ${stopwatch.elapsedMilliseconds}ms (Avg: ${averageLoadTimeMs}ms)',
            source: source,
          );

          // If more banners needed, continue filling the queue
          _replenishQueue(adUnitId: unit, source: 'onLoaded-chain');
        },
        onAdImpression: (ad) {
          // Impressions are a genuine revenue signal regardless of
          // ownership state (an active, displayed banner refreshing its
          // creative can legitimately record additional impressions) —
          // intentionally NOT gated by ownership.
          _impressionCount++;
          _impressedAds.add(ad as BannerAd);
          _logTelemetry(
              'Banner Impression Registered (Total Impressions: $_impressionCount)');
        },
        onAdFailedToLoad: (ad, err) {
          final bannerAd = ad as BannerAd;
          final ownership = _ownership[bannerAd];

          if (ownership != _BannerOwnership.loading) {
            // A refresh attempt failed on an ad we already own (ready or
            // active) — this is not our original in-flight preload failing,
            // so don't touch _inFlightCount/_failedLoadsCount/backoff for it.
            _refreshCallbackCount++;
            _logTelemetry(
              'BANNER_REFRESH_CALLBACK (refresh failed, ownership=$ownership)',
              source: source,
            );
            return;
          }

          stopwatch.stop();
          _inFlightCount = max(0, _inFlightCount - 1);
          _inFlightByUnit[unit] = max(0, (_inFlightByUnit[unit] ?? 1) - 1);
          _failedLoadsCount++;
          _ownership[bannerAd] = _BannerOwnership.disposed;
          try {
            bannerAd.dispose();
          } catch (_) {}

          _logTelemetry(
            'Banner Failed to load in ${stopwatch.elapsedMilliseconds}ms ($err)',
            source: source,
          );
          _handleLoadFailure(unit);
        },
      ),
    );

    _ownership[banner] = _BannerOwnership.loading;
    banner.load();
  }

  void _handleLoadFailure(String unit) {
    _consecutiveFailures++;
    // Exponential backoff: 3s, 6s, 12s, max 30s
    final int delaySec = min(30, 3 * (1 << min(3, _consecutiveFailures - 1)));
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (!UserProfile.plusMember) {
        _replenishQueue(adUnitId: unit, source: 'manager-backoff');
      }
    });
  }

  /// Clears all preloaded ads and cancels pending timers (e.g. on Pro purchase).
  void clear() {
    _retryTimer?.cancel();
    _retryTimer = null;
    for (final entry in _readyQueue) {
      final ad = entry.ad;
      _ownership[ad] = _BannerOwnership.disposed;
      try {
        ad.dispose();
      } catch (_) {}
    }
    _readyQueue.clear();
    for (final ad in _activeInUse) {
      _ownership[ad] = _BannerOwnership.disposed;
      try {
        ad.dispose();
      } catch (_) {}
    }
    _activeInUse.clear();
    _impressedAds.clear();
    _inFlightCount = 0;
    _inFlightByUnit.clear();
    _adUnitIds.clear();
    _isWarmedUp = false;
  }

  String _resolveUnitId(String adUnitId) => Platform.isIOS
      ? _iosBannerAdUnitId
      : (adUnitId.isEmpty ? _defaultBannerAdUnitId : adUnitId);

  void _logTelemetry(String event,
      {String? screen, String? placement, String? source}) {
    if (!kDebugMode) return;
    final screenTag = screen != null ? ' [Screen: $screen]' : '';
    final placeTag = placement != null ? ' [Placement: $placement]' : '';
    // DIAGNOSTIC ONLY: source/instance tag, does not affect ad behavior.
    final sourceTag = source != null ? ' [Source: $source]' : '';
    final double matchRate = _requestedCount > 0
        ? (_successfulLoadsCount / _requestedCount) * 100
        : 0;
    final double impressionRate =
        _displayedCount > 0 ? (_impressionCount / _displayedCount) * 100 : 0;
    debugPrint(
      '[BannerTelemetry]$screenTag$placeTag$sourceTag $event | ts=${DateTime.now().toIso8601String()} | instanceId=$instanceId | Queue: ${_readyQueue.length}/$_targetQueueSize | InFlight: $_inFlightCount | Displayed: $_displayedCount | Impressions: $_impressionCount (${impressionRate.toStringAsFixed(1)}%) | MatchRate: ${matchRate.toStringAsFixed(1)}%',
    );
  }
}
