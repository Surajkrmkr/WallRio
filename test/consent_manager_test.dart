import 'package:flutter_test/flutter_test.dart';
import 'package:wallrio/services/consent_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentManager Tests', () {
    test('Singleton instance is consistent', () {
      final instance1 = ConsentManager.instance;
      final instance2 = ConsentManager.instance;
      expect(instance1, same(instance2));
    });

    test('Initial canRequestAds state is gated to false by default before consent update', () {
      final manager = ConsentManager.instance;
      expect(manager.canRequestAds, isFalse);
    });

    test('isMobileAdsInitialized is false initially', () {
      final manager = ConsentManager.instance;
      expect(manager.isMobileAdsInitialized, isFalse);
    });

    test('Privacy options requirement defaults to false', () {
      final manager = ConsentManager.instance;
      expect(manager.isPrivacyOptionsRequired, isFalse);
    });
  });
}
