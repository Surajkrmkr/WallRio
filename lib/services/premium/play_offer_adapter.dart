import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:wallrio/services/plan_offers.dart';

/// Turns Google Play subscription products into the platform-free
/// [OfferView]s that [PlanOffers] works on.
class PlayOfferAdapter {
  PlayOfferAdapter._();

  /// [index] is the product's position in the list it came from, so the
  /// chosen offer can be mapped back to a purchasable product.
  static OfferView? toOfferView(Object product, int index) {
    if (product is! GooglePlayProductDetails ||
        product.subscriptionIndex == null) {
      return null;
    }
    final offers = product.productDetails.subscriptionOfferDetails;
    final i = product.subscriptionIndex!;
    if (offers == null || i >= offers.length) return null;
    final offer = offers[i];
    return OfferView(
      index: index,
      basePlanId: offer.basePlanId,
      offerId: offer.offerId,
      phases: [
        for (final ph in offer.pricingPhases)
          PhaseView(
            formattedPrice: ph.formattedPrice,
            price: ph.priceAmountMicros / 1000000.0,
            billingPeriod: ph.billingPeriod,
            cycleCount: ph.billingCycleCount,
          ),
      ],
    );
  }
}
