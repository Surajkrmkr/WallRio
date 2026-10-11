import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

/// Opens the App Icon picker as its own bottom sheet — presented the same
/// way every other WallRio personalization surface is (Themes, Widgets):
/// `CNBottomSheet.show`, rounded top, transparent barrier — instead of a
/// full pushed page. Separate from [showFramesSheet] rather than one sheet
/// with an internal tab switcher, since each is already reached from its
/// own distinct card in Settings — a switcher between them added nothing.
void showAppIconsSheet(BuildContext context) {
  _showPersonalizationSheet(context, showFrames: false);
}

/// Opens the Profile Frame picker as its own bottom sheet. See
/// [showAppIconsSheet].
void showFramesSheet(BuildContext context) {
  _showPersonalizationSheet(context, showFrames: true);
}

void _showPersonalizationSheet(BuildContext context,
    {required bool showFrames}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  CNBottomSheet.show(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: Platform.isIOS,
    constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => PersonalizationHubPage(showFrames: showFrames),
  );
}

/// App icon catalog — shared between the App Icons tab and the compact
/// "App Icon" card in the Personalization card grid, so both read the same
/// data instead of two copies drifting apart.
const List<Map<String, dynamic>> kAppIconCatalog = [
  {
    'key': 'icon_default',
    'name': 'Default',
    'unlock': 0,
    'imageAsset': 'assets/app_icon/icon_default.webp'
  },
  {
    'key': 'icon_cosmic_galaxy',
    'name': 'Cosmic Galaxy',
    'unlock': 0,
    'imageAsset': 'assets/app_icon/icon_cosmic_galaxy.webp'
  },
  {
    'key': 'icon_aurora',
    'name': 'Aurora',
    'unlock': 0,
    'imageAsset': 'assets/app_icon/icon_aurora.webp'
  },
  {
    'key': 'icon_diamond',
    'name': 'Diamond',
    'unlock': 1,
    'imageAsset': 'assets/app_icon/icon_diamond.webp'
  },
  {
    'key': 'icon_electric_plasma',
    'name': 'Electric Plasma',
    'unlock': 2,
    'imageAsset': 'assets/app_icon/icon_electric_plasma.webp'
  },
  {
    'key': 'icon_emerald_energy',
    'name': 'Emerald Energy',
    'unlock': 3,
    'imageAsset': 'assets/app_icon/icon_emerald_energy.webp'
  },
  {
    'key': 'icon_gold_luxury',
    'name': 'Gold Luxury',
    'unlock': 4,
    'imageAsset': 'assets/app_icon/icon_gold_luxury.webp'
  },
  {
    'key': 'icon_holographic_crystal',
    'name': 'Holo Crystal',
    'unlock': 5,
    'imageAsset': 'assets/app_icon/icon_holographic_crystal.webp'
  },
  {
    'key': 'icon_ice_crystal',
    'name': 'Ice Crystal',
    'unlock': 6,
    'imageAsset': 'assets/app_icon/icon_ice_crystal.webp'
  },
  {
    'key': 'icon_jelly_glass',
    'name': 'Jelly Glass',
    'unlock': 7,
    'imageAsset': 'assets/app_icon/icon_jelly_glass.webp'
  },
  {
    'key': 'icon_liquid_chrome',
    'name': 'Liquid Chrome',
    'unlock': 8,
    'imageAsset': 'assets/app_icon/icon_liquid_chrome.webp'
  },
  {
    'key': 'icon_liquid_glass',
    'name': 'Liquid Glass',
    'unlock': 9,
    'imageAsset': 'assets/app_icon/icon_liquid_glass.webp'
  },
  {
    'key': 'icon_marble',
    'name': 'Marble',
    'unlock': 10,
    'imageAsset': 'assets/app_icon/icon_marble.webp'
  },
  {
    'key': 'icon_molten_lava',
    'name': 'Molten Lava',
    'unlock': 11,
    'imageAsset': 'assets/app_icon/icon_molten_lava.webp'
  },
  {
    'key': 'icon_neon_glow',
    'name': 'Neon Glow',
    'unlock': 12,
    'imageAsset': 'assets/app_icon/icon_neon_glow.webp'
  },
  {
    'key': 'icon_obsidian_glass',
    'name': 'Obsidian Glass',
    'unlock': 13,
    'imageAsset': 'assets/app_icon/icon_obsidian_glass.webp'
  },
  {
    'key': 'icon_prism_glass',
    'name': 'Prism Glass',
    'unlock': 14,
    'imageAsset': 'assets/app_icon/icon_prism_glass.webp'
  },
  {
    'key': 'icon_rose_gold',
    'name': 'Rose Gold',
    'unlock': 15,
    'imageAsset': 'assets/app_icon/icon_rose_gold.webp'
  },
  {
    'key': 'icon_ruby_crystal',
    'name': 'Ruby Crystal',
    'unlock': 16,
    'imageAsset': 'assets/app_icon/icon_ruby_crystal.webp'
  },
  {
    'key': 'icon_titanium',
    'name': 'Titanium',
    'unlock': 18,
    'imageAsset': 'assets/app_icon/icon_titanium.webp'
  },
];

/// Profile frame catalog — shared between the Frames tab and the compact
/// "Profile Frame" card.
const List<Map<String, dynamic>> kProfileFrameCatalog = [
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
    'imageAsset': 'assets/frame_gold_vip.webp'
  },
  {
    'key': 'frame_neon_v2',
    'name': 'Neon Pulse',
    'unlock': 0,
    'imageAsset': 'assets/frame_neon_v2.webp'
  },
  {
    'key': 'frame_aurora',
    'name': 'Aurora',
    'unlock': 0,
    'imageAsset': 'assets/frame_aurora.webp'
  },
  {
    'key': 'frame_galaxy',
    'name': 'Galaxy',
    'unlock': 0,
    'imageAsset': 'assets/frame_galaxy.webp'
  },
  {
    'key': 'frame_glossy',
    'name': 'Glossy',
    'unlock': 0,
    'imageAsset': 'assets/frame_glossy.webp'
  },
  {
    'key': 'frame_metal_fire',
    'name': 'Metal Fire',
    'unlock': 0,
    'imageAsset': 'assets/frame_metal_fire.webp'
  },
  {
    'key': 'frame_fifa',
    'name': 'FIFA',
    'unlock': 0,
    'imageAsset': 'assets/frame_fifa.webp'
  },
];

class PersonalizationHubPage extends StatelessWidget {
  /// Which single section this sheet shows — App Icons (false) or Profile
  /// Frames (true). Each is reached from its own distinct card in Settings,
  /// so this is a plain either/or rather than an internal tab switcher.
  final bool showFrames;

  const PersonalizationHubPage({super.key, this.showFrames = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;

    // Check if the user is a Pro member
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final hasSub = subProvider.subscriptionDaysLeft.isNotEmpty;

    // We no longer block access here. Non-pro users can view the hub to see what they are missing!

    // App Icon switching is Android-only (no iOS native handler exists for
    // the icon channel yet); the Settings card already disables itself on
    // iOS, but fall back to Frames defensively if this sheet is somehow
    // still reached for icons there.
    final effectiveShowFrames = showFrames || !Platform.isAndroid;

    return glassSheetBackground(
      Container(
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
                child: Row(
                  children: [
                    Text(
                      effectiveShowFrames ? 'Frames' : 'App Icons',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded,
                          color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer<PersonalizationProvider>(
                  builder: (context, personalization, _) {
                    if (personalization.isLoading ||
                        personalization.personalization == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: context.appColors.accent)),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          effectiveShowFrames
                              ? _buildProfileFramesTab(
                                  context, personalization, isDarkMode, hasSub)
                              : _buildAppIconsTab(
                                  context, personalization, isDarkMode, hasSub),
                          if (!hasSub) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildSubscribeButton(context),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      tint: colors.card,
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP ICONS TAB
  // ──────────────────────────────────────────────────────────
  Widget _buildAppIconsTab(BuildContext context,
      PersonalizationProvider provider, bool isDarkMode, bool hasSub) {
    final icons = kAppIconCatalog;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentlyActive(
            context,
            provider.personalization?.activeAppIcon ?? 'icon_default',
            icons,
            isDarkMode,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isTablet(context) ? 6 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final iconData = icons[index];
              final isDefault = iconData['key'] == 'icon_default';
              final isUnlocked = isDefault ||
                  provider.isItemUnlocked(iconData['key'] as String);
              final isActive =
                  (provider.personalization?.activeAppIcon ?? 'icon_default') ==
                      iconData['key'];

              return _buildIconCard(
                context: context,
                name: iconData['name'] as String,
                imageAsset: iconData['imageAsset'] as String,
                isUnlocked: isDefault || (hasSub && isUnlocked),
                isActive: isActive,
                unlockMonth: iconData['unlock'] as int,
                isDarkMode: isDarkMode,
                onTap: () {
                  if (!hasSub && !isDefault) {
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
    final frames = kProfileFrameCatalog;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentlyActiveFrame(
            context,
            provider.personalization?.activeProfileFrame ?? 'frame_none',
            frames,
            isDarkMode,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isTablet(context) ? 5 : 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: frames.length,
            itemBuilder: (context, index) {
              final frameData = frames[index];
              final isDefault = frameData['key'] == 'frame_none';
              final isUnlocked = isDefault ||
                  provider.isItemUnlocked(frameData['key'] as String);
              final isActive =
                  (provider.personalization?.activeProfileFrame ??
                          'frame_none') ==
                      frameData['key'];

              return _buildFrameCard(
                context: context,
                name: frameData['name'] as String,
                icon: frameData['icon'] as IconData?,
                imageAsset: frameData['imageAsset'] as String?,
                isUnlocked: isDefault || (hasSub && isUnlocked),
                isActive: isActive,
                unlockMonth: frameData['unlock'] as int,
                isDarkMode: isDarkMode,
                onTap: () {
                  if (!hasSub && !isDefault) {
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
    BuildContext context,
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
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
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
                colors: [
                  Color(0xFF2C5364),
                  Color(0xFF203A43),
                  Color(0xFF0F2027)
                ],
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
                    color: context.appColors.accent,
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
              color: context.appColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'IN USE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyActiveFrame(
    BuildContext context,
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
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: active['imageAsset'] != null
                ? ClipOval(
                    child: Image.asset(active['imageAsset'] as String,
                        fit: BoxFit.cover))
                : Icon(active['icon'] as IconData,
                    size: 28, color: context.appColors.accent),
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
              color: context.appColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'IN USE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: context.appColors.accent,
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
                ? context.appColors.accent
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isActive ? 3.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.appColors.accent.withValues(alpha: 0.25),
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
                  decoration: BoxDecoration(
                    color: context.appColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
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
              ? context.appColors.accent.withValues(alpha: 0.15)
              : (isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? context.appColors.accent.withValues(alpha: 0.5)
                : Colors.transparent,
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.appColors.accent.withValues(alpha: 0.08),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    gradient: LinearGradient(
                      colors: [
                        context.appColors.accent.withValues(alpha: 0),
                        context.appColors.accent.withValues(alpha: 0.6),
                        context.appColors.accent.withValues(alpha: 0),
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
                                          color: context.appColors.accent
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
                                    ? context.appColors.accent
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
                                ? context.appColors.accent
                                : (isDarkMode
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.black.withValues(alpha: 0.75)))
                            : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(
                        context, isActive, isUnlocked, unlockMonth, isDarkMode),
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
  Widget _buildStatusChip(BuildContext context, bool isActive, bool isUnlocked,
      int unlockMonth, bool isDarkMode) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.appColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '✓ ACTIVE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: context.appColors.accent,
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
          unlockMonth > 0 ? '${unlockMonth}M+' : 'PRO',
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
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingScreen4(
                onComplete: () => Navigator.pop(context),
              ),
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.workspace_premium_rounded, size: 20),
        label: const Text(
          'Unlock all with WallRio Pro',
          style: TextStyle(
            fontFamily: appFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
