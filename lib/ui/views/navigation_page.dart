import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:wallrio/model/export.dart';
import 'package:wallrio/pages.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/services/theme_data.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  Timer _timer = Timer(Duration.zero, () {});

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _checkUserIsDisable(_timer);
      Provider.of<WallRio>(context, listen: false).getListFromAPI(context);
      Provider.of<LiveWallpaperProvider>(context, listen: false)
          .getListFromAPI();
      if (UserProfile.plusMember) {
        Provider.of<FavouriteProvider>(context, listen: false)
            .getFavouritesFromFirebase();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 30), _checkUserIsDisable);

    super.initState();
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
      return Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: PageTransitionSwitcher(
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
        bottomNavigationBar: RepaintBoundary(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            offset: provider.visible ? Offset.zero : const Offset(0, 1.8),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 61,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF1E1E1E).withOpacity(0.85)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                                color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03),
                                  width: 1,
                                ),
                                boxShadow: isDarkMode ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(int index, String iconName, Navigation provider, bool isDarkMode) {
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
                  : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
