import 'dart:io' show Platform;

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
      // Reconciliation note: `DarkThemeProvider.darkTheme` remains the
      // single legacy on/off switch (persisted under "isDarkMode") that
      // `_darkModeTile()` in settings_page.dart still flips directly for
      // backward compatibility. `AppThemeManager.mode` is the new source of
      // truth for `MaterialApp.themeMode` (it adds `ThemeMode.system`, which
      // `DarkThemeProvider` cannot express). `AppThemeManager.setMode()` is
      // what settings_page.dart's dark-mode tile now calls, and it mirrors
      // the choice back into `DarkThemeProvider` so any other existing code
      // reading `DarkThemeProvider.darkTheme` keeps working unchanged.
      child: Consumer2<DarkThemeProvider, AppThemeManager>(
        builder: (context, darkThemeProvider, appThemeManager, _) {
          setStatusBarTheme(darkThemeProvider);
          ThemeMode themeMode;
          if (appThemeManager.mode == AppThemeMode.system) {
            themeMode = ThemeMode.system;
          } else if (appThemeManager.mode == AppThemeMode.light) {
            themeMode = ThemeMode.light;
          } else {
            themeMode = ThemeMode.dark;
          }
          return MaterialApp(
              title: 'WallRio',
              navigatorKey: ToastWidget.navigatorKey,
              theme: appThemeManager.buildThemeData(
                  context: context, isDarkTheme: false),
              darkTheme: appThemeManager.buildThemeData(
                  context: context, isDarkTheme: true),
              themeMode: themeMode,
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
                      OverlayEntry(
                          builder: (context) {
                            // Fires once per cold-start/new-intent; the native
                            // side clears the pending extras after this read so
                            // it never double-navigates on rebuild.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              HomeWidgetLaunchService.handleLaunch();
                            });
                            return child ?? const SizedBox.shrink();
                          }),
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
  if (Platform.isAndroid || Platform.isIOS) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

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
  if (Platform.isIOS) {
    try {
      await RevenueCatService.initialize();
    } catch (error, stackTrace) {
      logger.e(
        'Failed to initialize RevenueCat. iOS purchases will be unavailable.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  
  try {
    // ignore: deprecated_member_use
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (e) {
    logger.w('AppCheck activation skipped/failed: $e');
  }}
  try {
    await NotificationService().init();
  } catch (e) {
    logger.w('NotificationService init error: $e');
  }

  // Google UMP is mobile-only (Android & iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    ConsentManager.instance.gatherConsent();
  }

  // Workmanager is mobile-only
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

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
