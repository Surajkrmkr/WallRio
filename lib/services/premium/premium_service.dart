import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class PremiumService {
  Future<void> checkSupportForIAP(Set<String> productIDs);
  Future<void> getUserProducts(Set<String> productIDs);
  Future<void> buyProduct(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> checkPastPurchases({String? email});
  Future<void> clearPurchaseSharedPreferences();
  void dispose();

  List<ProductDetails> get products;
  Set<String> get purchasedCollections;
  Stream<bool> get successPurchasedStream;
  bool get isLoading;
  String get subscriptionDaysLeft;
}
