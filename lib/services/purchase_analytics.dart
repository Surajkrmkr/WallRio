import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Logs the paywall and purchase funnel to Firebase Analytics.
///
/// Funnel, in order:
///   paywall_view -> paywall_plan_select -> paywall_cta_tap -> purchase_launch
///   -> purchase_result (purchased | canceled | error | pending | restored)
///   -> purchase_success
/// Revenue is NOT logged here: Google Analytics already collects Play
/// purchases as `in_app_purchase`, and logging a second `purchase` event with
/// a value would double-count revenue.
/// plus paywall_dismiss, dropoff_offer_* and entitlement_check.
///
/// Logging is fire-and-forget: it never throws, never awaits on the UI path
/// and never carries personal data (no email, no account id).
class PurchaseAnalytics {
  PurchaseAnalytics._();

  /// Firebase limits: 40 characters per event or parameter name, 100 per
  /// string value, 25 parameters per event.
  static const int maxNameLength = 40;
  static const int maxValueLength = 100;
  static const int maxParams = 25;

  /// The last purchase the user started. Google reports a cancelled purchase
  /// with an empty product id, so the cancel is attributed to this one.
  static _Launch? _last;

  /// Turns arbitrary values into something Firebase accepts: nulls and
  /// non-finite numbers are dropped, booleans become "true" / "false", strings
  /// are trimmed to [maxValueLength] and parameter names are made safe.
  @visibleForTesting
  static Map<String, Object> sanitize(Map<String, Object?> params) {
    final out = <String, Object>{};
    for (final entry in params.entries) {
      if (out.length >= maxParams) break;
      final value = entry.value;
      if (value == null) continue;
      final key = _safeName(entry.key);
      if (key.isEmpty) continue;
      if (value is num) {
        if (value is double && !value.isFinite) continue;
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 'true' : 'false';
      } else {
        final text = value.toString();
        out[key] =
            text.length > maxValueLength ? text.substring(0, maxValueLength) : text;
      }
    }
    return out;
  }

  static String _safeName(String name) {
    var safe = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (safe.isNotEmpty && RegExp(r'^[0-9]').hasMatch(safe)) safe = 'p_$safe';
    return safe.length > maxNameLength ? safe.substring(0, maxNameLength) : safe;
  }

  /// What kind of product a Play/App Store id is, so revenue can be split in
  /// GA4: `pass` (28-day, 4-month, 1-year one-time access, including the offer
  /// twin), `lifetime`, `collection`, `subscription` or `other`.
  @visibleForTesting
  static String productKind(String? productId) {
    final id = (productId ?? '').toLowerCase();
    if (id.isEmpty) return 'other';
    if (RegExp(r'^com\.wallrio\.(monthly|quaterly|quarterly|yearly)_\d+(_dropoff|_nudge)?$')
        .hasMatch(id)) {
      return 'pass';
    }
    if (id.contains('lifetime')) return 'lifetime';
    if (id.contains('collection')) return 'collection';
    if (id == 'wallrio_pro' || id.contains('.pro.') || id.contains('subscription')) {
      return 'subscription';
    }
    return 'other';
  }

  // ---- Limited offers (exit, comeback, nudge) and pass reminders ----------

  /// Which limited offer the user is buying through (`exit`, `comeback` or
  /// `nudge`). Set when they tap the offer and cleared when the purchase ends,
  /// so purchase events can say which offer produced them: the 40% twin is
  /// sold by both the exit and the comeback offer.
  static String? _offerKind;
  static String? get offerKind => _offerKind;
  static void setOfferContext(String? kind) => _offerKind = kind;

  /// Offers already reported as seen on a surface in this app session, so a
  /// banner that rebuilds every second counts as one view.
  static final Set<String> _seenThisSession = <String>{};

  @visibleForTesting
  static void resetSession() {
    _seenThisSession.clear();
    _offerKind = null;
  }

  /// An offer was put in front of the user. [surface] is `sheet`,
  /// `home_banner` or `paywall`. Reported once per kind and surface per session.
  static void offerShown({
    required String kind,
    required String surface,
    String? productId,
    int? percentOff,
  }) {
    if (!_seenThisSession.add('$kind/$surface')) return;
    log('limited_offer_shown', {
      'offer_kind': kind,
      'surface': surface,
      'product_id': productId,
      'percent_off': percentOff,
    });
  }

  /// The user tapped the offer to buy. The purchase events that follow carry
  /// the same `offer_kind`.
  static void offerClaimed({
    required String kind,
    required String surface,
    String? productId,
    int? percentOff,
  }) {
    setOfferContext(kind);
    log('limited_offer_claim', {
      'offer_kind': kind,
      'surface': surface,
      'product_id': productId,
      'percent_off': percentOff,
    });
  }

  /// The user closed the offer without buying.
  static void offerDismissed({required String kind, required String surface}) {
    log('limited_offer_dismiss', {'offer_kind': kind, 'surface': surface});
  }

  /// The "your Pro is ending" reminder: [surface] is `banner` or
  /// `notification`. Reported once per surface per session.
  static void reminderShown({
    required String surface,
    int? daysLeft,
    String? productId,
  }) {
    if (!_seenThisSession.add('reminder/$surface')) return;
    log('pass_reminder_shown', {
      'surface': surface,
      'days_left': daysLeft,
      'product_id': productId,
    });
  }

  /// A reminder or offer notification was scheduled. [type] is `ending`,
  /// `ended` or `nudge`.
  static void notificationScheduled(String type, {String? productId}) {
    // The reminders are re-armed on every app start; report each type once
    // per session so the count means "users", not "launches".
    if (!_seenThisSession.add('notification/$type')) return;
    log('offer_notification_scheduled',
        {'notification_type': type, 'product_id': productId});
  }

  /// A pass ran out and the user is no longer Pro.
  static void passExpired(String productId) {
    if (!_seenThisSession.add('expired/$productId')) return;
    log('pass_expired', {'product_id': productId});
  }

  /// Adds `product_kind` to params that carry a `product_id`. A pass always
  /// reports as a pass, even where the caller can only say "lifetime" or
  /// "subscription"; for other products the caller's own kind is kept.
  @visibleForTesting
  static Map<String, Object?> withKind(Map<String, Object?> params) {
    final id = params['product_id']?.toString() ?? '';
    if (id.isEmpty) return {...params};
    final computed = productKind(id);
    final isOfferProduct = RegExp(r'_(dropoff|nudge)$').hasMatch(id);
    return {
      ...params,
      'product_kind':
          computed == 'pass' ? 'pass' : (params['product_kind'] ?? computed),
      // Which offer sold this pass. Only for the discounted twins, and only
      // when the caller did not say already.
      if (isOfferProduct && _offerKind != null && params['offer_kind'] == null)
        'offer_kind': _offerKind,
    };
  }

  /// Logs one event. Safe to call from anywhere.
  static void log(String name, [Map<String, Object?> params = const {}]) {
    try {
      final withKind = PurchaseAnalytics.withKind(params);
      unawaited(
        FirebaseAnalytics.instance
            .logEvent(name: _safeName(name), parameters: sanitize(withKind))
            .catchError((Object _) {}),
      );
    } catch (_) {
      // Analytics must never break a purchase.
    }
  }

  /// The user started a purchase (Play or the App Store sheet is about to open).
  static void launched({
    required String productId,
    required double price,
    required String currency,
    Map<String, Object?> extra = const {},
  }) {
    _last = _Launch(productId, extra['base_plan'], extra['offer_id']);
    log('purchase_launch', {
      'product_id': productId,
      'price': price,
      'currency': currency,
      ...extra,
    });
    try {
      unawaited(
        FirebaseAnalytics.instance
            .logBeginCheckout(
              value: price,
              currency: currency,
              items: [
                AnalyticsEventItem(
                  itemId: productId,
                  itemCategory: productKind(productId),
                ),
              ],
            )
            .catchError((Object _) {}),
      );
    } catch (_) {}
  }

  /// What the store reported back. [status] is one of purchased, canceled,
  /// error, pending, restored, launch_failed, no_entitlement.
  static void result(
    String productId,
    String status, {
    String? code,
    String? detail,
    Map<String, Object?> extra = const {},
  }) {
    final last = _last;
    final known = productId.isEmpty && last != null;
    log('purchase_result', {
      'product_id': known ? last.productId : productId,
      'purchase_status': status,
      'error_code': code,
      'error_detail': detail,
      if (known) 'base_plan': last.basePlan,
      if (known) 'offer_id': last.offerId,
      ...extra,
    });
    // A cancelled or failed purchase ends the offer attempt.
    if (status == 'canceled' || status == 'error' || status == 'launch_failed') {
      _offerKind = null;
    }
  }

  /// A new purchase was completed and access was granted.
  static void succeeded(String productId,
      {Map<String, Object?> extra = const {}}) {
    log('purchase_success', {'product_id': productId, ...extra});
    // The sale is complete; the next purchase is a new decision.
    _offerKind = null;
  }
}

class _Launch {
  final String productId;
  final Object? basePlan;
  final Object? offerId;
  const _Launch(this.productId, this.basePlan, this.offerId);
}
