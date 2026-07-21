import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/pages.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  Timer _timer = Timer(Duration.zero, () {});
  bool _showPromoBanner = false;
  static const String _promoDismissKey = 'promo_banner_dismissed_date';
  bool _isChanging = false;

  Future<void> _applyRandomWallpaper() async {
    final wallRio = Provider.of<WallRio>(context, listen: false);
    final walls = wallRio.actionWallList.isNotEmpty
        ? wallRio.actionWallList
        : wallRio.originalWallList;
    if (walls.isEmpty) return;

    setState(() => _isChanging = true);
    final randomWall = walls[Random().nextInt(walls.length)];

    try {
      final file = await DefaultCacheManager().getSingleFile(randomWall.url);
      await WallpaperManagerPlus().setWallpaper(file, 1);
      ToastWidget.showToast('Wallpaper rotated!');
    } catch (e) {
      ToastWidget.showToast('Failed to apply wallpaper');
    }

    if (mounted) setState(() => _isChanging = false);
  }

  @override
  void initState() {
    TrackingService.requestIfNeeded();
    Future.delayed(Duration.zero, () {
      _checkUserIsDisable(_timer);
      if (!mounted) return;
      final wallRio = Provider.of<WallRio>(context, listen: false);
      if (wallRio.originalWallList.isEmpty) {
        wallRio.getListFromAPI(context);
      }
      final liveProvider =
          Provider.of<LiveWallpaperProvider>(context, listen: false);
      if (liveProvider.wallList.isEmpty) {
        liveProvider.getListFromAPI();
      }
      if (UserProfile.plusMember) {
        Provider.of<FavouriteProvider>(context, listen: false)
            .getFavouritesFromFirebase();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 30), _checkUserIsDisable);
    _checkPromoBanner();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkRateUsPopup();
    });

    super.initState();
  }

  Future<void> _checkRateUsPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRated = prefs.getBool('rate_has_rated') ?? false;
    final bool rateRefused = prefs.getBool('rate_refused') ?? false;
    if (hasRated || rateRefused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    int firstLaunch = prefs.getInt('app_first_launch_time') ?? 0;
    if (firstLaunch == 0) {
      firstLaunch = now;
      await prefs.setInt('app_first_launch_time', firstLaunch);
    }

    final hoursSinceInstall = (now - firstLaunch) / (1000 * 60 * 60);
    final dismissCount = prefs.getInt('rate_dismiss_count') ?? 0;

    bool shouldShow = false;

    if (dismissCount == 0) {
      if (hoursSinceInstall >= 24) {
        shouldShow = true;
      }
    } else if (dismissCount == 1) {
      final lastDismiss = prefs.getInt('rate_last_dismiss_time') ?? 0;
      final daysSinceDismiss = (now - lastDismiss) / (1000 * 60 * 60 * 24);
      if (daysSinceDismiss >= 4) {
        shouldShow = true;
      }
    }

    if (shouldShow && mounted) {
      _showRateUsDialog(context);
    }
  }

  void _showRateUsDialog(BuildContext context) {
    final progProvider = Provider.of<ProgressionProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RateUsDialog(
        onRateNow: () async {
          Navigator.pop(dialogContext);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rate_has_rated', true);

          final String url = Platform.isAndroid
              ? "https://play.google.com/store/apps/details?id=com.shadowteam.wallrio"
              : "https://apps.apple.com/app/wallrio/id6789848688";
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

          if (!UserProfile.plusMember) {
            progProvider.trackAction(ActionType.rateApp);
          }
        },
        onDismiss: () async {
          Navigator.pop(dialogContext);
          final prefs = await SharedPreferences.getInstance();
          final count = prefs.getInt('rate_dismiss_count') ?? 0;
          if (count == 0) {
            await prefs.setInt('rate_dismiss_count', 1);
            await prefs.setInt(
                'rate_last_dismiss_time', DateTime.now().millisecondsSinceEpoch);
          } else {
            await prefs.setBool('rate_refused', true);
          }
        },
      ),
    );
  }

  Future<void> _checkPromoBanner() async {
    if (UserProfile.plusMember) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissedDate = prefs.getString(_promoDismissKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (dismissedDate != today) {
      if (mounted) setState(() => _showPromoBanner = true);
    }
  }

  Future<void> _dismissPromoBanner() async {
    setState(() => _showPromoBanner = false);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_promoDismissKey, today);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkUserIsDisable(Timer timer) {
    try {
      FirebaseAuth.instance.currentUser!.reload();
    } catch (error) {
      logger.e(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<Navigation>(builder: (context, provider, _) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 500) {
                  Provider.of<WallRio>(context, listen: false).loadMore();
                }
              }
              return false;
            },
            child: Stack(
              children: [
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) =>
                      FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  ),
                  child: pages[provider.index],
                ),
                if (_showPromoBanner && !UserProfile.plusMember)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom +
                        16 +
                        61 +
                        20 +
                        60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildPromoBanner(context),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: RepaintBoundary(
            child: Platform.isIOS
                ? _buildCupertinoTabBar(provider, isDarkMode)
                : _buildCustomTabBar(provider, isDarkMode),
          ),
          // The shuffle FAB sets the home-screen wallpaper directly via
          // WallpaperManagerPlus, which has no iOS equivalent (no API sets a
          // wallpaper without user interaction), so it's Android-only.
          floatingActionButton: Platform.isAndroid
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: UserProfile.plusMember
                        ? 0.0
                        : (_showPromoBanner ? 140.0 : 70.0),
                  ),
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                    .withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDarkMode ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _isChanging ? null : _applyRandomWallpaper,
                              child: Center(
                                child: _isChanging
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      )
                                    : Icon(Icons.shuffle_rounded,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      );
    });
  }

  Widget _buildCupertinoTabBar(Navigation provider, bool isDarkMode) {
    return CNTabBar(
      currentIndex: provider.index,
      onTap: (index) => provider.setIndex = index,
      tint: bgDarkAccentColor,
      items: const [
        CNTabBarItem(icon: CNSymbol('safari.fill', size: 20)),
        CNTabBarItem(icon: CNSymbol('livephoto', size: 20)),
        CNTabBarItem(icon: CNSymbol('square.grid.2x2.fill', size: 20)),
        CNTabBarItem(icon: CNSymbol('list.bullet', size: 20)),
        CNTabBarItem(icon: CNSymbol('heart.fill', size: 20)),
      ],
    );
  }

  Widget _buildCustomTabBar(Navigation provider, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 61,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sliding Indicator Pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  alignment: Alignment(
                    -1.0 + (provider.index * (2.0 / 4.0)),
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.2,
                    child: Container(
                      height: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF121212) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          width: 1,
                        ),
                        boxShadow: isDarkMode
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
                // Navigation Items
                Row(
                  children: [
                    _buildNavItem(0, 'Explore', provider, isDarkMode),
                    _buildNavItem(1, 'Live', provider, isDarkMode),
                    _buildNavItem(2, 'Collections', provider, isDarkMode),
                    _buildNavItem(3, 'Categories', provider, isDarkMode),
                    _buildNavItem(4, 'Favorites', provider, isDarkMode),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, String iconName, Navigation provider, bool isDarkMode) {
    bool isSelected = provider.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setIndex = index,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/$iconName.svg',
            height: 18.5,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4)),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Consumer2<WallRio, SubscriptionProvider>(
      builder: (context, wallRio, subProvider, _) {
        if (subProvider.subscriptionDaysLeft.isNotEmpty) {
          return const SizedBox.shrink();
        }

        SubscriptionPlan? plan;
        for (final p in wallRio.subscriptionPlans) {
          if (p.id == SubscriptionProvider.lifetimeProductId) {
            plan = p;
            break;
          }
        }
        ProductDetails? product;
        for (final p in subProvider.products) {
          if (p.id == SubscriptionProvider.lifetimeProductId) {
            product = p;
            break;
          }
        }

        int discount = 0;
        if (plan != null && product != null && plan.actualPrice > 0) {
          discount =
              ((plan.actualPrice - product.rawPrice) / plan.actualPrice * 100)
                  .round()
                  .abs();
        }

        if (discount == 0) return const SizedBox.shrink();

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OnboardingScreen4(
                  onComplete: () => Navigator.pop(context),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$discount% off on Lifetime',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _dismissPromoBanner,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.5), size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
