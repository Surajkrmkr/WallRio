import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Debug-only: shows how a Play trial or discount offer looks on the paywall
/// without creating anything in Play Console.
///
///   flutter run --dart-define=FAKE_PLAY_OFFER=trial      (or: discount, dropoff)
///
/// It swaps the real subscription entries for a fixed set with a fake offer
/// and blocks purchasing them. It does nothing in release builds or when the
/// define is not set.
class DebugOfferPreview {
  DebugOfferPreview._();

  static const String mode = String.fromEnvironment('FAKE_PLAY_OFFER');
  static bool get enabled =>
      kDebugMode && (mode == 'trial' || mode == 'discount' || mode == 'dropoff');

  static const String tokenPrefix = 'preview-';

  static bool isPreviewProduct(Object p) =>
      p is GooglePlayProductDetails &&
      (p.offerToken ?? '').startsWith(tokenPrefix);

  static PricingPhaseWrapper _phase(String price, int micros, String period,
          {int cycles = 0}) =>
      PricingPhaseWrapper(
        billingCycleCount: cycles,
        billingPeriod: period,
        formattedPrice: price,
        priceAmountMicros: micros,
        priceCurrencyCode: 'INR',
        recurrenceMode: RecurrenceMode.infiniteRecurring,
      );

  static SubscriptionOfferDetailsWrapper _offer(
          String plan, String? id, List<PricingPhaseWrapper> phases) =>
      SubscriptionOfferDetailsWrapper(
        basePlanId: plan,
        offerId: id,
        offerTags: const [],
        offerIdToken: '$tokenPrefix$plan-${id ?? 'base'}',
        pricingPhases: phases,
      );

  static final List<GooglePlayProductDetails> _fake = _build();

  static List<GooglePlayProductDetails> _build() {
    final offers = <SubscriptionOfferDetailsWrapper>[
      _offer('monthly', null, [_phase('₹59.00', 59000000, 'P1M')]),
      _offer('quarterly', null, [_phase('₹149.00', 149000000, 'P4M')]),
      _offer('yearly', null, [_phase('₹499.00', 499000000, 'P1Y')]),
      if (mode == 'trial')
        _offer('yearly', 'yearly-3d-trial', [
          _phase('Free', 0, 'P3D', cycles: 1),
          _phase('₹499.00', 499000000, 'P1Y'),
        ]),
      if (mode == 'dropoff')
        _offer('yearly', 'dropoff-40', [
          _phase('₹299.00', 299000000, 'P1Y', cycles: 1),
          _phase('₹499.00', 499000000, 'P1Y'),
        ]),
      if (mode == 'discount')
        _offer('yearly', 'yearly-festive', [
          _phase('₹299.00', 299000000, 'P1Y', cycles: 1),
          _phase('₹499.00', 499000000, 'P1Y'),
        ]),
    ];
    return GooglePlayProductDetails.fromProductDetails(
      ProductDetailsWrapper(
        description: 'WallRio Pro',
        name: 'WallRio Pro',
        productId: 'wallrio_pro',
        productType: ProductType.subs,
        title: 'WallRio Pro',
        subscriptionOfferDetails: offers,
      ),
    );
  }

  /// Real non-subscription products (lifetime, collections) stay; the real
  /// subscription entries are replaced by the fake set.
  static List<T> apply<T extends Object>(List<T> real) {
    final keep = real
        .where((p) => !(p is GooglePlayProductDetails && p.subscriptionIndex != null))
        .toList();
    return [...keep, ..._fake.cast<T>()];
  }
}
