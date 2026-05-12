import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/navigation_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late PageController _pageController;
  late StreamSubscription<bool> _purchaseSuccessSub;

  @override
  void initState() {
    super.initState();
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    int startPage = onboardingProvider.currentStep.clamp(0, 3);
    if (FirebaseAuth.instance.currentUser != null && startPage == 0) {
      startPage = 1;
    }
    _pageController = PageController(initialPage: startPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WallRio>(context, listen: false).getListFromAPI(context);

      _purchaseSuccessSub = Provider.of<SubscriptionProvider>(context, listen: false)
          .successPurchasedStream
          .listen((success) {
        if (success && mounted) _completeOnboarding();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _purchaseSuccessSub.cancel();
    super.dispose();
  }

  void _goToNextPage() async {
    final nextStep = (_pageController.page ?? 0).round() + 1;
    await Provider.of<OnboardingProvider>(context, listen: false)
        .saveStep(nextStep);
    if (mounted) {
      _pageController.animateToPage(
        nextStep.clamp(0, 3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await Provider.of<OnboardingProvider>(context, listen: false)
        .completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavigationPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OnboardingScreen1(onSignedIn: _goToNextPage),
          OnboardingScreen2(onNext: _goToNextPage),
          OnboardingScreen3(onNext: _goToNextPage),
          OnboardingScreen4(onComplete: _completeOnboarding),
        ],
      ),
    );
  }
}
