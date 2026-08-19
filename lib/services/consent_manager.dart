import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/banner_ad_manager.dart';

/// Centralized Google User Messaging Platform (UMP) Consent Manager.
///
/// Implements Google-certified CMP consent information updates, automated
/// form presentation, duplicate-initialization protection, ad request gating,
/// and IAB TCF privacy options management.
class ConsentManager extends ChangeNotifier {
  ConsentManager._internal();
  static final ConsentManager instance = ConsentManager._internal();

  bool _isMobileAdsInitialized = false;
  bool _isConsentUpdating = false;
  bool _canRequestAds = false;
  bool _isPrivacyOptionsRequired = false;

  /// Whether ads can currently be requested according to Google UMP signals.
  bool get canRequestAds => _canRequestAds;

  /// Whether the IAB TCF privacy options entry point is required by regulation.
  bool get isPrivacyOptionsRequired => _isPrivacyOptionsRequired;

  /// Whether the Mobile Ads SDK has already been initialized.
  bool get isMobileAdsInitialized => _isMobileAdsInitialized;

  /// Requests the latest consent information from Google UMP and displays
  /// the consent form if required by regulation.
  Future<void> gatherConsent({bool debugEea = false}) async {
    if (_isConsentUpdating) {
      if (kDebugMode) {
        debugPrint('[UMP] Consent update already in progress, skipping duplicate call.');
      }
      return;
    }
    _isConsentUpdating = true;

    if (kDebugMode) {
      debugPrint('[UMP] Consent update started');
    }

    final ConsentDebugSettings? debugSettings;
    if (kDebugMode && debugEea) {
      debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
      );
    } else {
      debugSettings = null;
    }

    final params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );

    final Completer<void> completer = Completer<void>();

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          if (kDebugMode) {
            final status = await ConsentInformation.instance.getConsentStatus();
            final isFormAvailable =
                await ConsentInformation.instance.isConsentFormAvailable();
            final privacyStatus = await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus();

            debugPrint('[UMP] Consent status: $status');
            debugPrint('[UMP] Consent form available: $isFormAvailable');
            debugPrint('[UMP] Privacy options required: $privacyStatus');
          }

          // Load and show consent form if required by regulation
          ConsentForm.loadAndShowConsentFormIfRequired(
            (FormError? formError) async {
              if (formError != null && kDebugMode) {
                debugPrint(
                    '[UMP] Consent form error: [${formError.errorCode}] ${formError.message}');
              }

              if (kDebugMode) {
                debugPrint('[UMP] Consent flow completed');
              }

              await _updateConsentState();
              _isConsentUpdating = false;
              if (!completer.isCompleted) completer.complete();
            },
          );
        },
        (FormError error) async {
          if (kDebugMode) {
            debugPrint(
                '[UMP] Consent update error: [${error.errorCode}] ${error.message}');
          }

          await _updateConsentState();
          _isConsentUpdating = false;
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UMP] Unexpected error during consent gathering: $e');
      }
      await _updateConsentState();
      _isConsentUpdating = false;
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  /// Refreshes `canRequestAds` and privacy options requirement status from UMP.
  Future<void> _updateConsentState() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final privacyStatus =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _isPrivacyOptionsRequired =
          privacyStatus == PrivacyOptionsRequirementStatus.required;

      if (kDebugMode) {
        debugPrint('[UMP] canRequestAds result: $_canRequestAds');
        debugPrint(
            '[UMP] Privacy options requirement: $_isPrivacyOptionsRequired');
      }

      if (_canRequestAds) {
        await _initializeMobileAdsIfPossible();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UMP] Error querying UMP state: $e');
      }
    }
  }

  /// Initializes the Google Mobile Ads SDK exactly once when permitted by UMP.
  Future<void> _initializeMobileAdsIfPossible() async {
    if (_isMobileAdsInitialized || !_canRequestAds) {
      return;
    }
    _isMobileAdsInitialized = true;

    if (kDebugMode) {
      debugPrint('[UMP] Initializing MobileAds SDK (canRequestAds is true)...');
    }

    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: const [],
          ),
        );
      }

      // Warm up banner preload queue for non-Plus users
      if (!UserProfile.plusMember) {
        BannerAdManager.instance.warmUp();
      }
    } catch (err) {
      debugPrint('[GMA] Next-Gen SDK initialization failed: $err');
    }
  }

  /// Shows the IAB TCF Privacy Options form so users can review or change their consent choices.
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('[UMP] Showing Privacy Options form...');
    }

    final Completer<void> completer = Completer<void>();

    try {
      ConsentForm.showPrivacyOptionsForm((FormError? formError) async {
        if (formError != null && kDebugMode) {
          debugPrint(
              '[UMP] Privacy options form error: [${formError.errorCode}] ${formError.message}');
        }

        if (kDebugMode) {
          debugPrint('[UMP] Privacy options flow completed');
        }

        await _updateConsentState();
        if (!completer.isCompleted) completer.complete();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UMP] Error presenting privacy options form: $e');
      }
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  /// Refreshes the privacy options status (e.g. when entering Settings).
  Future<void> checkPrivacyOptionsRequirement() async {
    try {
      final privacyStatus =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      final required =
          privacyStatus == PrivacyOptionsRequirementStatus.required;
      if (_isPrivacyOptionsRequired != required) {
        _isPrivacyOptionsRequired = required;
        notifyListeners();
      }
    } catch (_) {}
  }
}
