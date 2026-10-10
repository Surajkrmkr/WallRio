# Wallrio

A new Flutter project.

## Ads toggle

Ads are disabled by default on Android and iOS. The existing ad implementations
and placements are retained behind `AdsConfig.enabled` in
`lib/services/ads_config.dart`. This also skips ad consent and SDK initialization.

To enable ads again, pass `--dart-define=ADS_ENABLED=true` when running or building:

```sh
flutter run --dart-define=ADS_ENABLED=true
flutter build appbundle --dart-define=ADS_ENABLED=true
flutter build ios --dart-define=ADS_ENABLED=true
```

Omit the flag (or set it to `false`) to keep ads off. Changing this build-time
toggle requires a full restart or rebuild, not a hot reload.

## iOS in-app purchases

iOS purchases use RevenueCat. Configure the existing App Store products in
RevenueCat and attach the subscription and lifetime products to an entitlement
named `pro`. Build with the iOS public SDK key:

```sh
flutter build ios --dart-define=REVENUECAT_IOS_API_KEY=appl_your_public_sdk_key
```

Use the RevenueCat App Store key (`appl_...`) for App Store purchases. A
RevenueCat Test Store key (`test_...`) is not an App Store key. Android
purchases continue to use Google Play Billing.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
