import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/oauth/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class UserBottomSheet extends StatelessWidget {
  const UserBottomSheet({super.key});

  void moreApps() =>
      launch("https://play.google.com/store/apps/dev?id=5668598285863173548");

  void _settings(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void launch(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7);

    Widget sheetContent = glassSheetBackground(
      Container(
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Consumer<AuthProvider>(
                  builder: (context, provider, _) {
                    final String name = provider.isLoggedIn
                        ? provider.displayName
                        : "Guest User";
                    final String photoUrl = provider.photoUrl;
                    return Row(
                      children: [
                        PremiumAvatar(imageUrl: photoUrl, radius: 30),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Consumer<SubscriptionProvider>(
                            builder: (context, provider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.displayMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const PremiumBadgeWidget(),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "WallRio ${UserProfile.plusMember || provider.subscriptionDaysLeft.isNotEmpty ? "PRO " : ""}Member",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const StreakCalendarWidget(),
              _SheetRow(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => _settings(context),
              ),
              _SheetRow(
                icon: Icons.apps_rounded,
                label: 'More apps',
                onTap: moreApps,
              ),
              Consumer<AuthProvider>(
                builder: (context, provider, _) {
                  return provider.isLoading
                      ? ShimmerWidget.withWidget(
                          _buildAuthBtn(context, provider),
                          context,
                        )
                      : _buildAuthBtn(context, provider);
                },
              ),
            ],
          ),
        ),
      ),
      tint: sheetColor,
    );

    if (ResponsiveHelper.isTablet(context)) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: sheetContent,
        ),
      );
    }

    return sheetContent;
  }

  Widget _buildAuthBtn(BuildContext context, AuthProvider authProvider) {
    if (!authProvider.isLoggedIn) {
      return _SheetRow(
        icon: Icons.login_rounded,
        label: 'Sign in',
        onTap: () {
          final navigator = Navigator.of(context, rootNavigator: true);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
      );
    }
    return _SheetRow(
      icon: Icons.logout_rounded,
      label: 'Log out',
      danger: true,
      onTap: () async {
        final subProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        final favProvider = Provider.of<FavouriteProvider>(
          context,
          listen: false,
        );

        subProvider.clearData();
        favProvider.clearData();
        await authProvider.signOut();

        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = danger ? colors.danger : colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: danger
            ? colors.danger.withValues(alpha: isDark ? 0.09 : 0.06)
            : (isDark ? Colors.white : Colors.black).withValues(
                alpha: isDark ? 0.06 : 0.04,
              ),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: danger ? fg : colors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  if (!danger)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
