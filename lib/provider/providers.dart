import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wallrio/provider/export.dart';

List<SingleChildWidget> providers(BuildContext context) => [
      ChangeNotifierProvider(create: (context) => OnboardingProvider()),
      ChangeNotifierProvider(create: (context) => AuthProvider()),
      ChangeNotifierProvider(create: (context) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (context) => AdsProvider()),
      ChangeNotifierProvider(create: (context) => DarkThemeProvider()),
      ChangeNotifierProvider(create: (context) => WallRio()),
      ChangeNotifierProvider(create: (context) => Navigation()),
      ChangeNotifierProvider(create: (context) => WallDetails()),
      ChangeNotifierProvider(create: (context) => WallActionProvider()),
      ChangeNotifierProvider(create: (context) => FavouriteProvider()),
      ChangeNotifierProvider(create: (context) => LiveWallpaperProvider()),
    ];
