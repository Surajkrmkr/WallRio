import 'package:flutter/material.dart';
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
        MaterialPageRoute(builder: (context) => const SettingsPage()));
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
        child: Padding(
      padding:
          const EdgeInsets.only(left: 20.0, right: 20, top: 20, bottom: 40),
      child: Wrap(
        runSpacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Consumer<AuthProvider>(
              builder: (context, provider, _) {
                final String name = provider.isLoggedIn ? provider.displayName : "Guest User";
                final String photoUrl = provider.photoUrl;
                return Row(children: [
                  PremiumAvatar(
                    imageUrl: photoUrl,
                    radius: 30,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Consumer<SubscriptionProvider>(
                        builder: (context, provider, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium),
                              ),
                              const SizedBox(width: 8),
                              const PremiumBadgeWidget(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "WallRio ${provider.subscriptionDaysLeft.isNotEmpty ? "Plus" : ""} Member",
                              style: Theme.of(context).textTheme.titleSmall)
                        ],
                      );
                    }),
                  )
                ]);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 25.0),
            child: StreakCalendarWidget(),
          ),
          PrimaryBtnWidget(
            btnText: 'SETTINGS',
            onTap: () => _settings(context),
          ),
          PrimaryBtnWidget(btnText: 'MORE APPS', onTap: moreApps),
          Consumer<AuthProvider>(builder: (context, provider, _) {
            return provider.isLoading
                ? ShimmerWidget.withWidget(_buildAuthBtn(context, provider), context)
                : _buildAuthBtn(context, provider);
          }),
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
      return PrimaryBtnWidget(
        btnText: 'SIGN IN',
        onTap: () {
          final navigator = Navigator.of(context, rootNavigator: true);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
      );
    }
    return PrimaryBtnWidget(
        btnText: 'LOG OUT',
        onTap: () async {
          final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          
          subProvider.clearData();
          await authProvider.signOut();
          
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        });
  }
}
