import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:wallrio/log.dart';

class RevenueCatService {
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static bool _isConfigured = false;
  static bool _androidShadowRunning = false;

  static bool get isConfigured => _isConfigured;

  /// Whether RevenueCat is watching Android purchases in shadow mode.
  static bool get androidShadowRunning => _androidShadowRunning;

  /// A RevenueCat Android public SDK key starts with `goog_`.
  static bool isValidAndroidKey(String key) => key.startsWith('goog_');

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

  /// Android shadow mode. RevenueCat only *observes* purchases made through
  /// the existing Play Billing code: the app still buys, acknowledges and
  /// restores exactly as before, and nothing here changes who is Pro. It logs
  /// what RevenueCat sees so it can be compared with the current entitlement
  /// before RevenueCat is ever allowed to grant access.
  ///
  /// Inert unless the build supplies `--dart-define=REVENUECAT_ANDROID_API_KEY=goog_...`.
  static Future<void> initializeAndroidShadow() async {
    if (!Platform.isAndroid || _androidShadowRunning) return;
    if (_androidApiKey.isEmpty) return; // not configured: do nothing
    if (!isValidAndroidKey(_androidApiKey)) {
      logger.e(
        'RevenueCat Android shadow mode skipped: the key must be a public '
        'SDK key starting with goog_.',
      );
      return;
    }

    await Purchases.configure(
      PurchasesConfiguration(_androidApiKey)
        // The app keeps completing and acknowledging purchases itself.
        ..purchasesAreCompletedBy = PurchasesAreCompletedByMyApp(
          storeKitVersion: StoreKitVersion.defaultVersion,
        ),
    );
    _androidShadowRunning = true;
    Purchases.addCustomerInfoUpdateListener((info) {
      logger.i(
        '[RC shadow] active entitlements: '
        '${info.entitlements.active.keys.toList()}, '
        'active subscriptions: ${info.activeSubscriptions}, '
        'purchased products: ${info.allPurchasedProductIdentifiers}',
      );
    });
    logger.i('[RC shadow] observing Android purchases (no entitlement changes).');
  }

  /// Tells RevenueCat about purchases the app completed itself. With
  /// `PurchasesAreCompletedByMyApp` RevenueCat does not see Play purchases
  /// until the app syncs. Observe-only: failures are swallowed and nothing
  /// here touches the purchase, acknowledgement or entitlement flow.
  static Future<void> syncAndroidPurchases() async {
    if (!_androidShadowRunning) return;
    try {
      await Purchases.syncPurchases();
    } catch (error) {
      logger.w('[RC shadow] syncPurchases failed: $error');
    }
  }

  /// Logs whether RevenueCat agrees with the app's own Pro decision. Logging
  /// only: it never grants or removes access.
  static Future<void> logShadowComparison({required bool legacyIsPro}) async {
    if (!_androidShadowRunning) return;
    try {
      await syncAndroidPurchases();
      final info = await Purchases.getCustomerInfo();
      final rcActive = info.entitlements.active.isNotEmpty ||
          info.activeSubscriptions.isNotEmpty;
      logger.i(
        '[RC shadow] app says Pro=$legacyIsPro, RevenueCat says active=$rcActive'
        '${legacyIsPro == rcActive ? '' : '  <-- MISMATCH'}',
      );
    } catch (error) {
      logger.w('[RC shadow] could not read customer info: $error');
    }
  }
}
