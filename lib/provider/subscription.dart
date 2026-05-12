import 'dart:async' show Future, Stream, StreamSubscription;

import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SubscriptionProvider extends ChangeNotifier {
  final String subscriptionFirebasePath = "purchases";

  bool isLoading = false;
  bool isSupported = false;
  bool isSubscriptionLoading = false;
  bool isSubcriptionAnimating = false;

  String _subscriptionDaysLeft = "";

  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];

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

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  set setIsSubscriptionIdLoading(val) {
    isSubscriptionLoading = val;
    notifyListeners();
  }

  set setIsSubcriptionAnimating(val) {
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

  void buyProduct(ProductDetails prod) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
      if (prod.id == lifetimeProductId) {
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
      final int subscriptionDays = purchase.productID == lifetimeProductId
          ? 36135 // ~99 years
          : int.parse(purchase.productID.split("_").last);
      final now = DateTime.now();
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
      UserProfile.setPlusMemberInfo(true);
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
      final CollectionReference purchases =
          FirebaseFirestore.instance.collection(subscriptionFirebasePath);
      final QuerySnapshot<Object?> querySnapshot = await purchases.get();
      final now = DateTime.now();
      UserProfile.setPlusMemberInfo(false);
      for (var element in querySnapshot.docs) {
        if (element["email"] == email) {
          final purchaseStartDate =
              DateTime.parse(element["purchaseStartDate"].toDate().toString())
                  .toLocal();
          final purchaseEndDate =
              DateTime.parse(element["purchaseEndDate"].toDate().toString())
                  .toLocal();
          final bool isPurchaseActive =
              purchaseStartDate.isBefore(now) && purchaseEndDate.isAfter(now);
          if (isPurchaseActive) {
            setSubscriptionDaysLeft =
                (purchaseEndDate.difference(now).inDays + 1).toString();
            UserProfile.setPlusMemberInfo(true);
            return;
          }
        }
      }
    } catch (error) {
      throw Exception(error);
    } finally {
      setIsSubscriptionIdLoading = false;
    }
  }

  void clearData() => setSubscriptionDaysLeft = "";
}
