import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class PersonalizationHubPage extends StatefulWidget {
  const PersonalizationHubPage({super.key});

  @override
  State<PersonalizationHubPage> createState() => _PersonalizationHubPageState();
}

class _PersonalizationHubPageState extends State<PersonalizationHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Check if the user is a Pro member
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final hasSub = subProvider.subscriptionDaysLeft.isNotEmpty;

    // We no longer block access here. Non-pro users can view the hub to see what they are missing!

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: !hasSub
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildSubscribeButton(context),
              ),
            )
          : null,
      body: Consumer<PersonalizationProvider>(
        builder: (context, personalization, _) {
          if (personalization.isLoading ||
              personalization.personalization == null) {
            return const Center(
                child: CircularProgressIndicator(color: bgDarkAccentColor));
          }

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverAppBarWidget(
                  showLogo: false,
                  showSearchBtn: false,
                  centeredTitle: true,
                  showBackBtn: true,
                  text: 'Personalize',
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Membership Card
                      _buildMembershipCard(personalization, isDarkMode),
                      const SizedBox(height: 28),
  
                      // Tab Selector — App Icons switching is Android-only
                      // (no iOS native handler exists for the icon channel yet),
                      // so iOS goes straight to Frames without a tab bar.
                      if (Platform.isAndroid) ...[
                        _buildTabBar(isDarkMode),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: _calculateTabHeight(context, personalization),
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildAppIconsTab(context, personalization,
                                  isDarkMode, hasSub),
                              _buildProfileFramesTab(context, personalization,
                                  isDarkMode, hasSub),
                            ],
                          ),
                        ),
                      ] else
                        _buildProfileFramesTab(
                            context, personalization, isDarkMode, hasSub),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateTabHeight(BuildContext context, PersonalizationProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth - 40; // 20 padding on each side
    
    // Icons: 20 items in 4 columns = 5 rows
    final iconCardWidth = (gridWidth - (3 * 16)) / 4;
    // Aspect ratio 1.0, cardHeight = iconCardWidth
    final iconsHeight = (5 * (iconCardWidth + 16)) + 120;
    
    // Frames: 8 items in 3 columns = 3 rows
    final frameCardWidth = (gridWidth - (2 * 14)) / 3;
    final frameCardHeight = frameCardWidth / 0.72;
    final framesHeight = (3 * (frameCardHeight + 14)) + 120;
    
    final maxHeight = iconsHeight > framesHeight ? iconsHeight : framesHeight;
    return maxHeight;
  }

  // ──────────────────────────────────────────────────────────
  // MEMBERSHIP CARD — Glassmorphic hero card
  // ──────────────────────────────────────────────────────────
  Widget _buildMembershipCard(
      PersonalizationProvider provider, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2ABFAA), Color(0xFF178A76)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ABFAA).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: whiteColor, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'WallRio Pro',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${provider.monthsSubscribed} ${provider.monthsSubscribed == 1 ? 'month' : 'months'} active — Rewards unlock over time',
                    style: TextStyle(
                      color: whiteColor.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.workspace_premium_rounded,
                color: whiteColor, size: 64),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TAB BAR — Pill-style segmented control
  // ──────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: bgDarkAccentColor.withValues(alpha: 0.15),
            border: Border.all(
              color: bgDarkAccentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: bgDarkAccentColor,
          unselectedLabelColor:
              isDarkMode ? Colors.white.withValues(alpha: 0.4) : Colors.grey,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apps_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('App Icons'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Frames'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP ICONS TAB
  // ──────────────────────────────────────────────────────────
  Widget _buildAppIconsTab(BuildContext context,
      PersonalizationProvider provider, bool isDarkMode, bool hasSub) {
    final icons = [
      {
        'key': 'icon_default',
        'name': 'Default',
        'unlock': 0,
        'imageAsset': 'assets/app_icon/icon_default.png'
      },
      {
        'key': 'icon_cosmic_galaxy',
        'name': 'Cosmic Galaxy',
        'unlock': 0,
        'imageAsset': 'assets/app_icon/icon_cosmic_galaxy.png'
      },
      {
        'key': 'icon_aurora',
        'name': 'Aurora',
        'unlock': 0,
        'imageAsset': 'assets/app_icon/icon_aurora.png'
      },
      {
        'key': 'icon_diamond',
        'name': 'Diamond',
        'unlock': 1,
        'imageAsset': 'assets/app_icon/icon_diamond.png'
      },
      {
        'key': 'icon_electric_plasma',
        'name': 'Electric Plasma',
        'unlock': 2,
        'imageAsset': 'assets/app_icon/icon_electric_plasma.png'
      },
      {
        'key': 'icon_emerald_energy',
        'name': 'Emerald Energy',
        'unlock': 3,
        'imageAsset': 'assets/app_icon/icon_emerald_energy.png'
      },
      {
        'key': 'icon_gold_luxury',
        'name': 'Gold Luxury',
        'unlock': 4,
        'imageAsset': 'assets/app_icon/icon_gold_luxury.png'
      },
      {
        'key': 'icon_holographic_crystal',
        'name': 'Holo Crystal',
        'unlock': 5,
        'imageAsset': 'assets/app_icon/icon_holographic_crystal.png'
      },
      {
        'key': 'icon_ice_crystal',
        'name': 'Ice Crystal',
        'unlock': 6,
        'imageAsset': 'assets/app_icon/icon_ice_crystal.png'
      },
      {
        'key': 'icon_jelly_glass',
        'name': 'Jelly Glass',
        'unlock': 7,
        'imageAsset': 'assets/app_icon/icon_jelly_glass.png'
      },
      {
        'key': 'icon_liquid_chrome',
        'name': 'Liquid Chrome',
        'unlock': 8,
        'imageAsset': 'assets/app_icon/icon_liquid_chrome.png'
      },
      {
        'key': 'icon_liquid_glass',
        'name': 'Liquid Glass',
        'unlock': 9,
        'imageAsset': 'assets/app_icon/icon_liquid_glass.png'
      },
      {
        'key': 'icon_marble',
        'name': 'Marble',
        'unlock': 10,
        'imageAsset': 'assets/app_icon/icon_marble.png'
      },
      {
        'key': 'icon_molten_lava',
        'name': 'Molten Lava',
        'unlock': 11,
        'imageAsset': 'assets/app_icon/icon_molten_lava.png'
      },
      {
        'key': 'icon_neon_glow',
        'name': 'Neon Glow',
        'unlock': 12,
        'imageAsset': 'assets/app_icon/icon_neon_glow.png'
      },
      {
        'key': 'icon_obsidian_glass',
        'name': 'Obsidian Glass',
        'unlock': 13,
        'imageAsset': 'assets/app_icon/icon_obsidian_glass.png'
      },
      {
        'key': 'icon_prism_glass',
        'name': 'Prism Glass',
        'unlock': 14,
        'imageAsset': 'assets/app_icon/icon_prism_glass.png'
      },
      {
        'key': 'icon_rose_gold',
        'name': 'Rose Gold',
        'unlock': 15,
        'imageAsset': 'assets/app_icon/icon_rose_gold.png'
      },
      {
        'key': 'icon_ruby_crystal',
        'name': 'Ruby Crystal',
        'unlock': 16,
        'imageAsset': 'assets/app_icon/icon_ruby_crystal.png'
      },
      {
        'key': 'icon_titanium',
        'name': 'Titanium',
        'unlock': 18,
        'imageAsset': 'assets/app_icon/icon_titanium.png'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentlyActive(
            provider.personalization?.activeAppIcon ?? 'icon_default',
            icons,
            isDarkMode,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final iconData = icons[index];
              final isUnlocked =
                  provider.isItemUnlocked(iconData['key'] as String);
              final isActive =
                  provider.personalization?.activeAppIcon == iconData['key'];

              return _buildIconCard(
                context: context,
                name: iconData['name'] as String,
                imageAsset: iconData['imageAsset'] as String,
                isUnlocked: hasSub && isUnlocked,
                isActive: isActive,
                unlockMonth: iconData['unlock'] as int,
                isDarkMode: isDarkMode,
                onTap: () {
                  if (!hasSub) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OnboardingScreen4(
                                onComplete: () => Navigator.pop(context))));
                    return;
                  }
                  if (isUnlocked) {
                    provider.setAppIcon(iconData['key'] as String);
                  } else {
                    ToastWidget.showToast(
                        "Unlocks at ${iconData['unlock']} months");
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // PROFILE FRAMES TAB
  // ──────────────────────────────────────────────────────────
  Widget _buildProfileFramesTab(BuildContext context,
      PersonalizationProvider provider, bool isDarkMode, bool hasSub) {
    final frames = [
      {
        'key': 'frame_none',
        'name': 'No Frame',
        'unlock': 0,
        'icon': Icons.account_circle_rounded
      },
      {
        'key': 'frame_gold_vip',
        'name': 'Gold VIP',
        'unlock': 0,
        'imageAsset': 'assets/frame_gold_vip.png'
      },
      {
        'key': 'frame_neon_v2',
        'name': 'Neon Pulse',
        'unlock': 0,
        'imageAsset': 'assets/frame_neon_v2.png'
      },
      {
        'key': 'frame_aurora',
        'name': 'Aurora',
        'unlock': 0,
        'imageAsset': 'assets/frame_aurora.png'
      },
      {
        'key': 'frame_galaxy',
        'name': 'Galaxy',
        'unlock': 0,
        'imageAsset': 'assets/frame_galaxy.png'
      },
      {
        'key': 'frame_glossy',
        'name': 'Glossy',
        'unlock': 0,
        'imageAsset': 'assets/frame_glossy.png'
      },
      {
        'key': 'frame_metal_fire',
        'name': 'Metal Fire',
        'unlock': 0,
        'imageAsset': 'assets/frame_metal_fire.png'
      },
      {
        'key': 'frame_fifa',
        'name': 'FIFA',
        'unlock': 0,
        'imageAsset': 'assets/frame_fifa.png'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentlyActiveFrame(
            provider.personalization?.activeProfileFrame ?? 'frame_none',
            frames,
            isDarkMode,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: frames.length,
            itemBuilder: (context, index) {
              final frameData = frames[index];
              final isUnlocked =
                  provider.isItemUnlocked(frameData['key'] as String);
              final isActive =
                  provider.personalization?.activeProfileFrame ==
                      frameData['key'];

              return _buildFrameCard(
                context: context,
                name: frameData['name'] as String,
                icon: frameData['icon'] as IconData?,
                imageAsset: frameData['imageAsset'] as String?,
                isUnlocked: hasSub && isUnlocked,
                isActive: isActive,
                unlockMonth: frameData['unlock'] as int,
                isDarkMode: isDarkMode,
                onTap: () {
                  if (!hasSub) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OnboardingScreen4(
                                onComplete: () => Navigator.pop(context))));
                    return;
                  }
                  if (isUnlocked) {
                    provider.setProfileFrame(frameData['key'] as String);
                  } else {
                    ToastWidget.showToast(
                        "Unlocks at ${frameData['unlock']} months");
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CURRENTLY ACTIVE INDICATOR — Shows selected icon/frame
  // ──────────────────────────────────────────────────────────
  Widget _buildCurrentlyActive(
    String activeKey,
    List<Map<String, dynamic>> items,
    bool isDarkMode,
  ) {
    Map<String, dynamic> active;
    try {
      active = items.firstWhere((i) => i['key'] == activeKey);
    } catch (_) {
      active = items.first;
    }
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1C1C1E), const Color(0xFF121214)]
              : [const Color(0xFFF9F9FB), const Color(0xFFE5E5EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C5364), Color(0xFF203A43), Color(0xFF0F2027)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(active['imageAsset'] as String),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ACTIVE APP ICON',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: bgDarkAccentColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE600),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'IN USE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyActiveFrame(
    String activeKey,
    List<Map<String, dynamic>> items,
    bool isDarkMode,
  ) {
    Map<String, dynamic> active;
    try {
      active = items.firstWhere((i) => i['key'] == activeKey);
    } catch (_) {
      active = items.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
            ),
            child: active['imageAsset'] != null
                ? ClipOval(
                    child: Image.asset(active['imageAsset'] as String,
                        fit: BoxFit.cover))
                : Icon(active['icon'] as IconData,
                    size: 28, color: bgDarkAccentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Currently Active',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  active['name'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgDarkAccentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'IN USE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: bgDarkAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ICON CARD — Premium glassmorphic card for app icons
  Widget _buildIconCard({
    required BuildContext context,
    required String name,
    required String imageAsset,
    required bool isUnlocked,
    required bool isActive,
    required int unlockMonth,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFFE600)
                : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            width: isActive ? 3.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFE600).withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isActive ? 17 : 19),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.4,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (isActive)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE600),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(isActive ? 17 : 19),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // FRAME CARD — For profile frames
  // ──────────────────────────────────────────────────────────
  Widget _buildFrameCard({
    required BuildContext context,
    required String name,
    IconData? icon,
    String? imageAsset,
    required bool isUnlocked,
    required bool isActive,
    required int unlockMonth,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive
              ? bgDarkAccentColor.withValues(alpha: 0.15)
              : (isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? bgDarkAccentColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: bgDarkAccentColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
                    gradient: LinearGradient(
                      colors: [
                        bgDarkAccentColor.withValues(alpha: 0),
                        bgDarkAccentColor.withValues(alpha: 0.6),
                        bgDarkAccentColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: isUnlocked ? 1.0 : 0.35,
                      child: imageAsset != null
                          ? Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(imageAsset),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: bgDarkAccentColor
                                              .withValues(alpha: 0.2),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                            )
                          : Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                              child: Icon(
                                icon ?? Icons.account_circle_rounded,
                                size: 36,
                                color: isActive
                                    ? bgDarkAccentColor
                                    : (isDarkMode
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.4)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? (isActive
                                ? bgDarkAccentColor
                                : (isDarkMode
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.black.withValues(alpha: 0.75)))
                            : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(
                        isActive, isUnlocked, unlockMonth, isDarkMode),
                  ],
                ),
              ),
            ),

            if (!isUnlocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 12, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STATUS CHIP — Active / Locked badge
  // ──────────────────────────────────────────────────────────
  Widget _buildStatusChip(
      bool isActive, bool isUnlocked, int unlockMonth, bool isDarkMode) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgDarkAccentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✓ ACTIVE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: bgDarkAccentColor,
          ),
        ),
      );
    } else if (!isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${unlockMonth}M+',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.orange.withValues(alpha: 0.8),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubscribeButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFC00), Color(0xFFFFE600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE600).withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OnboardingScreen4(
                  onComplete: () => Navigator.pop(context),
                ),
              ),
            );
          },
          child: const Center(
            child: Text(
              'GET WALLRIO+ TO UNLOCK ALL ICONS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
