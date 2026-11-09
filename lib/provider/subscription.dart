import 'dart:async' show Future, Stream, StreamSubscription, Timer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallrio/model/user_profile_model.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/services/premium/debug_offer_preview.dart';
import 'package:wallrio/services/premium/play_offer_adapter.dart';
import 'package:wallrio/ui/widgets/toast_widget.dart';

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

  /// True while the limited-time drop-off offer window is open.
  bool _dropoffActive = false;
  bool get dropoffActive => _dropoffActive;
  Timer? _dropoffTimer;

  final PublishSubject<bool> _successPurchased = PublishSubject<bool>();
  Stream<bool> get successPurchasedStream => _successPurchased.stream;

  SubscriptionProvider() {
    _service = Platform.isIOS ? IOSPremiumService() : AndroidPremiumService();
    _restoreDropoff();
    _purchaseSub = _service.successPurchasedStream.listen((event) {
      _successPurchased.sink.add(event);
      notifyListeners();
    });
  }

  bool get isLoading => _service.isLoading;
  bool get isSupported => _service is AndroidPremiumService
      ? _service.isSupported
      : (_service as IOSPremiumService).isSupported;

  /// What the paywall shows. For Android subscriptions Play returns one
  /// product per offer (the plain plan plus any trial or discount the user
  /// qualifies for); this collapses them to one product per base plan, picking
  /// the best offer. Lifetime, collection and iOS products pass through as is.
  List<ProductDetails> get _rawProducts => DebugOfferPreview.enabled
      ? DebugOfferPreview.apply<ProductDetails>(_service.products)
      : _service.products;

  List<ProductDetails> get products {
    final raw = _rawProducts;
    if (!Platform.isAndroid) return raw;

    final offers = <OfferView>[];
    for (var i = 0; i < raw.length; i++) {
      final view = _offerView(raw[i], i);
      if (view != null) offers.add(view);
    }
    if (offers.isEmpty) return raw;

    final chosen = {
      for (final c in PlanOffers.select(offers, dropoffActive: _dropoffActive)) c.purchase.index: c,
    };
    final skip = {for (final o in offers) o.index}..removeAll(chosen.keys);
    return [
      for (var i = 0; i < raw.length; i++)
        if (!skip.contains(i)) raw[i],
    ];
  }

  Future<void> _restoreDropoff() async {
    await DropoffOffer.load();
    _syncDropoff();
  }

  /// Re-reads the window and schedules the moment it closes.
  void _syncDropoff() {
    final active = DropoffOffer.isActive();
    _dropoffTimer?.cancel();
    if (active) {
      _dropoffTimer = Timer(
        DropoffOffer.remaining() + const Duration(seconds: 1),
        _syncDropoff,
      );
    }
    if (active != _dropoffActive) {
      _dropoffActive = active;
      notifyListeners();
    }
  }

  /// The discounted yearly plan the drop-off offer would sell right now, or
  /// null when Play has no drop-off offer for this user (not configured, or
  /// the user is not eligible). Safe to call before the window opens.
  PlanChoice? get dropoffChoice {
    if (!Platform.isAndroid) return null;
    final raw = _rawProducts;
    final offers = <OfferView>[];
    for (var i = 0; i < raw.length; i++) {
      final v = _offerView(raw[i], i);
      if (v != null) offers.add(v);
    }
    for (final c in PlanOffers.select(offers, dropoffActive: true)) {
      if (c.kind == OfferKind.discount && PlanOffers.isDropoff(c.purchase)) {
        return c;
      }
    }
    return null;
  }

  /// Whether to show the one-time offer now: a free user, an offer exists and
  /// the window has never been opened.
  bool get shouldShowDropoff =>
      Platform.isAndroid &&
      !UserProfile.plusMember &&
      !DropoffOffer.wasShown &&
      dropoffChoice != null;

  /// Opens the 2 hour window (once) and switches the paywall to the offer.
  Future<void> startDropoff() async {
    await DropoffOffer.start();
    _syncDropoff();
  }

  OfferView? _offerView(ProductDetails product, int index) =>
      PlayOfferAdapter.toOfferView(product, index);

  /// The trial/discount choice behind [product], or null for products that
  /// are not Android subscriptions.
  PlanChoice? choiceFor(ProductDetails product) {
    if (!Platform.isAndroid) return null;
    final raw = _rawProducts;
    final index = raw.indexOf(product);
    final here = index < 0 ? null : _offerView(product, index);
    if (here == null) return null;

    final group = <OfferView>[];
    for (var i = 0; i < raw.length; i++) {
      final v = _offerView(raw[i], i);
      if (v != null && v.basePlanId == here.basePlanId) group.add(v);
    }
    final choices = PlanOffers.select(group, dropoffActive: _dropoffActive);
    return choices.isEmpty ? null : choices.first;
  }

  /// The price the user pays on renewal. For a plan with a free trial,
  /// `product.price` is the trial's price ("free"), which must never be shown
  /// as the plan price.
  String priceOf(ProductDetails product) =>
      choiceFor(product)?.recurring.formattedPrice ?? product.price;

  double rawPriceOf(ProductDetails product) =>
      choiceFor(product)?.recurring.price ?? product.rawPrice;
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
    return phases.isEmpty ? null : phases.last.billingPeriod;
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
    if (DebugOfferPreview.isPreviewProduct(prod)) {
      ToastWidget.showToast('Preview only: purchasing is disabled');
      return;
    }
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
    _dropoffTimer?.cancel();
    _purchaseSub?.cancel();
    _service.dispose();
    _successPurchased.close();
    super.dispose();
  }
}
