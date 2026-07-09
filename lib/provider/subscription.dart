import 'dart:async' show Future, Stream, StreamSubscription;

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SubscriptionProvider extends ChangeNotifier {
  final String subscriptionFirebasePath = "purchases";
  static const String keyPlusMember = 'user_is_plus_member';
  static const String keyExpiryDate = 'user_subscription_expiry';

  bool isLoading = false;
  bool isSupported = false;
  bool isSubscriptionLoading = false;
  bool isSubcriptionAnimating = false;

  String _subscriptionDaysLeft = "";

  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];
  Set<String> purchasedCollections = {};

  late StreamSubscription subscription;

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  static const String lifetimeProductId = 'com.wallrio.lifetime_pro';

  final Set<String> productIDs = {
    //   "com.wallrio.test",
    lifetimeProductId,
    "com.wallrio.monthly_28",
    "com.wallrio.quaterly_84",
    "com.wallrio.yearly_365"
  };

  // final successPurchasedStream = StreamController<bool>();
  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  set setProducts(List<ProductDetails> productList) {
    products = productList;
    notifyListeners();
  }

  set setPurchases(List<PurchaseDetails> purchasesList) {
    purchases = purchasesList;
    notifyListeners();
  }

  set setSubscriptionDaysLeft(String days) {
    _subscriptionDaysLeft = days;
    notifyListeners();
  }

  String get subscriptionDaysLeft => _subscriptionDaysLeft;

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setIsSubscriptionIdLoading(bool val) {
    isSubscriptionLoading = val;
    notifyListeners();
  }

  set setIsSubcriptionAnimating(bool val) {
    isSubcriptionAnimating = val;
    notifyListeners();
  }

  Future<void> checkSupportForIAP() async {
    isSupported = await inAppPurchase.isAvailable();
    if (isSupported) {
      await getUserProducts();
      subscription = inAppPurchase.purchaseStream.listen((data) {
        switch (data.first.status) {
          case PurchaseStatus.canceled:
            ToastWidget.showToast('Purchase Cancelled');
            break;
          case PurchaseStatus.error:
            ToastWidget.showToast('Something went wrong');
            break;
          case PurchaseStatus.pending:
            ToastWidget.showToast(
                'Your purchase is currently pending. Please check back in sometime');
            break;
          case PurchaseStatus.purchased:
            ToastWidget.showToast('Purchased successfully');
            _verifyPurchase(data.first);
            break;
          default:
        }
      });
    }
  }

  Future<void> getUserProducts() async {
    setIsLoading = true;
    try {
      final ProductDetailsResponse response =
          await inAppPurchase.queryProductDetails(productIDs);
      setProducts = response.productDetails;
    } catch (error) {
      logger.e(error);
    } finally {
      setIsLoading = false;
    }
  }

  void addCollectionProductIds(List<String> collectionIds) {
    bool added = false;
    for (String id in collectionIds) {
      final prodId = id.startsWith('com.wallrio.collection.') ? id : 'com.wallrio.collection.$id';
      if (!productIDs.contains(prodId)) {
        productIDs.add(prodId);
        added = true;
      }
    }
    if (added) getUserProducts();
  }

  void buyProduct(ProductDetails prod) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
      if (prod.id == lifetimeProductId || prod.id.startsWith('com.wallrio.collection.')) {
        await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam, autoConsume: true);
      }
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    setIsLoading = true;
    try {
      await inAppPurchase.completePurchase(purchase);
      final CollectionReference purchases =
          FirebaseFirestore.instance.collection(subscriptionFirebasePath);
      final now = DateTime.now();

      if (purchase.productID.startsWith('com.wallrio.collection.')) {
        final collectionId = purchase.productID.split('.').last;
        purchasedCollections.add(collectionId);
        await purchases.add({
          "productID": purchase.productID,
          "purchaseID": purchase.purchaseID,
          "pendingCompletePurchase": purchase.pendingCompletePurchase,
          "transactionDate": purchase.transactionDate,
          'email': FirebaseAuth.instance.currentUser!.email,
          'purchaseDate': now.toUtc(),
          'isCollection': true,
        });
        _successPurchased.sink.add(true);
        notifyListeners();
        return;
      }

      final int subscriptionDays = purchase.productID == lifetimeProductId
          ? 36135 // ~99 years
          : int.parse(purchase.productID.split("_").last);
      final endDate = now.add(Duration(days: subscriptionDays));
      await purchases.add({
        "productID": purchase.productID,
        "purchaseID": purchase.purchaseID,
        "pendingCompletePurchase": purchase.pendingCompletePurchase,
        "transactionDate": purchase.transactionDate,
        'email': FirebaseAuth.instance.currentUser!.email,
        'purchaseStartDate': now.toUtc(),
        'purchaseEndDate': endDate.toUtc(),
      });
      setSubscriptionDaysLeft = endDate.difference(now).inDays.toString();
      final bool hasCollectionAccess = subscriptionDays >= 360;
      UserProfile.setPlusMemberInfo(true, hasCollectionAccess: hasCollectionAccess);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyPlusMember, true);
      await prefs.setBool('user_has_collection_access', hasCollectionAccess);
      await prefs.setString(keyExpiryDate, endDate.toIso8601String());
      await prefs.setString('user_subscription_start', now.toIso8601String());
      FirebaseAnalytics.instance.logPurchase(
          currency: 'USD',
          value: null,
          parameters: {
            'product_id': purchase.productID,
            'subscription_days': subscriptionDays,
          });
      _successPurchased.sink.add(true);
    } catch (error) {
      logger.e(error);
    } finally {
      setIsLoading = false;
    }
  }

  Future<void> checkPastPurchases({required String email}) async {
    setIsSubscriptionIdLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
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
              ? element["productID"] ?? "" : "";

          if (prodId.startsWith('com.wallrio.collection.')) {
            purchasedCollections.add(prodId.split('.').last);
            continue;
          }

          if (foundActiveSubscription) continue;
          if (!element.data().toString().contains("purchaseStartDate")) continue;

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
            setSubscriptionDaysLeft =
                (purchaseEndDate.difference(now).inDays + 1).toString();
            final int totalDays = purchaseEndDate.difference(purchaseStartDate).inDays;
            final bool hasCollectionAccess = totalDays >= 360;
            UserProfile.setPlusMemberInfo(true, hasCollectionAccess: hasCollectionAccess);
            await prefs.setBool(keyPlusMember, true);
            await prefs.setBool('user_has_collection_access', hasCollectionAccess);
            await prefs.setString(keyExpiryDate, purchaseEndDate.toIso8601String());
            await prefs.setString('user_subscription_start', purchaseStartDate.toIso8601String());
          }
        }
      }
    } catch (error) {
      throw Exception(error);
    } finally {
      setIsSubscriptionIdLoading = false;
    }
  }

  void clearData() {
    setSubscriptionDaysLeft = "";
    purchasedCollections.clear();
  }
}
