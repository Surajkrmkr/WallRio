import 'dart:io';
import 'package:flutter/material.dart';
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
              icon: Icons.photo_camera_rounded,
              title: 'Instagram',
              subtitle: 'Follow us @studio.teamshadow',
              onTap: () =>
                  launch('https://instagram.com/studio.teamshadow')),
          _tile(context,
              icon: Icons.alternate_email_rounded,
              title: 'Twitter',
              subtitle: 'Follow us @TeamShadowST',
              onTap: () => launch('https://twitter.com/4XDesigns')),
          _tile(context,
              icon: Icons.send_rounded,
              title: 'Telegram',
              subtitle: 'Join our community',
              onTap: () => launch('https://t.me/TeamShadow_Studio')),
        ],
      ),
      _sectionCard(
        context,
        label: 'Legal',
        children: [
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
          return GestureDetector(
            onTap: hasSub
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen4(
                            onComplete: () => Navigator.popUntil(context, (route) => route.isFirst)),
                      ),
                    ),
            child: Container(
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
              child: hasSub
                  ? _subscribedContent(context, provider)
                  : _upgradeContent(context),
            ),
          );
        },
      ),
    );
  }

  Widget _upgradeContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WallRio Pro',
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ad-free  •  Exclusive walls  •  Pro access',
                style: TextStyle(
                  color: whiteColor.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    color: Color(0xFF178A76),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
