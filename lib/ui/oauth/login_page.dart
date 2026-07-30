import 'dart:io';
import 'package:flutter/material.dart';

import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
                alignment: Alignment.topCenter,
                child: Image.asset("assets/login_bg.png")),
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor,
                    Colors.transparent
                  ])),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: EdgeInsets.only(bottom: Platform.isIOS ? 20 : 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Welcome to",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      GradientText(
                        "WallRio",
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge!
                            .copyWith(fontSize: 35),
                        colors: gradientColorMap[GradientAccentType.defaultType]!,
                      ),
                      Text("Team Shadow",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Consumer<AuthProvider>(
                        builder: (context, provider, _) {
                          void onSuccess() {
                            if (!context.mounted) return;
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const NavigationPage()),
                              );
                            }
                          }

                          Widget buildButtons() {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SocialIconButton(
                                      onTap: provider.isLoading
                                          ? null
                                          : () async {
                                              final ok = await provider.signIn();
                                              if (ok) onSuccess();
                                            },
                                      icon: Image.asset("assets/google_logo.png", height: 26),
                                      tooltip: "Sign In with Google",
                                    ),
                                    if (Platform.isIOS) ...[
                                      const SizedBox(width: 20),
                                      SocialIconButton(
                                        onTap: provider.isLoading
                                            ? null
                                            : () async {
                                                final ok = await provider.signInWithApple();
                                                if (ok) onSuccess();
                                              },
                                        icon: const Icon(Icons.apple, color: Colors.black, size: 30),
                                        tooltip: "Sign In with Apple",
                                      ),
                                    ],
                                  ],
                                ),
                                if (Platform.isIOS) ...[
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      } else {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const NavigationPage()),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Continue as Guest",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }

                          return provider.isLoading
                              ? ShimmerWidget.withWidget(buildButtons(), context)
                              : buildButtons();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
