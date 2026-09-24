import 'dart:async';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/services/premium/premium_service.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AndroidPremiumService implements PremiumService {
  final String subscriptionFirebasePath = "purchases";
  static const String keyPlusMember = 'user_is_plus_member';
  static const String keyExpiryDate = 'user_subscription_expiry';
  static const String keyEntitlementSource = 'user_entitlement_source';

  @override
  bool isLoading = false;
  bool isSupported = false;
  String _subscriptionDaysLeft = "";
  bool _storeEntitlementSeen = false;

  @override
  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];
  @override
  Set<String> purchasedCollections = {};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final InAppPurchase inAppPurchase = InAppPurchase.instance;

  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();
  @override
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  @override
  String get subscriptionDaysLeft => _subscriptionDaysLeft;

  @override
  Future<void> checkSupportForIAP(Set<String> productIDs) async {
    isSupported = await inAppPurchase.isAvailable();
    logger.i('Android IAP available: $isSupported, queried IDs: $productIDs');
    if (isSupported) {
      _subscription = inAppPurchase.purchaseStream.listen((data) {
        if (data.isEmpty) return;
        for (final purchase in data) {
          switch (purchase.status) {
            case PurchaseStatus.canceled:
              ToastWidget.showToast('Purchase Cancelled');
              isLoading = false;
              break;
            case PurchaseStatus.error:
              final error = purchase.error;
              if (error != null && error.message.contains('itemAlreadyOwned')) {
                ToastWidget.showToast(
                    'Fixing a stuck purchase, please try again in a moment');
                _consumeStalePurchases();
              } else {
                ToastWidget.showToast('Something went wrong');
              }
              isLoading = false;
              break;
            case PurchaseStatus.pending:
              ToastWidget.showToast(
                  'Your purchase is currently pending. Please check back in sometime');
              break;
            case PurchaseStatus.purchased:
              ToastWidget.showToast('Purchased successfully');
              _verifyPurchase(purchase);
              break;
            case PurchaseStatus.restored:
              if (_isStoreEntitlement(purchase.productID)) {
                _storeEntitlementSeen = true;
              }
              _consumeRestoredPurchase(purchase);
              break;
            default:
              break;
          }
        }
      });
      await getUserProducts(productIDs);
    }
  }

  @override
  Future<void> getUserProducts(Set<String> productIDs) async {
    isLoading = true;
    try {
      final ProductDetailsResponse response =
          await inAppPurchase.queryProductDetails(productIDs);
      if (response.notFoundIDs.isNotEmpty) {
        logger.e('Store returned no product for IDs: ${response.notFoundIDs}');
      }
      if (response.error != null) {
        logger.e('queryProductDetails error: ${response.error}');
      }
      products = response.productDetails;
    } catch (error) {
      logger.e(error);
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> buyProduct(ProductDetails prod) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
      if (_isCollectionProduct(prod.id)) {
        await inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam, autoConsume: true);
      } else {
        // Play subscriptions and the lifetime product must not be consumed.
        // Google Play then owns renewal and makes the entitlement available
        // again through restorePurchases().
        await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await inAppPurchase.restorePurchases();
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> _consumeStalePurchases() async {
    try {
      await inAppPurchase.restorePurchases();
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> _consumeRestoredPurchase(PurchaseDetails purchase) async {
    try {
      if (!_isCollectionProduct(purchase.productID)) {
        if (purchase.pendingCompletePurchase) {
          await inAppPurchase.completePurchase(purchase);
        }
        await _grantStoreEntitlement(purchase);
        return;
      }
      final addition = inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await addition.consumePurchase(purchase);
      if (purchase.pendingCompletePurchase) {
        await inAppPurchase.completePurchase(purchase);
      }
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    isLoading = true;
    try {
      await inAppPurchase.completePurchase(purchase);
      if (_isCollectionProduct(purchase.productID)) {
        final collectionId = purchase.productID.split('.').last;
        purchasedCollections.add(collectionId);
        _successPurchased.sink.add(true);
        return;
      }

      await _grantStoreEntitlement(purchase);
      _successPurchased.sink.add(true);
    } catch (error) {
      logger.e(error);
    } finally {
      isLoading = false;
    }
  }

  @override
  Future<void> checkPastPurchases({String? email}) async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPlayEntitlement =
          prefs.getString(keyEntitlementSource) == 'play';
      if (hasPlayEntitlement) {
        // Clear only entitlements previously established by Play. Legacy
        // Firebase entitlements are deliberately left untouched.
        UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
        await prefs.setBool(keyPlusMember, false);
        await prefs.setBool('user_has_collection_access', false);
      }
      // This is the source of truth for new Android purchases. The purchase
      // stream will deliver active subscriptions and lifetime purchases.
      _storeEntitlementSeen = false;
      await inAppPurchase.restorePurchases();
      if (_storeEntitlementSeen ||
          prefs.getString(keyEntitlementSource) == 'play') {
        return;
      }

      // Keep the old Firestore read-only migration path for existing users.
      // No new purchase or expiry data is written to Firebase.
      if (hasPlayEntitlement || email == null || email.isEmpty) return;
      final CollectionReference purchases =
          FirebaseFirestore.instance.collection(subscriptionFirebasePath);
      final QuerySnapshot<Object?> querySnapshot = await purchases.get();
      final now = DateTime.now();
      UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
      await prefs.setBool(keyPlusMember, false);
      await prefs.setBool('user_has_collection_access', false);
      await prefs.remove(keyExpiryDate);
      purchasedCollections.clear();

      bool foundActiveSubscription = false;

      for (var element in querySnapshot.docs) {
        if (element["email"] == email) {
          final String prodId = element.data().toString().contains("productID")
              ? element["productID"] ?? ""
              : "";

          if (prodId.startsWith('com.wallrio.collection.')) {
            purchasedCollections.add(prodId.split('.').last);
            continue;
          }

          if (foundActiveSubscription) continue;
          if (!element.data().toString().contains("purchaseStartDate")) {
            continue;
          }

          final purchaseStartDate =
              DateTime.parse(element["purchaseStartDate"].toDate().toString())
                  .toLocal();
          final purchaseEndDate =
              DateTime.parse(element["purchaseEndDate"].toDate().toString())
                  .toLocal();
          final bool isPurchaseActive =
              purchaseStartDate.isBefore(now) && purchaseEndDate.isAfter(now);
          if (isPurchaseActive) {
            foundActiveSubscription = true;
            _subscriptionDaysLeft =
                (purchaseEndDate.difference(now).inDays + 1).toString();
            final int totalDays =
                purchaseEndDate.difference(purchaseStartDate).inDays;
            final bool hasCollectionAccess = totalDays >= 360;
            UserProfile.setPlusMemberInfo(true,
                hasCollectionAccess: hasCollectionAccess);
            await prefs.setBool(keyPlusMember, true);
            await prefs.setBool(
                'user_has_collection_access', hasCollectionAccess);
            await prefs.setString(
                keyExpiryDate, purchaseEndDate.toIso8601String());
            await prefs.setString(
                'user_subscription_start', purchaseStartDate.toIso8601String());
          }
        }
      }
    } catch (error) {
      logger.e(error);
    } finally {
      isLoading = false;
    }
  }

  bool _isCollectionProduct(String productId) =>
      productId.startsWith('com.wallrio.collection.');

  bool _isSubscriptionProduct(String productId) =>
      productId == 'com.wallrio.pro.monthly' ||
      productId == 'com.wallrio.pro.quarterly' ||
      productId == 'com.wallrio.pro.annual' ||
      productId.contains('monthly') ||
      productId.contains('quaterly') ||
      productId.contains('quarterly') ||
      productId.contains('yearly') ||
      productId.contains('annual');

  bool _isStoreEntitlement(String productId) =>
      productId.contains('lifetime') || _isSubscriptionProduct(productId);

  Future<void> _grantStoreEntitlement(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    final isLifetime = purchase.productID.contains('lifetime');
    final isSubscription = _isSubscriptionProduct(purchase.productID);
    if (!isLifetime && !isSubscription) return;

    // Play is authoritative for recurring entitlement state. Do not calculate
    // an expiry date because Play owns renewal and cancellation state.
    final hasCollectionAccess = isLifetime ||
        purchase.productID.contains('yearly') ||
        purchase.productID.contains('annual');
    UserProfile.setPlusMemberInfo(true,
        hasCollectionAccess: hasCollectionAccess);
    await prefs.setBool(keyPlusMember, true);
    await prefs.setBool('user_has_collection_access', hasCollectionAccess);
    await prefs.setString(keyEntitlementSource, 'play');
    await prefs.remove(keyExpiryDate);
    await prefs.remove('user_subscription_start');
    _subscriptionDaysLeft = isLifetime ? 'Lifetime' : 'Active';
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
      await prefs.remove(keyEntitlementSource);
      await prefs.remove('user_unlocked_collections');

      purchasedCollections.clear();
      _subscriptionDaysLeft = "";
      UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);
      ToastWidget.showToast('Debug: Cleared purchase SharedPreferences');
    } catch (e) {
      logger.e('Error clearing purchase SharedPreferences: $e');
    } finally {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _successPurchased.close();
  }
}
