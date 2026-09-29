import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as revenuecat;
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/services/premium/premium_service.dart';
import 'package:wallrio/services/revenuecat_service.dart';
import 'package:wallrio/ui/widgets/export.dart';

class IOSPremiumService implements PremiumService {
  static const String keyPlusMember = 'user_is_plus_member';
  static const String keyExpiryDate = 'user_subscription_expiry';
  static const String keyUnlockedCollections = 'user_unlocked_collections';
  static const String keyLifetimeMember = 'user_is_lifetime_member';
  static const String premiumEntitlementId = 'pro';

  @override
  bool isLoading = false;

  bool get isSupported => RevenueCatService.isConfigured;
  String _subscriptionDaysLeft = '';

  @override
  List<ProductDetails> products = [];

  @override
  Set<String> purchasedCollections = {};

  final Map<String, revenuecat.StoreProduct> _storeProducts = {};
  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();

  @override
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  @override
  String get subscriptionDaysLeft => _subscriptionDaysLeft;

  @override
  Future<void> checkSupportForIAP(Set<String> productIDs) async {
    await _loadCachedCollections();
    if (!isSupported) {
      logger.e(
        '[IOSPremiumService] RevenueCat is not configured; pass an App Store '
        'API key using REVENUECAT_IOS_API_KEY.',
      );
      await _loadCachedEntitlement();
      return;
    }

    await getUserProducts(productIDs);
    await checkPastPurchases();
  }

  @override
  Future<void> getUserProducts(Set<String> productIDs) async {
    if (!isSupported) {
      logger.e(
        '[IOSPremiumService] Cannot load products: RevenueCat is not configured.',
      );
      return;
    }

    isLoading = true;
    _storeProducts.clear();
    products = [];
    try {
      final subscriptionIds = productIDs
          .where(
            (id) =>
                !id.startsWith('com.wallrio.collection.') &&
                id != 'com.wallrio.ios.lifetime_pro',
          )
          .toList();
      final nonSubscriptionIds = productIDs
          .where(
            (id) =>
                id.startsWith('com.wallrio.collection.') ||
                id == 'com.wallrio.ios.lifetime_pro',
          )
          .toList();
      final loadedProducts = <String, revenuecat.StoreProduct>{};

      if (subscriptionIds.isNotEmpty) {
        final subscriptions = await revenuecat.Purchases.getProducts(
          subscriptionIds,
          productCategory: revenuecat.ProductCategory.subscription,
        );
        for (final product in subscriptions) {
          loadedProducts[product.identifier] = product;
        }
      }
      if (nonSubscriptionIds.isNotEmpty) {
        final oneTimeProducts = await revenuecat.Purchases.getProducts(
          nonSubscriptionIds,
          productCategory: revenuecat.ProductCategory.nonSubscription,
        );
        for (final product in oneTimeProducts) {
          loadedProducts[product.identifier] = product;
        }
      }

      _storeProducts
        ..clear()
        ..addAll(loadedProducts);
      products = loadedProducts.values
          .map(
            (product) => ProductDetails(
              id: product.identifier,
              title: product.title,
              description: product.description,
              price: product.priceString,
              rawPrice: product.price,
              currencyCode: product.currencyCode,
            ),
          )
          .toList();

      final missingIds = productIDs.difference(loadedProducts.keys.toSet());
      if (missingIds.isNotEmpty) {
        logger.w(
          '[IOSPremiumService] RevenueCat did not return configured products: $missingIds',
        );
      }
      logger.i(
        '[IOSPremiumService] Loaded ${products.length} products from RevenueCat.',
      );
    } catch (error, stackTrace) {
      logger.e(
        '[IOSPremiumService] Failed to load RevenueCat products.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> buyProduct(ProductDetails product) async {
    final storeProduct = _storeProducts[product.id];
    if (storeProduct == null) {
      logger.e(
        '[IOSPremiumService] RevenueCat product ${product.id} is not available.',
      );
      ToastWidget.showToast('This product is currently unavailable.');
      return;
    }

    isLoading = true;
    try {
      final result = await revenuecat.Purchases.purchase(
        revenuecat.PurchaseParams.storeProduct(storeProduct),
      );
      if (product.id.startsWith('com.wallrio.collection.')) {
        await _unlockCollection(product.id);
      } else {
        await _applyCustomerInfo(result.customerInfo);
        if (result.customerInfo.entitlements.active.containsKey(
          premiumEntitlementId,
        )) {
          ToastWidget.showToast('Purchased successfully!');
          _successPurchased.add(true);
        } else {
          logger.e(
            '[IOSPremiumService] Purchase completed without active "$premiumEntitlementId" entitlement. '
            'Check RevenueCat product-to-entitlement configuration.',
          );
          ToastWidget.showToast(
            'Purchase completed, but premium access is not active.',
          );
        }
      }
    } on PlatformException catch (error, stackTrace) {
      final errorCode = revenuecat.PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == revenuecat.PurchasesErrorCode.purchaseCancelledError) {
        logger.i('[IOSPremiumService] Purchase cancelled by user.');
        return;
      }
      logger.e(
        '[IOSPremiumService] RevenueCat purchase failed for ${product.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      ToastWidget.showToast('Unable to complete purchase');
    } catch (error, stackTrace) {
      logger.e(
        '[IOSPremiumService] RevenueCat purchase failed for ${product.id}.',
        error: error,
        stackTrace: stackTrace,
      );
      ToastWidget.showToast('Unable to complete purchase');
    } finally {
      isLoading = false;
    }
  }

  Future<void> _unlockCollection(String productId) async {
    final collectionId = productId.split('.').last;
    final prefs = await SharedPreferences.getInstance();
    purchasedCollections
      ..add(collectionId)
      ..add(productId);

    final unlockedCollections =
        prefs.getStringList(keyUnlockedCollections) ?? [];
    final updatedCollections = Set<String>.from(unlockedCollections)
      ..add(collectionId)
      ..add(productId);
    await prefs.setStringList(
      keyUnlockedCollections,
      updatedCollections.toList(),
    );

    ToastWidget.showToast('Collection unlocked!');
    _successPurchased.add(true);
  }

  @override
  Future<void> restorePurchases() async {
    if (!isSupported) {
      ToastWidget.showToast('Purchases are not available right now.');
      return;
    }

    isLoading = true;
    try {
      ToastWidget.showToast('Restoring purchases from App Store...');
      final customerInfo = await revenuecat.Purchases.restorePurchases();
      await _applyCustomerInfo(customerInfo);
      if (customerInfo.entitlements.active.containsKey(premiumEntitlementId)) {
        ToastWidget.showToast('Purchases restored successfully!');
        _successPurchased.add(true);
      } else {
        ToastWidget.showToast('No active purchases found.');
      }
    } catch (error, stackTrace) {
      logger.e(
        '[IOSPremiumService] RevenueCat restore failed.',
        error: error,
        stackTrace: stackTrace,
      );
      ToastWidget.showToast('Failed to restore purchases');
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> checkPastPurchases({String? email}) async {
    await _loadCachedCollections();
    if (!isSupported) {
      await _loadCachedEntitlement();
      return;
    }

    isLoading = true;
    try {
      final customerInfo = await revenuecat.Purchases.getCustomerInfo();
      await _applyCustomerInfo(customerInfo);
    } catch (error, stackTrace) {
      logger.e(
        '[IOSPremiumService] Failed to refresh RevenueCat customer entitlements; '
        'using the cached entitlement when still valid.',
        error: error,
        stackTrace: stackTrace,
      );
      await _loadCachedEntitlement();
    } finally {
      isLoading = false;
    }
  }

  Future<void> _applyCustomerInfo(revenuecat.CustomerInfo customerInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final entitlement = customerInfo.entitlements.active[premiumEntitlementId];
    if (entitlement == null) {
      _subscriptionDaysLeft = '';
      UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
      await prefs.setBool(keyPlusMember, false);
      await prefs.setBool(keyLifetimeMember, false);
      await prefs.setBool('user_has_collection_access', false);
      await prefs.remove(keyExpiryDate);
      await prefs.remove('user_subscription_start');
      return;
    }

    final expirationDate = entitlement.expirationDate == null
        ? null
        : DateTime.tryParse(entitlement.expirationDate!);
    if (entitlement.expirationDate != null && expirationDate == null) {
      throw FormatException(
        'Invalid RevenueCat entitlement expiration date: '
        '${entitlement.expirationDate}',
      );
    }
    final isLifetime = expirationDate == null;
    final hasCollectionAccess =
        entitlement.productIdentifier.contains('yearly') ||
        entitlement.productIdentifier.contains('lifetime');
    _subscriptionDaysLeft = isLifetime
        ? 'Lifetime'
        : (expirationDate.difference(DateTime.now()).inDays + 1).toString();

    UserProfile.setPlusMemberInfo(
      true,
      hasCollectionAccess: hasCollectionAccess,
    );
    await prefs.setBool(keyPlusMember, true);
    await prefs.setBool(keyLifetimeMember, isLifetime);
    await prefs.setBool('user_has_collection_access', hasCollectionAccess);
    await prefs.setString(
      keyExpiryDate,
      (expirationDate ?? DateTime.now().add(const Duration(days: 36135)))
          .toIso8601String(),
    );
    await prefs.setString(
      'user_subscription_start',
      entitlement.latestPurchaseDate,
    );
  }

  Future<void> _loadCachedCollections() async {
    final prefs = await SharedPreferences.getInstance();
    purchasedCollections
      ..clear()
      ..addAll(prefs.getStringList(keyUnlockedCollections) ?? []);
  }

  Future<void> _loadCachedEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    final isPlus = prefs.getBool(keyPlusMember) ?? false;
    final isLifetime = prefs.getBool(keyLifetimeMember) ?? false;
    final expiryString = prefs.getString(keyExpiryDate);
    final expiryDate = expiryString == null
        ? null
        : DateTime.tryParse(expiryString);
    final isActive =
        isPlus &&
        (isLifetime || (expiryDate?.isAfter(DateTime.now()) ?? false));

    if (isActive) {
      _subscriptionDaysLeft = isLifetime
          ? 'Lifetime'
          : (expiryDate!.difference(DateTime.now()).inDays + 1).toString();
      UserProfile.setPlusMemberInfo(
        true,
        hasCollectionAccess:
            prefs.getBool('user_has_collection_access') ?? false,
      );
      return;
    }

    _subscriptionDaysLeft = '';
    UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
    await prefs.setBool(keyPlusMember, false);
    await prefs.setBool(keyLifetimeMember, false);
    await prefs.setBool('user_has_collection_access', false);
  }

  @override
  Future<void> clearPurchaseSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyPlusMember);
    await prefs.remove(keyLifetimeMember);
    await prefs.remove(keyExpiryDate);
    await prefs.remove('user_subscription_start');
    await prefs.remove('user_has_collection_access');
    await prefs.remove(keyUnlockedCollections);

    purchasedCollections.clear();
    _subscriptionDaysLeft = '';
    UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
    ToastWidget.showToast('Debug: Cleared purchase SharedPreferences');
  }

  @override
  void dispose() {
    _successPurchased.close();
  }
}
