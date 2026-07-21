import 'dart:async';

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

  /// The product id encodes its duration as a trailing `_days` segment
  /// (e.g. com.wallrio.yearly_365) — reused here to anchor a per-day price.
  int? _daysForProduct(String productId) {
    final suffix = productId.split('_').last;
    return int.tryParse(suffix);
  }

  String? _perDayPrice(ProductDetails product) {
    final days = _daysForProduct(product.id);
    if (days == null || days <= 0) return null;
    final symbol = product.price.replaceAll(RegExp(r'[\d.,\s]+'), '').trim();
    final perDay = product.rawPrice / days;
    return '$symbol${perDay.toStringAsFixed(perDay < 10 ? 1 : 0)}/day';
  }

  String _ctaLabel(List<ProductDetails> products) {
    if (_selectedProductId == null) return 'Continue';
    if (_selectedProductId == SubscriptionProvider.lifetimeProductId) {
      return 'Get Lifetime Access';
    }
    final match = products.cast<dynamic>().firstWhere(
        (p) => p.id == _selectedProductId,
        orElse: () => null);
    if (match == null) return 'Continue';
    return 'Continue • ${match.price}';
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDark ? Colors.white : Colors.black;
  Color get _subColor => _isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _sheetColor => _isDark ? bgDark2Color : const Color(0xFFF2F2F7);

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, wallRio, _) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          widget.onComplete();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
          ),
          child: Material(
            color: _sheetColor,
            child: _buildContent(
                context, wallRio.subscriptionPlans, wallRio.originalWallList),
          ),
        ),
      );
    });
  }

  Widget _buildContent(BuildContext context, List<SubscriptionPlan> plans, List<Walls> allWalls) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SubscriptionTopAnimatedBanner(allWalls: allWalls),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildFeatureList(),
                        const SizedBox(height: 16),
                        _buildLifetimeCard(plans),
                        const SizedBox(height: 8),
                        _buildOtherPlans(plans),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
            child: _buildCTA(),
          ),
        ],
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

  static const List<String> _features = [
    "Premium Collections",
    "Custom App Icons",
    "Live Wallpapers",
    "100% Ad-Free",
  ];

  Widget _buildFeatureList() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFeatureRow(_features[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildFeatureRow(_features[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildFeatureRow(_features[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildFeatureRow(_features[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: bgDarkAccentColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeCard(List<SubscriptionPlan> plans) {
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
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? bgDarkAccentColor.withValues(alpha: 0.12) : _textColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? bgDarkAccentColor.withValues(alpha: 0.6) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RadioDot(isSelected: isSelected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Lifetime",
                            style: TextStyle(color: _textColor, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: bgDarkAccentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "LIMITED TIME",
                              style: TextStyle(
                                color: bgDarkAccentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "One-time payment. Yours forever.",
                        style: TextStyle(color: _subColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (discount > 0) ...[
                      _buildDiscountChip(discount),
                      const SizedBox(height: 3),
                    ],
                    if (plan != null && lifetimeProd != null)
                      Text(
                        _formatActualPrice(lifetimeProd, plan.actualPrice),
                        style: TextStyle(
                          color: _subColor,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _subColor,
                        ),
                      ),
                    Text(
                      lifetimeProd?.price ?? "—",
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _productOrderIndex(String id) {
    if (id == SubscriptionProvider.yearlyProductId) return 1;
    if (id == SubscriptionProvider.quaterlyProductId) return 2;
    if (id == SubscriptionProvider.monthlyProductId) return 3;
    return 4;
  }

  Widget _buildOtherPlans(List<SubscriptionPlan> plans) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final others = subProvider.products
            .where((p) => p.id != SubscriptionProvider.lifetimeProductId && !p.id.contains('collection'))
            .toList()
          ..sort((a, b) => _productOrderIndex(a.id).compareTo(_productOrderIndex(b.id)));
        if (others.isEmpty) return const SizedBox.shrink();
        return Column(
          children: others.map((product) {
            final isSelected = _selectedProductId == product.id;
            final plan = _planFor(product.id, plans);
            final discount = plan != null
                ? _discountPercent(product.rawPrice, plan.actualPrice)
                : 0;
            final labelColor = isSelected ? _textColor : _textColor.withValues(alpha: 0.65);

            String displayTitle;
            String subtitle;
            Widget? badgeWidget;

            if (product.id == SubscriptionProvider.yearlyProductId) {
              displayTitle = "Yearly";
              subtitle = "Billed annually. Full access.";
              badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bgDarkAccentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "POPULAR",
                  style: TextStyle(
                    color: bgDarkAccentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            } else if (product.id == SubscriptionProvider.quaterlyProductId) {
              displayTitle = "Quarterly";
              subtitle = "Billed every 3 months. Flexible.";
            } else if (product.id == SubscriptionProvider.monthlyProductId) {
              displayTitle = "Monthly";
              subtitle = "Billed monthly. Cancel anytime.";
            } else {
              displayTitle = product.title.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
              subtitle = "Flexible plan. Cancel anytime.";
            }

            return GestureDetector(
              onTap: () => setState(() => _selectedProductId = product.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? bgDarkAccentColor.withValues(alpha: 0.12) : _textColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? bgDarkAccentColor.withValues(alpha: 0.6) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _RadioDot(isSelected: isSelected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayTitle,
                                style: TextStyle(color: labelColor, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              if (badgeWidget != null) ...[
                                const SizedBox(width: 8),
                                badgeWidget,
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(color: _subColor, fontSize: 12),
                          ),
                        ],
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
                                    color: _subColor,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: _subColor,
                                  ),
                                ),
                              ),
                            Text(
                              product.price,
                              style: TextStyle(color: labelColor, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 3),
                          _buildDiscountChip(discount),
                        ],
                        if (_perDayPrice(product) != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'just ${_perDayPrice(product)}',
                            style: TextStyle(color: _subColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildCTA() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final hasProducts = subProvider.products.isNotEmpty;
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: hasProducts ? _purchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgDarkAccentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: bgDarkAccentColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: subProvider.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _ctaLabel(subProvider.products),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            _buildTrustRow(),
            TextButton(
              onPressed: widget.onComplete,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Continue with free",
                style: TextStyle(color: _subColor, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrustRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTrustItem(Icons.lock_rounded, "Secure payment"),
          const SizedBox(width: 16),
          _buildTrustItem(
            _selectedProductId == SubscriptionProvider.lifetimeProductId
                ? Icons.done_all_rounded
                : Icons.event_repeat_rounded,
            _selectedProductId == SubscriptionProvider.lifetimeProductId
                ? "Pay once, forever"
                : "Cancel anytime",
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _subColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: _subColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;
  const _RadioDot({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
    );
  }
}

class _SubscriptionTopAnimatedBanner extends StatefulWidget {
  final List<Walls> allWalls;
  const _SubscriptionTopAnimatedBanner({required this.allWalls});

  @override
  State<_SubscriptionTopAnimatedBanner> createState() =>
      _SubscriptionTopAnimatedBannerState();
}

class _SubscriptionTopAnimatedBannerState
    extends State<_SubscriptionTopAnimatedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  List<Walls> _bannerWalls = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    if (widget.allWalls.isNotEmpty) {
      _loadOrSaveLocalWalls(widget.allWalls);
    }
  }

  @override
  void didUpdateWidget(covariant _SubscriptionTopAnimatedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isLoaded && widget.allWalls.isNotEmpty) {
      _loadOrSaveLocalWalls(widget.allWalls);
    }
  }

  Future<void> _loadOrSaveLocalWalls(List<Walls> allWalls) async {
    try {
      _isLoaded = true;
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('sub_page_pro_wallpaper_ids_20');

      if (savedIds != null && savedIds.isNotEmpty) {
        final Map<int, Walls> wallMap = {for (var w in allWalls) w.id: w};
        final loaded = <Walls>[];
        for (final idStr in savedIds) {
          final id = int.tryParse(idStr);
          if (id != null && wallMap.containsKey(id)) {
            loaded.add(wallMap[id]!);
          }
        }
        if (loaded.length >= 10) {
          if (mounted) setState(() => _bannerWalls = loaded);
          return;
        }
      }

      final proWalls = allWalls.where((w) => w.isPremium).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      final sourceList = proWalls.isNotEmpty ? proWalls : allWalls;
      final selected = sourceList.take(20).toList();

      final idsToSave = selected.map((w) => w.id.toString()).toList();
      await prefs.setStringList('sub_page_pro_wallpaper_ids_20', idsToSave);

      if (mounted) setState(() => _bannerWalls = selected);
    } catch (e) {
      logger.e('Error loading subscription page pro walls: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDark ? Colors.white : Colors.black;
  Color get _subColor => _isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _sheetColor => _isDark ? bgDark2Color : const Color(0xFFF2F2F7);

  Widget _buildCard(Walls wall, double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: wall.thumbnail.isNotEmpty ? wall.thumbnail : wall.url,
              fit: BoxFit.cover,
              width: width,
              height: height,
              filterQuality: FilterQuality.high,
              placeholder: (_, __) =>
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allToUse = _bannerWalls.isNotEmpty
        ? _bannerWalls
        : widget.allWalls.where((w) => w.isPremium).toList().take(20).toList();

    final row1ToUse = allToUse.take(10).toList();
    final row2ToUse = allToUse.length >= 20
        ? allToUse.skip(10).take(10).toList()
        : row1ToUse.reversed.toList();

    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // 1. Dual-Row Marquee Tracks animating in opposite directions
          Positioned.fill(
            child: allToUse.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top Row: Animates Left-to-Right
                        SizedBox(
                          height: 104,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              const cardWidth = 82.0;
                              const cardMargin = 8.0;
                              final totalWidth =
                                  row1ToUse.length * (cardWidth + cardMargin);
                              final maxScroll = (totalWidth * 2) -
                                  MediaQuery.of(context).size.width +
                                  40;
                              final dx = -(_animController.value * maxScroll)
                                  .clamp(0.0, totalWidth * 1.5);

                              final doubleWalls = [
                                ...row1ToUse,
                                ...row1ToUse,
                              ];

                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: OverflowBox(
                                  minWidth: 0,
                                  maxWidth: double.infinity,
                                  minHeight: 104,
                                  maxHeight: 104,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: doubleWalls
                                        .map((w) => _buildCard(w, cardWidth, 104))
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Bottom Row: Animates in OPPOSITE Direction (Right-to-Left)
                        SizedBox(
                          height: 104,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              const cardWidth = 82.0;
                              const cardMargin = 8.0;
                              final totalWidth =
                                  row2ToUse.length * (cardWidth + cardMargin);
                              final maxScroll = (totalWidth * 2) -
                                  MediaQuery.of(context).size.width +
                                  40;
                              final dx = -((1.0 - _animController.value) *
                                      maxScroll)
                                  .clamp(0.0, totalWidth * 1.5);

                              final doubleWalls = [
                                ...row2ToUse,
                                ...row2ToUse,
                              ];

                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: OverflowBox(
                                  minWidth: 0,
                                  maxWidth: double.infinity,
                                  minHeight: 104,
                                  maxHeight: 104,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: doubleWalls
                                        .map((w) => _buildCard(w, cardWidth, 104))
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Light / Dark mode legibility gradient overlay (seamlessly blends to page background)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    _sheetColor.withValues(alpha: 0.0),
                    _sheetColor.withValues(alpha: 0.7),
                    _sheetColor,
                  ],
                ),
              ),
            ),
          ),

          // 3. Foreground Overlay Title ("Wall" + green "Rio" + gold "Pro") & Rating Chip
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(text: "Wall", style: TextStyle(color: _textColor)),
                      const TextSpan(
                        text: "Rio",
                        style: TextStyle(
                          color: bgDarkAccentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(
                        text: " Pro",
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        "4.8  •  400+ ratings  •  100k+ downloads",
                        style: TextStyle(
                          color: _subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
