import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class UserBottomSheet extends StatelessWidget {
  const UserBottomSheet({super.key});

  void moreApps() =>
      launch("https://play.google.com/store/apps/dev?id=5668598285863173548");

  void _settings(context) {
    Navigator.of(context).pop();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  void launch(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 20.0, right: 20, top: 20, bottom: 40),
      child: Wrap(
        runSpacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Consumer<AuthProvider>(
              builder: (context, provider, _) {
                final String name = provider.user.displayName!;
                return Row(children: [
                  provider.user.photoURL!.isEmpty
                      ? const Icon(Icons.account_circle_rounded)
                      : CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              NetworkImage(provider.user.photoURL!),
                          backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Consumer<SubscriptionProvider>(
                        builder: (context, provider, _) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                      "WallRio ${provider.subscriptionDaysLeft.isNotEmpty ? "Plus" : ""} Member",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall)
                                ]),
                          ),
                          Visibility(
                            visible: provider.subscriptionDaysLeft.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Image.asset(
                                "assets/plus_icon.png",
                                height: 18,
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                  )
                ]);
              },
            ),
          ),
          PrimaryBtnWidget(
            btnText: 'SETTINGS',
            onTap: () => _settings(context),
          ),
          PrimaryBtnWidget(btnText: 'MORE APPS', onTap: moreApps),
          Consumer<AuthProvider>(builder: (context, provider, _) {
            return provider.isLoading
                ? ShimmerWidget.withWidget(_buildSignOutBtn(context), context)
                : _buildSignOutBtn(context);
          }),
        ],
      ),
    );
  }

  PrimaryBtnWidget _buildSignOutBtn(BuildContext context) {
    return PrimaryBtnWidget(
        btnText: 'LOG OUT',
        onTap: () {
          Navigator.pop(context);
          Provider.of<SubscriptionProvider>(context, listen: false).clearData();
          Provider.of<AuthProvider>(context, listen: false).signOut();
        });
  }
}
