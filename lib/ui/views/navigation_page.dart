import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/pages.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/macos/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer _timer = Timer(Duration.zero, () {});
  bool _showPromoBanner = false;
  static const String _promoDismissKey = 'promo_banner_dismissed_date';
  final Set<int> _visitedTabs = {0};
  int _shownTab = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isMacOS) {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        final wallRio = Provider.of<WallRio>(context, listen: false);
        if (wallRio.desktopWallList.isEmpty) {
          wallRio.fetchDesktopWallpapers();
        }
        if (UserProfile.plusMember) {
          Provider.of<FavouriteProvider>(context, listen: false)
              .getFavouritesFromFirebase();
        }
      });
      super.initState();
      return;
    }

    TrackingService.requestIfNeeded();
    Future.delayed(Duration.zero, () {
      _checkUserIsDisable();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .checkPastPurchases();
    }
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
    final progProvider =
        Provider.of<ProgressionProvider>(context, listen: false);
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

          if (!Platform.isIOS && !UserProfile.plusMember) {
            progProvider.trackAction(ActionType.rateApp);
          }
        },
        onDismiss: () async {
          Navigator.pop(dialogContext);
          final prefs = await SharedPreferences.getInstance();
          final count = prefs.getInt('rate_dismiss_count') ?? 0;
          if (count == 0) {
            await prefs.setInt('rate_dismiss_count', 1);
            await prefs.setInt('rate_last_dismiss_time',
                DateTime.now().millisecondsSinceEpoch);
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

  // Visited tabs stay mounted (offstage) so their scroll position and state
  // are preserved; only the active tab ticks and receives input.
  Widget _buildTabs(int activeIndex) {
    if (activeIndex != _shownTab) {
      _shownTab = activeIndex;
      _visitedTabs.add(activeIndex);
    }
    return IndexedStack(
      index: activeIndex,
      sizing: StackFit.expand,
      children: [
        for (int i = 0; i < pages.length; i++)
          _visitedTabs.contains(i)
              ? TickerMode(
                  enabled: i == activeIndex,
                  // Hidden tabs must not expose heroes that clash with the active tab's.
                  child: HeroMode(
                    enabled: i == activeIndex,
                    child: pages[i],
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );
  }

  Future<void> _checkUserIsDisable([Timer? timer]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled' || e.code == 'user-not-found') {
        logger.w('User account disabled or deleted: ${e.code}');
        await FirebaseAuth.instance.signOut();
      } else if (e.code == 'network-request-failed') {
        logger.w('Network request failed while reloading user: ${e.message}');
      } else {
        logger.w(
            'FirebaseAuthException reloading user: ${e.code} - ${e.message}');
      }
    } catch (error, stackTrace) {
      logger.e('Error reloading user: $error',
          error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return const MacOSDesktopScaffold();
    }

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
                // Hide the bar while scrolling down, bring it back on scroll up.
                final delta = notification.scrollDelta ?? 0;
                if (notification.metrics.axis == Axis.vertical &&
                    delta.abs() > 6) {
                  provider.setVisible =
                      delta < 0 || notification.metrics.pixels < 120;
                }
              }
              return false;
            },
            child: Stack(
              children: [
                _buildTabs(provider.index),
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
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStickyBanner(provider),
              RepaintBoundary(
                child: Platform.isIOS
                    ? _buildCupertinoTabBar(provider, isDarkMode)
                    : AnimatedSlide(
                        offset: provider.visible
                            ? Offset.zero
                            : const Offset(0, 1.6),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _buildCustomTabBar(provider, isDarkMode),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStickyBanner(Navigation provider) {
    if (UserProfile.plusMember) return const SizedBox.shrink();

    return Visibility(
      visible: provider.index != 2,
      maintainState: true,
      child: const StickyBottomBannerWidget(
        key: ValueKey('persistent_sticky_bottom_banner'),
        screenName: 'MainNavigation',
        placementName: 'StickyBottomBanner',
      ),
    );
  }

  Widget _buildCupertinoTabBar(Navigation provider, bool isDarkMode) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final double iconSize = isTablet ? 25.0 : 20.0;
    Widget bar = CNTabBar(
      currentIndex: provider.index,
      onTap: (index) => provider.selectTab(index),
      tint: context.appColors.accent,
      items: [
        CNTabBarItem(icon: CNSymbol('safari.fill', size: iconSize)),
        CNTabBarItem(icon: CNSymbol('livephoto', size: iconSize)),
        CNTabBarItem(icon: CNSymbol('square.grid.2x2.fill', size: iconSize)),
        CNTabBarItem(icon: CNSymbol('list.bullet', size: iconSize)),
        CNTabBarItem(icon: CNSymbol('desktopcomputer', size: iconSize)),
      ],
    );

    if (isTablet) {
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      final double maxW = isLandscape ? 720.0 : 640.0;
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: bar,
        ),
      );
    }
    return bar;
  }

  Widget _buildCustomTabBar(Navigation provider, bool isDarkMode) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final double barHeight = isTablet ? (isLandscape ? 66.0 : 64.0) : 60.0;
    final double maxW = isTablet ? (isLandscape ? 720.0 : 640.0) : 560.0;

    // Tab indices in display order: Explore, Live, Categories, Collections, Desktop.
    const mainTabs = [0, 1, 3, 2, 4];

    Widget barContent = Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16,
          MediaQuery.of(context).padding.bottom + (isTablet ? 18 : 12)),
      child: _glassPill(
        isDarkMode,
        height: barHeight,
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(builder: (context, constraints) {
          final slot = constraints.maxWidth / mainTabs.length;
          final sel = mainTabs.indexOf(provider.index);
          return Stack(
            children: [
              if (sel >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: slot * sel,
                  top: 0,
                  bottom: 0,
                  width: slot,
                  child: DecoratedBox(decoration: _selectedDecoration(context)),
                ),
              Row(
                children: [
                  for (final i in mainTabs)
                    SizedBox(
                      width: slot,
                      child: _buildNavItem(i, provider, isDarkMode),
                    ),
                ],
              ),
            ],
          );
        }),
      ),
    );

    if (isTablet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: barContent,
        ),
      );
    }

    return barContent;
  }

  Widget _glassPill(bool isDarkMode,
      {required double height,
      double? width,
      EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
      required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(44),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(44),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  static const _navItems = <_NavItem>[
    _NavItem(
        'Explore', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    _NavItem('Live', Icons.motion_photos_on_outlined,
        Icons.motion_photos_on_rounded),
    _NavItem('Collections', Icons.photo_library_outlined,
        Icons.photo_library_rounded),
    _NavItem('Categories', Icons.category_outlined, Icons.category_rounded),
    _NavItem('Desktop', Icons.laptop_mac_outlined, Icons.laptop_mac_rounded),
  ];

  // Shared selected-state capsule so both pills look identical.
  BoxDecoration _selectedDecoration(BuildContext context) {
    final colors = context.appColors;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      gradient: LinearGradient(
        colors: [colors.accent, colors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.accent.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, Navigation provider, bool isDarkMode) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final item = _navItems[index];
    final bool isSelected = provider.index == index;
    final accent = context.appColors.accent;
    final Color onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final Color idle = isDarkMode
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.62);
    final Color color = isSelected ? onAccent : idle;
    final controller = provider.tabController(index);

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          provider.selectTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scrolled-down active tab shows an up-arrow: tap again to jump up.
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final scrolled = isSelected &&
                    controller.hasClients &&
                    controller.positions.any((p) => p.pixels > 800);
                return Icon(
                  scrolled
                      ? Icons.arrow_upward_rounded
                      : (isSelected ? item.activeIcon : item.icon),
                  size: isTablet ? 22 : 19,
                  color: color,
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: appFontFamily,
                color: color,
                fontSize: isTablet ? 10.5 : 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
                height: 1.15,
              ),
            ),
          ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 16),
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
