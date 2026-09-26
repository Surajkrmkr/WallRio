import 'dart:async' show Future, Stream, StreamSubscription;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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
  static const String androidSubscriptionProductId = 'wallrio_pro';
  static final String monthlyProductId = Platform.isIOS
      ? 'com.wallrio.ios.monthly_28'
      : androidSubscriptionProductId;
  static final String quaterlyProductId = Platform.isIOS
      ? 'com.wallrio.ios.quaterly_84'
      : androidSubscriptionProductId;
  static final String yearlyProductId = Platform.isIOS
      ? 'com.wallrio.ios.yearly_365'
      : androidSubscriptionProductId;

  final Set<String> productIDs = Platform.isIOS
      ? {
          lifetimeProductId,
          monthlyProductId,
          quaterlyProductId,
          yearlyProductId,
        }
      : {
          lifetimeProductId,
          androidSubscriptionProductId,
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
  bool get isSupported => _service is AndroidPremiumService
      ? (_service as AndroidPremiumService).isSupported
      : (_service as IOSPremiumService).isSupported;

  List<ProductDetails> get products => _service.products;
  Set<String> get purchasedCollections => _service.purchasedCollections;
  String get subscriptionDaysLeft => _service.subscriptionDaysLeft;

  static String? androidBasePlanId(ProductDetails product) {
    if (product is! GooglePlayProductDetails ||
        product.subscriptionIndex == null) {
      return null;
    }
    final offers = product.productDetails.subscriptionOfferDetails;
    final index = product.subscriptionIndex!;
    if (offers == null || index >= offers.length) return null;
    return offers[index].basePlanId;
  }

  static String? androidBillingPeriod(ProductDetails product) {
    if (product is! GooglePlayProductDetails ||
        product.subscriptionIndex == null) {
      return null;
    }
    final offers = product.productDetails.subscriptionOfferDetails;
    final index = product.subscriptionIndex!;
    if (offers == null || index >= offers.length) return null;
    final phases = offers[index].pricingPhases;
    return phases.isEmpty ? null : phases.first.billingPeriod;
  }

  static String selectionId(ProductDetails product) {
    final basePlanId = androidBasePlanId(product);
    return basePlanId == null
        ? product.id
        : '$androidSubscriptionProductId:$basePlanId';
  }

  static String billingPeriodDescription(ProductDetails product) {
    final period = androidBillingPeriod(product);
    if (period == null) return product.id;
    final match = RegExp(
      r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$',
    ).firstMatch(period);
    if (match == null) return product.id;
    final years = int.tryParse(match.group(1) ?? '0') ?? 0;
    final months = int.tryParse(match.group(2) ?? '0') ?? 0;
    final weeks = int.tryParse(match.group(3) ?? '0') ?? 0;
    final days = int.tryParse(match.group(4) ?? '0') ?? 0;
    final totalMonths = years * 12 + months;
    if (totalMonths > 0) {
      return 'every $totalMonths ${totalMonths == 1 ? 'month' : 'months'}';
    }
    if (weeks > 0) return 'every $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    if (days > 0) return 'every $days ${days == 1 ? 'day' : 'days'}';
    return product.id;
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

  Future<bool> buyProductById(String rawProductId) async {
    final String shortId = rawProductId.split('.').last;
    final String fullProductId =
        rawProductId.startsWith('com.wallrio.collection.')
            ? rawProductId
            : 'com.wallrio.collection.$rawProductId';

    final idsToTry = {fullProductId, shortId, rawProductId};
    await fetchProducts(idsToTry);

    final product = products.cast<ProductDetails?>().firstWhere(
          (p) =>
              p != null && (idsToTry.contains(p.id) || p.id.endsWith(shortId)),
          orElse: () => null,
        );

    if (product != null) {
      await buyProduct(product);
      return true;
    }
    return false;
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
