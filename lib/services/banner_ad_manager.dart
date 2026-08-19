import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/consent_manager.dart';
import 'package:wallrio/services/packages/export.dart';

/// Centralized Banner Ad Manager maintaining a 4-item preloaded queue
/// with lightweight performance telemetry, instantaneous consumption, and automatic replenishment.
class BannerAdManager {
  BannerAdManager._internal();
  static final BannerAdManager instance = BannerAdManager._internal();

  static const int _targetQueueSize = 4;
  static const int _maxQueueSize = 4;

  final String _bannerAdUnitId = Platform.isIOS
      ? 'ca-app-pub-4861691653340010/2292486372'
      : 'ca-app-pub-4861691653340010/8536832813';

  final List<BannerAd> _readyQueue = <BannerAd>[];
  final Set<BannerAd> _activeInUse = <BannerAd>{};
  int _inFlightCount = 0;
  int _consecutiveFailures = 0;
  Timer? _retryTimer;
  bool _isWarmedUp = false;

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

  final Set<BannerAd> _impressedAds = <BannerAd>{};

  /// Current number of ready preloaded banners in the queue.
  int get readyCount => _readyQueue.length;

  /// Rolling average banner load time in milliseconds.
  int get averageLoadTimeMs =>
      _successfulLoadsCount > 0 ? (_totalLoadTimeMs / _successfulLoadsCount).round() : 0;

  int get successfulLoadsCount => _successfulLoadsCount;
  int get failedLoadsCount => _failedLoadsCount;
  int get emptyQueueEventsCount => _emptyQueueEventsCount;
  int get requestedCount => _requestedCount;
  int get displayedCount => _displayedCount;
  int get impressionCount => _impressionCount;
  int get disposedCount => _disposedCount;
  int get disposedBeforeImpressionCount => _disposedBeforeImpressionCount;

  /// Preload banners in the background upon app launch or initialization.
  void warmUp() {
    if (_isWarmedUp || UserProfile.plusMember || !ConsentManager.instance.canRequestAds) return;
    _isWarmedUp = true;
    _logTelemetry('Queue Warm-up started (Target queue depth: $_targetQueueSize)');
    _replenishQueue();
  }

  /// Acquires a unique, ready-to-display [BannerAd] from the preload queue.
  /// - Returns a ready [BannerAd] instantly (0ms) if available and marks it in use.
  /// - Returns `null` immediately if the queue is empty (never blocks the UI thread).
  /// - Triggers asynchronous background queue replenishment.
  BannerAd? acquireBanner({
    String screen = 'UnknownScreen',
    String placement = 'Banner',
  }) {
    _requestedCount++;
    _logTelemetry(
      'Banner Requested',
      screen: screen,
      placement: placement,
    );

    if (UserProfile.plusMember || !ConsentManager.instance.canRequestAds) {
      return null;
    }

    // 1. Pop from ready queue if available (Instantaneous 0ms return)
    while (_readyQueue.isNotEmpty) {
      final ad = _readyQueue.removeAt(0);
      if (_activeInUse.contains(ad)) {
        continue;
      }
      _activeInUse.add(ad);
      _displayedCount++;
      _logTelemetry(
        'Banner Displayed',
        screen: screen,
        placement: placement,
      );
      // Immediately schedule background replenishment
      _replenishQueue();
      return ad;
    }

    // 2. Queue empty: return null immediately and trigger background refill
    _emptyQueueEventsCount++;
    _logTelemetry(
      'Empty Queue Event (Returned null immediately, triggering background refill)',
      screen: screen,
      placement: placement,
    );
    _replenishQueue();
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
    final bool hadImpression = _impressedAds.remove(ad);
    if (!hadImpression) {
      _disposedBeforeImpressionCount++;
    }
    _activeInUse.remove(ad);
    _readyQueue.remove(ad);
    _disposedCount++;
    _logTelemetry(
      hadImpression
          ? 'Banner Disposed (Impression recorded)'
          : 'Banner Disposed BEFORE Impression',
      screen: screen,
      placement: placement,
    );

    try {
      ad.dispose();
    } catch (e) {
      debugPrint('[BannerTelemetry] Error disposing banner: $e');
    }
    _replenishQueue();
  }

  /// Automatically fills the preload queue up to [_targetQueueSize].
  /// Throttles concurrent in-flight loads to max 2 to prevent server-side request starvation.
  void _replenishQueue() {
    if (UserProfile.plusMember || !ConsentManager.instance.canRequestAds) {
      clear();
      return;
    }

    final int remainingCapacity = _targetQueueSize - (_readyQueue.length + _inFlightCount);
    if (remainingCapacity <= 0 || (_readyQueue.length + _inFlightCount) >= _maxQueueSize) {
      return;
    }

    // Strict throttle: maximum 2 concurrent in-flight requests to prevent server starvation
    final int toLoad = min(remainingCapacity, max(0, 2 - _inFlightCount));
    if (toLoad <= 0) {
      return;
    }

    for (int i = 0; i < toLoad; i++) {
      _loadPreloadBanner();
    }
  }

  void _loadPreloadBanner() {
    if ((_readyQueue.length + _inFlightCount) >= _maxQueueSize ||
        !ConsentManager.instance.canRequestAds) {
      return;
    }

    _inFlightCount++;
    final stopwatch = Stopwatch()..start();

    BannerAd? banner;
    banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          stopwatch.stop();
          _inFlightCount = max(0, _inFlightCount - 1);
          _consecutiveFailures = 0;
          _successfulLoadsCount++;
          _totalLoadTimeMs += stopwatch.elapsedMilliseconds;

          _readyQueue.add(ad as BannerAd);
          _logTelemetry(
            'Banner Loaded in ${stopwatch.elapsedMilliseconds}ms (Avg: ${averageLoadTimeMs}ms)',
          );

          // If more banners needed, continue filling the queue
          _replenishQueue();
        },
        onAdImpression: (ad) {
          _impressionCount++;
          _impressedAds.add(ad as BannerAd);
          _logTelemetry('Banner Impression Registered (Total Impressions: $_impressionCount)');
        },
        onAdFailedToLoad: (ad, err) {
          stopwatch.stop();
          _inFlightCount = max(0, _inFlightCount - 1);
          _failedLoadsCount++;
          ad.dispose();

          _logTelemetry(
            'Banner Failed to load in ${stopwatch.elapsedMilliseconds}ms ($err)',
          );
          _handleLoadFailure();
        },
      ),
    );

    banner.load();
  }

  void _handleLoadFailure() {
    _consecutiveFailures++;
    // Exponential backoff: 3s, 6s, 12s, max 30s
    final int delaySec = min(30, 3 * (1 << min(3, _consecutiveFailures - 1)));
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (!UserProfile.plusMember) {
        _replenishQueue();
      }
    });
  }

  /// Clears all preloaded ads and cancels pending timers (e.g. on Pro purchase).
  void clear() {
    _retryTimer?.cancel();
    _retryTimer = null;
    for (final ad in _readyQueue) {
      try {
        ad.dispose();
      } catch (_) {}
    }
    _readyQueue.clear();
    for (final ad in _activeInUse) {
      try {
        ad.dispose();
      } catch (_) {}
    }
    _activeInUse.clear();
    _impressedAds.clear();
    _inFlightCount = 0;
    _isWarmedUp = false;
  }

  void _logTelemetry(String event, {String? screen, String? placement}) {
    if (!kDebugMode) return;
    final screenTag = screen != null ? ' [Screen: $screen]' : '';
    final placeTag = placement != null ? ' [Placement: $placement]' : '';
    final double matchRate = _requestedCount > 0 ? (_successfulLoadsCount / _requestedCount) * 100 : 0;
    final double impressionRate = _displayedCount > 0 ? (_impressionCount / _displayedCount) * 100 : 0;
    debugPrint(
      '[BannerTelemetry]$screenTag$placeTag $event | Queue: ${_readyQueue.length}/$_targetQueueSize | InFlight: $_inFlightCount | Displayed: $_displayedCount | Impressions: $_impressionCount (${impressionRate.toStringAsFixed(1)}%) | MatchRate: ${matchRate.toStringAsFixed(1)}%',
    );
  }
}
