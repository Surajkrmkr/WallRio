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
            .checkPastPurchases(email: event.email);
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
    final progressionProvider =
        Provider.of<ProgressionProvider>(context, listen: false);
    final personalizationProvider =
        Provider.of<PersonalizationProvider>(context, listen: false);

    Future.delayed(Duration.zero, () async {
      await onboardingProvider.loadState();
      if (!onboardingProvider.isCompleted && Platform.isIOS && firebaseAuth.currentUser != null) {
        try {
          await firebaseAuth.signOut();
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }

      subProvider.checkSupportForIAP();
      if (Platform.isIOS) {
        subProvider.checkPastPurchases();
        progressionProvider.fetchProgression();
        personalizationProvider.fetchPersonalization();
      } else if (firebaseAuth.currentUser != null) {
        _checkSubscription(firebaseAuth.currentUser!.email!);
      }
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
    if (kDebugMode) return;
    if (Platform.isAndroid) {
      final plugin = InAppUpdateFlutter();
      plugin.checkUpdateAndroid().then((info) async {
        if (info.updateAvailability == UpdateAvailabilityAndroid.updateAvailable) {
          if (info.isImmediateUpdateAllowed) {
            await plugin.startImmediateUpdateAndroid();
          } else if (info.isFlexibleUpdateAllowed) {
            await plugin.startFlexibleUpdateAndroid();
            plugin.installStateStreamAndroid.listen((state) {
              if (state.status == InstallStatusAndroid.downloaded) {
                plugin.completeUpdateAndroid();
              }
            });
          }
        }
      }, onError: (error) {
        logger.e(error);
      });
    } else if (Platform.isIOS) {
      _checkIosUpdate();
    }
  }

  void _checkIosUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final bundleId = packageInfo.packageName;
      
      final response = await Dio().get('https://itunes.apple.com/lookup?bundleId=$bundleId');
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'];
        if (results != null && results.isNotEmpty) {
          final latestVersion = results[0]['version'];
          if (_isVersionNewer(currentVersion, latestVersion)) {
            await InAppUpdateFlutter().showUpdateForIos(appStoreId: '6789848688');
          }
        }
      }
    } catch (e) {
      logger.e('Failed to check iOS update: $e');
    }
  }

  bool _isVersionNewer(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();
      int currentLen = currentParts.length;
      int latestLen = latestParts.length;
      int length = currentLen > latestLen ? currentLen : latestLen;
      for (int i = 0; i < length; i++) {
        int currentPart = i < currentLen ? currentParts[i] : 0;
        int latestPart = i < latestLen ? latestParts[i] : 0;
        if (latestPart > currentPart) return true;
        if (currentPart > latestPart) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
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

            // Route to onboarding if not yet completed
            if (!onboarding.isCompleted) {
              return const OnboardingPage();
            }

            final isLoggedIn = snapshot.hasData && !snapshot.hasError;

            if (snapshot.hasData) {
              UserProfile.setUserData(snapshot.data!);
            }

            if (Platform.isIOS || isLoggedIn) {
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
