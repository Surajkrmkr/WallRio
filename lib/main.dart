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
  await MobileAds.instance.initialize();
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [
          // TODO: paste your device's test ID here once you get it from the
          // console log (see "To get test ads on this device, set...").
        ],
      ),
    );
  }
  await Workmanager().initialize(
    callbackDispatcher,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
