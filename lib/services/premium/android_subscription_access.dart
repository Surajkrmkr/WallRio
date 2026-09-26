class AndroidSubscriptionAccess {
  static bool hasCollectionAccess({
    required String productId,
    String? basePlanId,
  }) {
    if (productId.contains('lifetime')) return true;

    final normalizedBasePlanId = basePlanId?.toLowerCase();
    if (normalizedBasePlanId == 'yearly' || normalizedBasePlanId == 'annual') {
      return true;
    }

    return productId.contains('yearly') || productId.contains('annual');
  }
}
