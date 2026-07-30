import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class OnboardingScreen1 extends StatefulWidget {
  final VoidCallback onSignedIn;
  const OnboardingScreen1({super.key, required this.onSignedIn});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  late StreamSubscription<User?> _authSub;
  bool _hasNavigated = false;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted && !_hasNavigated) {
        _hasNavigated = true;
        widget.onSignedIn();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, wallRio, _) {
      final walls = wallRio.originalWallList.isEmpty
          ? <Walls>[]
          : wallRio.originalWallList.take(6).toList();

      return Container(
        color: Colors.black,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                flex: 68,
                child: _buildCarouselSection(context, walls),
              ),
              Expanded(
                flex: 32,
                child: _buildBottomSection(context),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCarouselSection(BuildContext context, List<Walls> walls) {
    if (walls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          child: _PhoneFrame(
            child: ShimmerWidget(
                height: double.infinity, width: double.infinity, radius: 34),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        return CarouselSlider.builder(
          itemCount: walls.length,
          options: CarouselOptions(
            height: constraints.maxHeight,
            viewportFraction: 0.70,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            autoPlayCurve: Curves.easeInOut,
            enlargeCenterPage: true,
            enlargeFactor: 0.36,
            onPageChanged: (index, _) => setState(() => _activeIndex = index),
          ),
          itemBuilder: (context, index, _) {
            final isCenter = index == _activeIndex;
            return _buildCarouselItem(walls[index], isCenter);
          },
        );
      }),
    );
  }

  Widget _buildCarouselItem(Walls wall, bool isCenter) {
    final img = ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(60),
      child: CachedNetworkImage(
        imageUrl: wall.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: bgDark2Color),
        errorWidget: (_, __, ___) => Container(color: bgDark2Color),
      ),
    );

    if (isCenter) {
      return _PhoneFrame(child: img);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: img,
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Wall",
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontSize: 46,
                          color: whiteColor,
                          height: 1.1,
                        ),
                  ),
                  GradientText(
                    "Rio",
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontSize: 46,
                          height: 1.1,
                        ),
                    colors: gradientColorMap[GradientAccentType.defaultType]!,
                  ),
                ],
              ),
              Text(
                "By Team Shadow",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: whiteColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 18),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  Widget buildButtons() {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialIconButton(
                              onTap: authProvider.isLoading
                                  ? null
                                  : () async {
                                      final ok = await authProvider.signIn();
                                      if (ok) widget.onSignedIn();
                                    },
                              icon: Image.asset("assets/google_logo.png", height: 26),
                              tooltip: "Sign In with Google",
                            ),
                            if (Platform.isIOS) ...[
                              const SizedBox(width: 20),
                              SocialIconButton(
                                onTap: authProvider.isLoading
                                    ? null
                                    : () async {
                                        final ok = await authProvider.signInWithApple();
                                        if (ok) widget.onSignedIn();
                                      },
                                icon: const Icon(Icons.apple, color: Colors.black, size: 30),
                                tooltip: "Sign In with Apple",
                              ),
                            ],
                          ],
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: widget.onSignedIn,
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

                  return authProvider.isLoading
                      ? ShimmerWidget.withWidget(buildButtons(), context)
                      : buildButtons();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wallpaper fills the frame area
          Positioned.fill(child: child),
          // frame.png overlay — transparent screen lets wallpaper show through
          Positioned.fill(
            child: Image.asset(
              "assets/frame.png",
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
