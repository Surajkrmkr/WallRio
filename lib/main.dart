import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/oauth/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

void main() async {
  await initializationHandler();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void setStatusBarTheme(DarkThemeProvider provider) =>
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              provider.darkTheme ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              provider.darkTheme ? Brightness.light : Brightness.dark));

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers(context),
      child: Consumer<DarkThemeProvider>(
        builder: (context, provider, _) {
          setStatusBarTheme(provider);
          return MaterialApp(
              title: 'WallRio',
              navigatorKey: ToastWidget.navigatorKey,
              theme: WallRioThemeData.getLightThemeData(
                  context: context, isDarkTheme: false),
              darkTheme: WallRioThemeData.getLightThemeData(
                  context: context, isDarkTheme: true),
              themeMode: provider.darkTheme ? ThemeMode.dark : ThemeMode.light,
              debugShowCheckedModeBanner: false,
              navigatorObservers: [
                FirebaseAnalyticsObserver(
                    analytics: FirebaseAnalytics.instance),
              ],
              // Wraps the Navigator in its own Overlay ancestor so
              // ToastWidget.navigatorKey.currentContext (the Navigator's own
              // context, which sits above its internal Overlay) can still
              // resolve Overlay.of() for CNToast.
              builder: (context, child) => Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (context) => child!),
                    ],
                  ),
              home: const SplashPage());
        },
      ),
    );
  }
}

Future<void> initializationHandler() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final prefs = await SharedPreferences.getInstance();
  UserProfile.setPlusMemberInfo(
    prefs.getBool('user_is_plus_member') ?? false,
    hasCollectionAccess: prefs.getBool('user_has_collection_access') ?? false,
  );

  await ThemeService().getData();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }
  await FirebaseAppCheck.instance.activate();
  await NotificationService().init();
  // Next-Gen Google Mobile Ads initialization & background queue warm-up
  MobileAds.instance.initialize().then((status) {
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: const [],
        ),
      );
    }
    // Warm up banner preload queue in background for non-Plus users
    BannerAdManager.instance.warmUp();
  }).catchError((err) {
    debugPrint('[GMA] Next-Gen SDK initialization failed: $err');
  });
  await Workmanager().initialize(
    callbackDispatcher,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (kReleaseMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      final stackStr = details.stack?.toString() ?? '';

      final isTransientOrPlatformViewError = details.silent ||
          exceptionStr.contains('ClientException') ||
          exceptionStr.contains('Connection closed') ||
          exceptionStr.contains('SocketException') ||
          exceptionStr.contains('HttpException') ||
          exceptionStr.contains('Network is unreachable') ||
          exceptionStr.contains('Connection refused') ||
          stackStr.contains('getTransformTo') ||
          stackStr.contains('_PlatformViewPlaceholderBox') ||
          (exceptionStr.contains('Null check operator used on a null value') &&
              (stackStr.contains('localToGlobal') ||
                  stackStr.contains('platform_view.dart')));

      if (isTransientOrPlatformViewError) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } else {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final errorStr = error.toString();
      final stackStr = stack.toString();

      final isTransientOrPlatformViewError =
          errorStr.contains('ClientException') ||
          errorStr.contains('Connection closed') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('HttpException') ||
          errorStr.contains('Network is unreachable') ||
          errorStr.contains('Connection refused') ||
          stackStr.contains('getTransformTo') ||
          stackStr.contains('_PlatformViewPlaceholderBox') ||
          (errorStr.contains('Null check operator used on a null value') &&
              (stackStr.contains('localToGlobal') ||
                  stackStr.contains('platform_view.dart')));

      if (isTransientOrPlatformViewError) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      } else {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }
}
