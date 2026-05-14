import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
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
  late SubscriptionProvider _subProvider;
  bool _completing = false;

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

      _subProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      _purchaseSuccessSub =
          _subProvider.successPurchasedStream.listen((success) {
        if (success && mounted) _completeOnboarding();
      });

      _subProvider.addListener(_onSubscriptionChanged);
      // Catch the case where subscription was already resolved before this
      // listener was registered (e.g. Firestore returned before first frame).
      _onSubscriptionChanged();
    });
  }

  void _onSubscriptionChanged() {
    if (!_subProvider.isSubscriptionLoading &&
        UserProfile.plusMember &&
        mounted &&
        _pageController.hasClients &&
        (_pageController.page ?? 0).round() >= 3) {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _subProvider.removeListener(_onSubscriptionChanged);
    _pageController.dispose();
    _purchaseSuccessSub.cancel();
    super.dispose();
  }

  void _goToNextPage() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    final nextStep = (_pageController.page ?? 0).round() + 1;
    await provider.saveStep(nextStep);

    if (nextStep == 3 && UserProfile.plusMember) {
      if (mounted) _completeOnboarding();
      return;
    }

    if (mounted) {
      _pageController.animateToPage(
        nextStep.clamp(0, 3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    if (_completing) return;
    _completing = true;
    FirebaseAnalytics.instance.logTutorialComplete();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) UserProfile.setUserData(currentUser);
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await provider.completeOnboarding();
    if (mounted) {
      navigator.pushAndRemoveUntil(
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
