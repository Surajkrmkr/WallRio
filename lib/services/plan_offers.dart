/// Offer-aware plan selection, free of Flutter and platform types so it can be
/// unit tested.
///
/// Google Play returns one entry per *offer* of a subscription base plan (the
/// plain base plan plus every free-trial or discount offer the user is
/// eligible for). The paywall should show one card per plan, so for each base
/// plan this picks the best offer, and describes it for the UI.
///
/// Existing subscribers are unaffected: a plain base plan has a single pricing
/// phase, which is also its recurring phase.
library;

enum OfferKind { none, freeTrial, discount }

class PhaseView {
  /// Localised price as formatted by Play, e.g. "₹499.00".
  final String formattedPrice;

  /// Price in major units (0 for a free phase).
  final double price;

  /// ISO-8601 duration of one billing cycle, e.g. P1Y, P1M, P3D.
  final String billingPeriod;

  /// How many cycles this phase lasts (0 for an unlimited recurring phase).
  final int cycleCount;

  const PhaseView({
    required this.formattedPrice,
    required this.price,
    required this.billingPeriod,
    required this.cycleCount,
  });

  bool get isFree => price == 0;
}

class OfferView {
  /// Position of the matching product in the provider's list.
  final int index;
  final String basePlanId;
  final String? offerId;
  final List<PhaseView> phases;

  const OfferView({
    required this.index,
    required this.basePlanId,
    required this.offerId,
    required this.phases,
  });

  bool get isBasePlan => offerId == null;
  PhaseView get recurring => phases.last;
  PhaseView get first => phases.first;
}

class PlanChoice {
  final String basePlanId;

  /// The offer to buy: its token is what Play needs.
  final OfferView purchase;

  /// The plain base plan, which defines the renewal price.
  final OfferView base;
  final OfferKind kind;

  const PlanChoice({
    required this.basePlanId,
    required this.purchase,
    required this.base,
    required this.kind,
  });

  /// The phase the user pays after any trial or discount.
  PhaseView get recurring => base.recurring;

  /// The phase shown first: free for a trial, discounted for a discount offer.
  PhaseView? get intro => kind == OfferKind.none ? null : purchase.first;

  int? get percentOff {
    final i = intro;
    if (i == null || recurring.price <= 0) return null;
    return ((1 - i.price / recurring.price) * 100).round();
  }

  /// "3-day free trial", or null when there is no trial.
  String? get trialText => kind == OfferKind.freeTrial
      ? '${PlanOffers.describePeriod(intro!.billingPeriod, intro!.cycleCount, adjective: true)} free trial'
      : null;

  /// "first year", "first 3 months", or null when there is no discount.
  String? get introPeriodText => kind == OfferKind.discount
      ? 'first ${PlanOffers.describePeriod(intro!.billingPeriod, intro!.cycleCount)}'
      : null;
}

class PlanOffers {
  PlanOffers._();

  /// One [PlanChoice] per base plan, in order of first appearance.
  static List<PlanChoice> select(List<OfferView> offers) {
    final order = <String>[];
    final byPlan = <String, List<OfferView>>{};
    for (final o in offers) {
      if (o.phases.isEmpty) continue;
      byPlan.putIfAbsent(o.basePlanId, () {
        order.add(o.basePlanId);
        return [];
      }).add(o);
    }
    return [for (final id in order) _choose(id, byPlan[id]!)];
  }

  static PlanChoice _choose(String basePlanId, List<OfferView> group) {
    // The plain base plan defines the renewal price. If it is somehow absent,
    // fall back to the offer with the fewest phases.
    final base = group.firstWhere(
      (o) => o.isBasePlan,
      orElse: () => ([...group]..sort((a, b) =>
              a.phases.length.compareTo(b.phases.length)))
          .first,
    );

    OfferView? bestTrial;
    OfferView? bestDiscount;
    for (final o in group) {
      if (o.isBasePlan || identical(o, base)) continue;
      // Only offers that renew at the normal price qualify; anything that
      // changes the long-term price is left for the user to see in Play.
      if ((o.recurring.price - base.recurring.price).abs() > 0.005) continue;
      if (o.first.price >= base.recurring.price) continue;

      if (o.first.isFree) {
        if (bestTrial == null ||
            _approxDays(o.first.billingPeriod) * o.first.cycleCount >
                _approxDays(bestTrial.first.billingPeriod) *
                    bestTrial.first.cycleCount) {
          bestTrial = o;
        }
      } else if (bestDiscount == null ||
          o.first.price < bestDiscount.first.price) {
        bestDiscount = o;
      }
    }

    if (bestTrial != null) {
      return PlanChoice(
        basePlanId: basePlanId,
        purchase: bestTrial,
        base: base,
        kind: OfferKind.freeTrial,
      );
    }
    if (bestDiscount != null) {
      return PlanChoice(
        basePlanId: basePlanId,
        purchase: bestDiscount,
        base: base,
        kind: OfferKind.discount,
      );
    }
    return PlanChoice(
      basePlanId: basePlanId,
      purchase: base,
      base: base,
      kind: OfferKind.none,
    );
  }

  static final RegExp _iso =
      RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$');

  static int _n(RegExpMatch m, int g) => int.tryParse(m.group(g) ?? '') ?? 0;

  /// Approximate length of one ISO-8601 period in days (months = 30, years =
  /// 365). Used only for ranking offers and estimating expiry, never billing.
  static int _approxDays(String iso) {
    final m = _iso.firstMatch(iso);
    if (m == null) return 0;
    return _n(m, 1) * 365 + _n(m, 2) * 30 + _n(m, 3) * 7 + _n(m, 4);
  }

  static int approxDays(String iso) => _approxDays(iso);

  /// Human text for [cycles] cycles of [iso]. With [adjective] true it reads
  /// "3-day"; otherwise "3 days" or, for one year, "year".
  static String describePeriod(String iso, int cycles,
      {bool adjective = false}) {
    final m = _iso.firstMatch(iso);
    final n = cycles < 1 ? 1 : cycles;
    if (m == null) return adjective ? '$n-day' : '$n days';

    final years = _n(m, 1);
    final months = _n(m, 2);
    final weeks = _n(m, 3);
    final days = _n(m, 4);

    // Normalise weeks into days so "P1W" reads as 7 days.
    int amount;
    String unit;
    if (years > 0) {
      amount = years * n;
      unit = 'year';
    } else if (months > 0) {
      amount = months * n;
      unit = 'month';
    } else {
      amount = (weeks * 7 + days) * n;
      unit = 'day';
    }

    if (adjective) return '$amount-$unit';
    if (amount == 1) return unit;
    return '$amount ${unit}s';
  }
}
