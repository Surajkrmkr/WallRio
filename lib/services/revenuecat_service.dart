import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:wallrio/log.dart';

class RevenueCatService {
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  static Future<void> initialize() async {
    if (!Platform.isIOS || _isConfigured) return;

    if (_iosApiKey.isEmpty) {
      logger.e(
        'RevenueCat is not configured. Provide an App Store public SDK key '
        'with --dart-define=REVENUECAT_IOS_API_KEY=appl_...',
      );
      return;
    }
    if (!_iosApiKey.startsWith('appl_')) {
      logger.e(
        'The RevenueCat iOS key must be an App Store public SDK key (appl_...). '
        'RevenueCat Test Store keys (test_...) cannot load App Store products.',
      );
      return;
    }

    await Purchases.configure(PurchasesConfiguration(_iosApiKey));
    _isConfigured = true;
    logger.i('RevenueCat configured for iOS.');
  }
}
