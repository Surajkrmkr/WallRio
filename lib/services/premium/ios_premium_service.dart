import 'dart:async';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/services/premium/premium_service.dart';
import 'package:wallrio/ui/widgets/export.dart';

class IOSPremiumService implements PremiumService {
  static const String keyPlusMember = 'user_is_plus_member';
  static const String keyExpiryDate = 'user_subscription_expiry';
  static const String keyUnlockedCollections = 'user_unlocked_collections';

  @override
  bool isLoading = false;
  bool isSupported = false;
  String _subscriptionDaysLeft = "";

  @override
  List<ProductDetails> products = [];
  @override
  Set<String> purchasedCollections = {};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  bool _isExplicitUserAction = false;

  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();
  @override
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  @override
  String get subscriptionDaysLeft => _subscriptionDaysLeft;

  @override
  Future<void> checkSupportForIAP(Set<String> productIDs) async {
    logger.i('[IOSPremiumService] Initializing StoreKit IAP support...');
    isSupported = await inAppPurchase.isAvailable();
    logger.i('[IOSPremiumService] StoreKit available: $isSupported. Queried Product IDs: $productIDs');

    if (isSupported) {
      // 1. Load local cached entitlements from SharedPreferences immediately
      await checkPastPurchases();

      // 2. Fetch product details from App Store
      await getUserProducts(productIDs);

      // 3. Listen to StoreKit purchase updates safely
      await _subscription?.cancel();
      _subscription = inAppPurchase.purchaseStream.listen((data) {
        if (data.isEmpty) return;
        for (final purchase in data) {
          logger.i('[IOSPremiumService] Purchase Stream Event -> Status: ${purchase.status}, ProductID: ${purchase.productID}, TransactionID: ${purchase.purchaseID}, PendingComplete: ${purchase.pendingCompletePurchase}');

          if (purchase.pendingCompletePurchase) {
            inAppPurchase.completePurchase(purchase).catchError((err) {
              logger.e('[IOSPremiumService] Error completing purchase transaction: $err');
            });
          }

          switch (purchase.status) {
            case PurchaseStatus.canceled:
              logger.i('[IOSPremiumService] Purchase canceled by user for ProductID: ${purchase.productID}');
              if (_isExplicitUserAction) {
                ToastWidget.showToast('Purchase Cancelled');
              }
              isLoading = false;
              _isExplicitUserAction = false;
              break;
            case PurchaseStatus.error:
              logger.e('[IOSPremiumService] StoreKit purchase error: ${purchase.error}');
              if (_isExplicitUserAction) {
                ToastWidget.showToast('Purchase Error');
              }
              isLoading = false;
              _isExplicitUserAction = false;
              break;
            case PurchaseStatus.pending:
              logger.i('[IOSPremiumService] Purchase pending for ProductID: ${purchase.productID}');
              if (_isExplicitUserAction) {
                ToastWidget.showToast(
                    'Your purchase is currently pending. Please check back in a moment.');
              }
              break;
            case PurchaseStatus.purchased:
              _handleSuccessfulPurchase(purchase, isRestore: false);
              break;
            case PurchaseStatus.restored:
              _handleSuccessfulPurchase(purchase, isRestore: true);
              break;
            default:
              break;
          }
        }
      });
    }
  }

  @override
  Future<void> getUserProducts(Set<String> productIDs) async {
    isLoading = true;
    try {
      logger.i('[IOSPremiumService] Querying product details from StoreKit for IDs: $productIDs');
      final ProductDetailsResponse response =
          await inAppPurchase.queryProductDetails(productIDs);

      if (response.notFoundIDs.isNotEmpty) {
        logger.w('[IOSPremiumService] StoreKit returned no product for IDs: ${response.notFoundIDs}');
      }
      if (response.error != null) {
        logger.w('[IOSPremiumService] StoreKit queryProductDetails error: ${response.error}');
      }

      products = response.productDetails;
      logger.i('[IOSPremiumService] Products fetched successfully (${products.length} items): '
          '${products.map((p) => '${p.id}:${p.price}').toList()}');
    } catch (error) {
      logger.e('[IOSPremiumService] Exception in getUserProducts: $error');
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> buyProduct(ProductDetails prod) async {
    isLoading = true;
    _isExplicitUserAction = true;
    try {
      logger.i('[IOSPremiumService] Initiating purchase for ProductID: ${prod.id}, Price: ${prod.price}');
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
      if (prod.id.startsWith('com.wallrio.collection.')) {
        await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } on PlatformException catch (e) {
      logger.e('[IOSPremiumService] PlatformException initiating purchase for ${prod.id}: ${e.code} - ${e.message}');
      isLoading = false;
      _isExplicitUserAction = false;
      if (e.code == 'storekit_duplicate_product_object' || (e.message != null && e.message!.contains('storekit_duplicate_product_object'))) {
        ToastWidget.showToast('You already own this item or have a pending purchase. Try restoring purchases from Settings.');
      } else {
        ToastWidget.showToast('Unable to complete purchase at this time');
      }
      rethrow;
    } on Exception catch (e) {
      logger.e('[IOSPremiumService] Exception initiating purchase for ${prod.id}: $e');
      isLoading = false;
      _isExplicitUserAction = false;
      ToastWidget.showToast('Unable to complete purchase');
      rethrow;
    } catch (e) {
      logger.e('[IOSPremiumService] Unknown error initiating purchase for ${prod.id}: $e');
      isLoading = false;
      _isExplicitUserAction = false;
      rethrow;
    }
  }

  @override
  Future<void> restorePurchases({bool isAppLaunch = false}) async {
    isLoading = true;
    _isExplicitUserAction = true;
    try {
      ToastWidget.showToast('Restoring purchases from App Store...');
      logger.i('[IOSPremiumService] Triggering user-initiated StoreKit restorePurchases...');
      await inAppPurchase.restorePurchases();
      logger.i('[IOSPremiumService] StoreKit restorePurchases request dispatched successfully.');
    } on Exception catch (e) {
      logger.e('[IOSPremiumService] Exception restoring purchases: $e');
      ToastWidget.showToast('Failed to restore purchases');
      _isExplicitUserAction = false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase,
      {required bool isRestore}) async {
    isLoading = true;
    try {
      logger.i('[IOSPremiumService] Processing successful purchase/restore (isRestore: $isRestore) for ProductID: ${purchase.productID}');

      if (purchase.pendingCompletePurchase) {
        await inAppPurchase.completePurchase(purchase);
        logger.i('[IOSPremiumService] Completed StoreKit purchase transaction: ${purchase.purchaseID}');
      }

      final prefs = await SharedPreferences.getInstance();

      // --- COLLECTION PURCHASES ---
      if (purchase.productID.startsWith('com.wallrio.collection.')) {
        final collectionId = purchase.productID.split('.').last;
        
        purchasedCollections.add(collectionId);
        purchasedCollections.add(purchase.productID);

        final savedList = prefs.getStringList(keyUnlockedCollections) ?? [];
        final updatedSet = Set<String>.from(savedList)
          ..add(collectionId)
          ..add(purchase.productID);

        await prefs.setStringList(keyUnlockedCollections, updatedSet.toList());

        logger.i('[IOSPremiumService] Collection unlocked & saved to SharedPreferences! '
            'CollectionID: "$collectionId", ProductID: "${purchase.productID}". '
            'Total unlocked collections in SharedPreferences: ${updatedSet.toList()}');

        _successPurchased.sink.add(true);
        if (_isExplicitUserAction) {
          ToastWidget.showToast(isRestore
              ? 'Collection restored!'
              : 'Collection unlocked!');
          _isExplicitUserAction = false;
        }
        return;
      }

      // --- SUBSCRIPTION / LIFETIME PURCHASES ---
      int subscriptionDays = 365;
      if (purchase.productID.contains('lifetime')) {
        subscriptionDays = 36135; // ~99 years
      } else if (purchase.productID.contains('yearly')) {
        subscriptionDays = 365;
      } else if (purchase.productID.contains('quaterly')) {
        subscriptionDays = 90;
      } else if (purchase.productID.contains('monthly')) {
        subscriptionDays = 30;
      } else {
        final suffix = purchase.productID.split("_").last;
        final parsed = int.tryParse(suffix);
        if (parsed != null && parsed > 0) {
          subscriptionDays = parsed;
        }
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: subscriptionDays));
      _subscriptionDaysLeft = endDate.difference(now).inDays.toString();
      final bool hasCollectionAccess = subscriptionDays >= 360;

      UserProfile.setPlusMemberInfo(true,
          hasCollectionAccess: hasCollectionAccess);

      await prefs.setBool(keyPlusMember, true);
      await prefs.setBool('user_has_collection_access', hasCollectionAccess);
      await prefs.setString(keyExpiryDate, endDate.toIso8601String());
      await prefs.setString('user_subscription_start', now.toIso8601String());

      logger.i('[IOSPremiumService] Premium subscription active & saved to SharedPreferences! '
          'ProductID: "${purchase.productID}", ExpiryDate: "${endDate.toIso8601String()}", '
          'DaysRemaining: $_subscriptionDaysLeft, HasCollectionAccess: $hasCollectionAccess');

      _successPurchased.sink.add(true);
      if (_isExplicitUserAction) {
        ToastWidget.showToast(isRestore
            ? 'Purchases restored successfully!'
            : 'Purchased successfully!');
        _isExplicitUserAction = false;
      }
    } catch (error) {
      logger.e('[IOSPremiumService] Error handling purchase for ${purchase.productID}: $error');
      if (_isExplicitUserAction) {
        ToastWidget.showToast('Something went wrong');
        _isExplicitUserAction = false;
      }
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> checkPastPurchases({String? email}) async {
    isLoading = true;
    try {
      logger.i('[IOSPremiumService] Checking local SharedPreferences cached entitlement state...');
      final prefs = await SharedPreferences.getInstance();

      // 1. Load unlocked collection IDs from SharedPreferences
      final savedCollections = prefs.getStringList(keyUnlockedCollections) ?? [];
      if (savedCollections.isNotEmpty) {
        purchasedCollections.addAll(savedCollections);
        logger.i('[IOSPremiumService] Loaded ${savedCollections.length} unlocked collections from SharedPreferences: $savedCollections');
      }

      // 2. Load Pro Subscription status from SharedPreferences
      final expiryStr = prefs.getString(keyExpiryDate);
      final isPlus = prefs.getBool(keyPlusMember) ?? false;
      final hasCollectionAccess =
          prefs.getBool('user_has_collection_access') ?? false;

      if (isPlus && expiryStr != null) {
        final expiryDate = DateTime.tryParse(expiryStr);
        final now = DateTime.now();
        if (expiryDate != null && expiryDate.isAfter(now)) {
          _subscriptionDaysLeft =
              (expiryDate.difference(now).inDays + 1).toString();
          UserProfile.setPlusMemberInfo(true,
              hasCollectionAccess: hasCollectionAccess);
          logger.i('[IOSPremiumService] Active Pro subscription loaded from SharedPreferences. '
              'DaysRemaining: $_subscriptionDaysLeft, Expiry: $expiryStr, HasCollectionAccess: $hasCollectionAccess');
          return;
        }
      }

      // If subscription expired:
      logger.i('[IOSPremiumService] No active Pro subscription found in SharedPreferences (isPlus: $isPlus, expiryStr: $expiryStr).');
      UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
      _subscriptionDaysLeft = "";
      await prefs.setBool(keyPlusMember, false);
      await prefs.setBool('user_has_collection_access', false);
    } catch (error) {
      logger.e('[IOSPremiumService] Error checking past iOS purchases in SharedPreferences: $error');
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> clearPurchaseSharedPreferences() async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyPlusMember);
      await prefs.remove(keyExpiryDate);
      await prefs.remove('user_subscription_start');
      await prefs.remove('user_has_collection_access');
      await prefs.remove(keyUnlockedCollections);

      purchasedCollections.clear();
      _subscriptionDaysLeft = "";
      UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);

      logger.i('[IOSPremiumService] Debug Action: Cleared all purchase & collection values from SharedPreferences.');
      ToastWidget.showToast('Debug: Cleared purchase SharedPreferences');
    } catch (e) {
      logger.e('[IOSPremiumService] Error clearing purchase SharedPreferences: $e');
    } finally {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    logger.i('[IOSPremiumService] Disposing StoreKit service.');
    _subscription?.cancel();
    _successPurchased.close();
  }
}
