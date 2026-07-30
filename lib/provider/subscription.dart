import 'dart:async' show Future, Stream, StreamSubscription;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const String keyPlusMember = 'user_is_plus_member';
  static const String keyExpiryDate = 'user_subscription_expiry';

  late final PremiumService _service;
  StreamSubscription<bool>? _purchaseSub;

  bool isSubscriptionLoading = false;
  bool isSubcriptionAnimating = false;

  static final String lifetimeProductId = Platform.isIOS
      ? 'com.wallrio.ios.lifetime_pro'
      : 'com.wallrio.lifetime_pro';
  static final String monthlyProductId =
      Platform.isIOS ? 'com.wallrio.ios.monthly_28' : 'com.wallrio.monthly_28';
  static final String quaterlyProductId = Platform.isIOS
      ? 'com.wallrio.ios.quaterly_84'
      : 'com.wallrio.quaterly_84';
  static final String yearlyProductId =
      Platform.isIOS ? 'com.wallrio.ios.yearly_365' : 'com.wallrio.yearly_365';

  final Set<String> productIDs = {
    lifetimeProductId,
    monthlyProductId,
    quaterlyProductId,
    yearlyProductId,
  };

  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  SubscriptionProvider() {
    _service = Platform.isIOS ? IOSPremiumService() : AndroidPremiumService();
    _purchaseSub = _service.successPurchasedStream.listen((event) {
      _successPurchased.sink.add(event);
      notifyListeners();
    });
  }

  bool get isLoading => _service.isLoading;
  bool get isSupported =>
      _service is AndroidPremiumService
          ? (_service as AndroidPremiumService).isSupported
          : (_service as IOSPremiumService).isSupported;

  List<ProductDetails> get products => _service.products;
  Set<String> get purchasedCollections => _service.purchasedCollections;
  String get subscriptionDaysLeft => _service.subscriptionDaysLeft;

  set setIsSubscriptionIdLoading(bool val) {
    isSubscriptionLoading = val;
    notifyListeners();
  }

  set setIsSubcriptionAnimating(bool val) {
    isSubcriptionAnimating = val;
    notifyListeners();
  }

  Future<void> checkSupportForIAP() async {
    setIsSubscriptionIdLoading = true;
    try {
      await _service.checkSupportForIAP(productIDs);
    } finally {
      setIsSubscriptionIdLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUserProducts() async {
    await _service.getUserProducts(productIDs);
    notifyListeners();
  }

  Future<void> fetchProducts(Set<String> extraProductIDs) async {
    for (String id in extraProductIDs) {
      if (!productIDs.contains(id)) {
        productIDs.add(id);
      }
    }
    await _service.getUserProducts(productIDs);
    notifyListeners();
  }

  void addCollectionProductIds(List<String> collectionIds) {
    bool added = false;
    for (String id in collectionIds) {
      final prodId = id.startsWith('com.wallrio.collection.')
          ? id
          : 'com.wallrio.collection.$id';
      if (!productIDs.contains(prodId)) {
        productIDs.add(prodId);
        added = true;
      }
    }
    if (added) getUserProducts();
  }

  Future<void> buyProduct(ProductDetails prod) async {
    await _service.buyProduct(prod);
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    await _service.restorePurchases();
    notifyListeners();
  }

  Future<void> checkPastPurchases({String? email}) async {
    setIsSubscriptionIdLoading = true;
    try {
      if (Platform.isIOS) {
        await _service.checkPastPurchases();
      } else {
        await _service.checkPastPurchases(email: email);
      }
    } finally {
      setIsSubscriptionIdLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearPurchaseSharedPreferences() async {
    await _service.clearPurchaseSharedPreferences();
    notifyListeners();
  }

  void clearData() {
    _service.purchasedCollections.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _service.dispose();
    _successPurchased.close();
    super.dispose();
  }
}
