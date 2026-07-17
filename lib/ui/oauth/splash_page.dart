import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/oauth/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _onboardingLoaded = false;

  @override
  void initState() {
    _checkInAppUpdate();
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    firebaseAuth.authStateChanges().listen((event) {
      if (mounted && event != null) {
        Provider.of<SubscriptionProvider>(context, listen: false)
            .checkPastPurchases(email: event.email!);
        Provider.of<ProgressionProvider>(context, listen: false)
            .fetchProgression();
        Provider.of<PersonalizationProvider>(context, listen: false)
            .fetchPersonalization();
      }
    });

    final subProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    Future.delayed(Duration.zero, () async {
      subProvider.checkSupportForIAP();
      if (firebaseAuth.currentUser != null) {
        _checkSubscription(firebaseAuth.currentUser!.email!);
      }
      await onboardingProvider.loadState();
      if (mounted) setState(() => _onboardingLoaded = true);
    });
    FlutterNativeSplash.remove();
    super.initState();
  }

  void _checkSubscription(String email) async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    subscriptionProvider.checkPastPurchases(email: email);
    
    // Also fetch progression data
    Provider.of<ProgressionProvider>(context, listen: false).fetchProgression();
    Provider.of<PersonalizationProvider>(context, listen: false).fetchPersonalization();

    subscriptionProvider.successPurchasedStream.listen((event) {
      if (mounted && event) {
        Navigator.pop(context, true);
      }
    });
  }

  void _checkInAppUpdate() {
    if (kDebugMode || !Platform.isAndroid) return;
    InAppUpdate.checkForUpdate().then((updateInfo) async {
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    }, onError: (error) {
      logger.e(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (!_onboardingLoaded) return _getShimmer(size);

    return Consumer<OnboardingProvider>(
      builder: (context, onboarding, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _getShimmer(size);
            }

            final isLoggedIn = snapshot.hasData && !snapshot.hasError;

            // Route to onboarding if not yet completed
            if (!onboarding.isCompleted) {
              return const OnboardingPage();
            }

            // Onboarding done — normal login/home flow
            if (isLoggedIn) {
              UserProfile.setUserData(snapshot.data!);
              return Consumer<SubscriptionProvider>(
                builder: (context, provider, _) {
                  return provider.isSubscriptionLoading
                      ? _getShimmer(size)
                      : const NavigationPage();
                },
              );
            }

            if (snapshot.hasError) logger.e(snapshot.error);
            return const LoginPage();
          },
        );
      },
    );
  }

  Widget _getShimmer(Size size) => Scaffold(
        body: ShimmerWidget(
          height: size.height,
          width: size.width,
          radius: 0,
        ),
      );
}
