import 'dart:io';
import 'package:flutter/material.dart';

import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
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
            Column(
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
                Container(
                  margin: EdgeInsets.only(bottom: Platform.isIOS ? 40 : 60),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<AuthProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return ShimmerWidget.withWidget(
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGoogleSignInBtn(provider),
                              if (Platform.isIOS) ...[
                                const SizedBox(height: 12),
                                _buildAppleSignInBtn(provider),
                              ],
                            ],
                          ),
                          context,
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGoogleSignInBtn(provider),
                          if (Platform.isIOS) ...[
                            const SizedBox(height: 12),
                            _buildAppleSignInBtn(provider),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PrimaryBtnWidget _buildGoogleSignInBtn(AuthProvider provider) {
    return PrimaryBtnWidget(
      btnText: Platform.isIOS ? "SIGN IN WITH GOOGLE" : "SIGN IN",
      onTap: provider.signIn,
      icon: Image.asset("assets/google_logo.png"),
    );
  }

  PrimaryBtnWidget _buildAppleSignInBtn(AuthProvider provider) {
    return PrimaryBtnWidget(
      btnText: "SIGN IN WITH APPLE",
      onTap: provider.signInWithApple,
      icon: const Icon(Icons.apple, size: 24),
    );
  }
}
