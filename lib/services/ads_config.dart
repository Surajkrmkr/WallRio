class AdsConfig {
  AdsConfig._();

  static const bool enabled = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: false,
  );
}