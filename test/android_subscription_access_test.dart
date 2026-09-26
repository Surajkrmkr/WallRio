import 'package:flutter_test/flutter_test.dart';
import 'package:wallrio/services/premium/android_subscription_access.dart';

void main() {
  group('Android subscription collection access', () {
    test('monthly subscription has PRO but not collection access', () {
      expect(
        AndroidSubscriptionAccess.hasCollectionAccess(
          productId: 'wallrio_pro',
          basePlanId: 'monthly',
        ),
        isFalse,
      );
    });

    test('qaterly base plan has PRO but not collection access', () {
      expect(
        AndroidSubscriptionAccess.hasCollectionAccess(
          productId: 'wallrio_pro',
          basePlanId: 'qaterly',
        ),
        isFalse,
      );
    });

    test('yearly base plan receives collection access', () {
      expect(
        AndroidSubscriptionAccess.hasCollectionAccess(
          productId: 'wallrio_pro',
          basePlanId: 'yearly',
        ),
        isTrue,
      );
    });

    test('lifetime purchase receives collection access', () {
      expect(
        AndroidSubscriptionAccess.hasCollectionAccess(
          productId: 'com.wallrio.lifetime_pro',
        ),
        isTrue,
      );
    });
  });
}
