import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';

class OnboardingScreen4 extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen4({super.key, required this.onComplete});

  @override
  State<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends State<OnboardingScreen4> {
  String? _selectedProductId;
  List<Walls>? _bgWalls; // cached — never re-randomize on setState
  StreamSubscription<bool>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _selectedProductId = SubscriptionProvider.lifetimeProductId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _purchaseSub = Provider.of<SubscriptionProvider>(context, listen: false)
          .successPurchasedStream
          .listen((success) {
        if (success && mounted) widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _cacheBgWalls(List<Walls> all) {
    if (_bgWalls == null && all.isNotEmpty) {
      final shuffled = List<Walls>.from(all)..shuffle(Random());
      _bgWalls = shuffled.take(4).toList();
    }
  }

  void _purchase() {
    final subProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    if (_selectedProductId == null) return;
    ProductDetails? product;
    for (final p in subProvider.products) {
      if (p.id == _selectedProductId) {
        product = p;
        break;
      }
    }
    if (product != null) subProvider.buyProduct(product);
  }

  SubscriptionPlan? _planFor(String id, List<SubscriptionPlan> plans) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  int _discountPercent(double rawPrice, int actualPrice) {
    if (actualPrice <= 0 || rawPrice <= 0) return 0;
    return ((actualPrice - rawPrice) / actualPrice * 100).round().abs();
  }

  String _formatActualPrice(ProductDetails product, int actualPrice) {
    final symbol = product.price.replaceAll(RegExp(r'[\d.,\s]+'), '').trim();
    return '$symbol$actualPrice';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, wallRio, _) {
      _cacheBgWalls(wallRio.originalWallList);
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          widget.onComplete();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Material(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(),
                _buildBlurOverlay(),
                Center(child: _buildContent(context, wallRio.subscriptionPlans)),
            ],
          ),
        ),
        ),
      );
    });
  }

  Widget _buildBackground() {
    final walls = _bgWalls;
    if (walls == null || walls.isEmpty) {
      return Container(color: bgDarkColor);
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.65,
      children: walls
          .map((w) => CachedNetworkImage(
                imageUrl: w.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: bgDark2Color),
                errorWidget: (_, __, ___) => Container(color: bgDark2Color),
              ))
          .toList(),
    );
  }

  Widget _buildBlurOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.60),
              Colors.black.withValues(alpha: 0.90),
              Colors.black.withValues(alpha: 1.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<SubscriptionPlan> plans) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 22),
            _buildFeatureList(),
            const SizedBox(height: 20),
            _buildLifetimeCard(context, plans),
            const SizedBox(height: 10),
            _buildOtherPlans(context, plans),
            const SizedBox(height: 22),
            _buildCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountChip(int percent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$percent% off',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Container(
        //   width: 52,
        //   height: 52,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: bgDarkAccentColor.withValues(alpha: 0.15),
        //     border: Border.all(
        //         color: bgDarkAccentColor.withValues(alpha: 0.4), width: 1.5),
        //   ),
        //   padding: const EdgeInsets.all(10),
        //   child: Image.asset(
        //     "assets/app_icon/icon_white.png",
        //     fit: BoxFit.contain,
        //   ),
        // ),
        const SizedBox(height: 14),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
            children: const [
              TextSpan(text: "WallRio ", style: TextStyle(color: whiteColor)),
              TextSpan(text: "Pro", style: TextStyle(color: bgDarkAccentColor)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Unlock exclusive collections & personalize your app",
          style: TextStyle(
            color: whiteColor.withValues(alpha: 0.5),
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static const List<String> _features = [
    "Unlock all Premium Collections (Yearly & Lifetime plans only)",
    "Personalize with Custom App Icons",
    "Download Exclusive Live Wallpapers",
    "100% Ad-free experience",
  ];

  Widget _buildFeatureList() {
    return Column(
      children: [
        for (final feature in _features) ...[
          _buildFeatureTile(feature),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildFeatureTile(String feature) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgDarkAccentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: bgDarkAccentColor, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            feature,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeCard(
      BuildContext context, List<SubscriptionPlan> plans) {
    final isSelected = _selectedProductId == SubscriptionProvider.lifetimeProductId;
    final plan = _planFor(SubscriptionProvider.lifetimeProductId, plans);
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        ProductDetails? lifetimeProd;
        for (final p in subProvider.products) {
          if (p.id == SubscriptionProvider.lifetimeProductId) {
            lifetimeProd = p;
            break;
          }
        }
        final discount = (plan != null && lifetimeProd != null)
            ? _discountPercent(lifetimeProd.rawPrice, plan.actualPrice)
            : 0;
        return GestureDetector(
          onTap: () => setState(() => _selectedProductId = SubscriptionProvider.lifetimeProductId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ABFAA), Color(0xFF178A76)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? whiteColor.withValues(alpha: 0.45)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: bgDarkAccentColor.withValues(
                      alpha: isSelected ? 0.4 : 0.15),
                  blurRadius: isSelected ? 24 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Lifetime Pro",
                            style: TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "BEST VALUE",
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "One-time payment. Yours forever.",
                        style: TextStyle(
                          color: whiteColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (discount > 0) ...[
                      _buildDiscountChip(discount),
                      const SizedBox(height: 3),
                    ],
                    if (plan != null && lifetimeProd != null)
                      Text(
                        _formatActualPrice(lifetimeProd, plan.actualPrice),
                        style: TextStyle(
                          color: whiteColor.withValues(alpha: 0.55),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: whiteColor.withValues(alpha: 0.55),
                        ),
                      ),
                    Text(
                      lifetimeProd?.price ?? "—",
                      style: const TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RadioDot(isSelected: isSelected),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherPlans(BuildContext context, List<SubscriptionPlan> plans) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final others = subProvider.products
            .where((p) => p.id != SubscriptionProvider.lifetimeProductId && !p.id.contains('collection'))
            .toList();
        if (others.isEmpty) return const SizedBox.shrink();
        return Column(
          children: others.map((product) {
            final isSelected = _selectedProductId == product.id;
            final plan = _planFor(product.id, plans);
            final discount = plan != null
                ? _discountPercent(product.rawPrice, plan.actualPrice)
                : 0;
            final labelColor =
                isSelected ? whiteColor : whiteColor.withValues(alpha: 0.65);
            return GestureDetector(
              onTap: () => setState(() => _selectedProductId = product.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? whiteColor.withValues(alpha: 0.1)
                      : whiteColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? whiteColor.withValues(alpha: 0.28)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _RadioDot(isSelected: isSelected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (plan != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  _formatActualPrice(product, plan.actualPrice),
                                  style: TextStyle(
                                    color: whiteColor.withValues(alpha: 0.4),
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor:
                                        whiteColor.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            Text(
                              product.price,
                              style: TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 3),
                          _buildDiscountChip(discount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final hasProducts = subProvider.products.isNotEmpty;
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasProducts ? _purchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: whiteColor,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  disabledForegroundColor: whiteColor.withValues(alpha: 0.35),
                  elevation: 4,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: subProvider.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.black45, strokeWidth: 2.5),
                      )
                    : const Text(
                        "Unlock WallRio Pro",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
            TextButton(
              onPressed: widget.onComplete,
              child: Text(
                "Continue with free",
                style: TextStyle(
                  color: whiteColor.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ),

          ],
        );
      },
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;
  const _RadioDot({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? bgDarkAccentColor : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? bgDarkAccentColor
              : whiteColor.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: whiteColor, size: 12)
          : null,
    );
  }
}
