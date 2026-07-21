import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/auto_wallpaper_settings_page.dart';
import 'package:wallrio/ui/views/personalization_hub_page.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSub = Provider.of<SubscriptionProvider>(context).subscriptionDaysLeft.isNotEmpty;

    final sections = [
      _plusBanner(context),
      _sectionCard(
        context,
        label: 'Appearance',
        children: [
          _darkModeTile(context),
          _tile(context,
              icon: Icons.palette_rounded,
              title: 'Personalization Hub',
              subtitle: 'Customize your profile (Pro)',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PersonalizationHubPage()))),
          if (!hasSub)
            _tile(context,
                icon: Icons.diamond_rounded,
                title: 'Rewards Hub',
                subtitle: 'Earn diamonds & track progress',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RewardsHubPage()))),
        ],
      ),
      _sectionCard(
        context,
        label: 'Advanced',
        children: [
          if (Platform.isAndroid)
            _tile(context,
                icon: Icons.auto_mode_rounded,
                title: 'Auto Wallpaper',
                subtitle: 'Automatically change your wallpaper',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AutoWallpaperSettingsPage()))),
          _tile(context,
              icon: Icons.cleaning_services_rounded,
              title: 'Clear Cache',
              subtitle: 'Remove locally cached data',
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ClearCacheWidget())),
        ],
      ),
      _sectionCard(
        context,
        label: 'Social',
        children: [
          _tile(context,
              icon: Icons.star_rounded,
              title: 'Rate WallRio',
              subtitle: 'Rate us on Google Play',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => RateUsDialog(
                    onRateNow: () {
                      Navigator.pop(dialogContext);
                      if (!hasSub) {
                        Provider.of<ProgressionProvider>(context, listen: false)
                            .trackAction(ActionType.rateApp);
                      }
                      launch('https://play.google.com/store/apps/dev?id=5668598285863173548');
                    },
                    onDismiss: () => Navigator.pop(dialogContext),
                  ),
                );
              }),
          _tile(context,
              icon: Icons.share_rounded,
              title: 'Share WallRio',
              subtitle: 'Share app with friends',
              onTap: () {
                if (!hasSub) {
                  Provider.of<ProgressionProvider>(context, listen: false)
                      .trackAction(ActionType.shareApp);
                }
                // ignore: deprecated_member_use
                Share.share('Check out WallRio for amazing 4K & Live wallpapers! https://play.google.com/store/apps/dev?id=5668598285863173548');
              }),
          _tile(context,
              icon: Icons.apps_rounded,
              title: 'More Apps',
              subtitle: 'Check out our other apps',
              onTap: () => launch('https://play.google.com/store/apps/dev?id=5668598285863173548')),
          _tile(context,
              icon: Icons.photo_camera_rounded,
              title: 'Instagram',
              subtitle: 'Follow us @studio.teamshadow',
              onTap: () =>
                  launch('https://instagram.com/studio.teamshadow')),
          _tile(context,
              icon: Icons.alternate_email_rounded,
              title: 'Twitter/X',
              subtitle: 'Follow us @4XDesigns',
              onTap: () => launch('https://x.com/4XDesigns')),
          _tile(context,
              icon: Icons.send_rounded,
              title: 'Telegram',
              subtitle: 'Join our community',
              onTap: () => launch('https://t.me/TeamShadow_Studio')),
        ],
      ),
      _sectionCard(
        context,
        label: 'Support & Legal',
        children: [
          _tile(context,
              icon: Icons.help_outline_rounded,
              title: 'Support',
              subtitle: 'Get help and support',
              onTap: () =>
                  launch('https://piyushkpv.github.io/wallrio-support/')),
          _tile(context,
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () => launch(
                  'https://doc-hosting.flycricket.io/wallrio-privacy-policy/74e93607-af2a-42e8-b23c-ae459cee92b3/privacy')),
        ],
      ),
      _appInfoSection(context),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBarWidget(
                showLogo: false,
                showSearchBtn: false,
                centeredTitle: true,
                showBackBtn: true,
                text: 'Settings'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: sections.length,
                  (context, i) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 350 + i * 60),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: sections[i],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Plus Banner ──────────────────────────────────────────────

  Widget _plusBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          final bool hasSub = provider.subscriptionDaysLeft.isNotEmpty;
          if (hasSub) {
            return Container(
              padding: const EdgeInsets.all(22),
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
              child: _subscribedContent(context, provider),
            );
          }
          return const _AnimatedSubscriptionBanner();
        },
      ),
    );
  }

  Widget _subscribedContent(
      BuildContext context, SubscriptionProvider provider) {
    return Row(
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
                "You're a Pro Member — full access unlocked",
                style: TextStyle(
                  color: whiteColor.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: whiteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${provider.subscriptionDaysLeft} days remaining',
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.workspace_premium_rounded,
            color: whiteColor, size: 64),
      ],
    );
  }

  // ─── Section Card ─────────────────────────────────────────────

  Widget _sectionCard(BuildContext context,
      {required String label, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, label),
          const SizedBox(height: 10),
          Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? bgDark2Color
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Theme.of(context)
                          .primaryColorLight
                          .withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: bgDarkAccentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  // ─── Tiles ────────────────────────────────────────────────────

  Widget _darkModeTile(BuildContext context) {
    return Consumer<DarkThemeProvider>(
      builder: (context, provider, _) {
        if (Platform.isIOS) {
          return ListTile(
            leading: _tileIcon(Icons.dark_mode_rounded),
            title: const Text('Dark Mode'),
            subtitle: Text(
              'Switch to dark theme',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            trailing: CNSwitch(
              value: provider.darkTheme,
              onChanged: (val) => provider.darkTheme = val,
              color: bgDarkAccentColor,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          );
        }
        return SwitchListTile(
          value: provider.darkTheme,
          onChanged: (val) => provider.darkTheme = val,
          secondary: _tileIcon(Icons.dark_mode_rounded),
          title: const Text('Dark Mode'),
          subtitle: Text(
            'Switch to dark theme',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        );
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Function() onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _tileIcon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle:
          Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color:
            Theme.of(context).primaryColorLight.withValues(alpha: 0.35),
      ),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _tileIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgDarkAccentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: bgDarkAccentColor, size: 20),
    );
  }

  // ─── App Info ─────────────────────────────────────────────────

  Widget _appInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Consumer<WallRio>(builder: (context, provider, _) {
            return provider.isLoading
                ? const ShimmerWidget(height: 12, width: 60)
                : Text(
                    'Version ${provider.currentVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
          }),
          const SizedBox(height: 6),
          Text(
            'Made with ❤️ in India',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  static void launch(String url) => launchUrl(Uri.parse(url),
      mode: LaunchMode.externalApplication);
}

class _AnimatedSubscriptionBanner extends StatefulWidget {
  const _AnimatedSubscriptionBanner();

  @override
  State<_AnimatedSubscriptionBanner> createState() =>
      __AnimatedSubscriptionBannerState();
}

class __AnimatedSubscriptionBannerState
    extends State<_AnimatedSubscriptionBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  List<Walls> _bannerWalls = [];
  bool _isLocalLoaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadOrSaveLocalWalls(List<Walls> allWalls) async {
    if (_isLocalLoaded || allWalls.isEmpty) return;
    _isLocalLoaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedIds = prefs.getStringList('settings_banner_wallpaper_ids');

      List<Walls> matched = [];
      if (savedIds != null && savedIds.isNotEmpty) {
        for (final id in savedIds) {
          for (final wall in allWalls) {
            if (wall.id.toString() == id) {
              matched.add(wall);
              break;
            }
          }
        }
      }

      if (matched.length >= 5) {
        if (mounted) setState(() => _bannerWalls = matched);
        return;
      }

      final proWalls = allWalls.where((w) => w.isPremium).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      final sourceList = proWalls.isNotEmpty ? proWalls : allWalls;
      final selected = sourceList.take(10).toList();

      final idsToSave = selected.map((w) => w.id.toString()).toList();
      await prefs.setStringList('settings_banner_wallpaper_ids', idsToSave);

      if (mounted) setState(() => _bannerWalls = selected);
    } catch (e) {
      logger.e('Error loading settings banner walls: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(
      builder: (context, wallRio, _) {
        if (!_isLocalLoaded && wallRio.originalWallList.isNotEmpty) {
          _loadOrSaveLocalWalls(wallRio.originalWallList);
        }

        final wallsToUse = _bannerWalls.isNotEmpty
            ? _bannerWalls
            : wallRio.originalWallList.take(10).toList();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingScreen4(
                onComplete: () => Navigator.popUntil(
                    context, (route) => route.isFirst),
              ),
            ),
          ),
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // 1. Animated background wallpapers (scrolling left-to-right & right-to-left)
                  Positioned.fill(
                    child: wallsToUse.isEmpty
                        ? Container(color: bgDark2Color)
                        : AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              const cardWidth = 110.0;
                              final totalSingleSetWidth =
                                  wallsToUse.length * cardWidth;

                              final maxScroll = (totalSingleSetWidth * 2) - MediaQuery.of(context).size.width + 40;
                              final dx = -(_animController.value * maxScroll).clamp(0.0, totalSingleSetWidth * 1.5);

                              final doubleWalls = [
                                ...wallsToUse,
                                ...wallsToUse,
                              ];

                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: OverflowBox(
                                  minWidth: 0,
                                  maxWidth: double.infinity,
                                  minHeight: 190,
                                  maxHeight: 190,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: doubleWalls.map((wall) {
                                      return SizedBox(
                                        width: cardWidth,
                                        height: 190,
                                        child: CachedNetworkImage(
                                          imageUrl: wall.thumbnail.isNotEmpty
                                              ? wall.thumbnail
                                              : wall.url,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.high,
                                          placeholder: (_, __) =>
                                              Container(color: bgDark2Color),
                                          errorWidget: (_, __, ___) =>
                                              Container(color: bgDark2Color),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // 2. Dark translucent overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Foreground overlay content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Unlock Pro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Get unlimited access to all wallpapers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'See Plans',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
