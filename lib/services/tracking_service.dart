import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Requests iOS App Tracking Transparency authorization. Android has no such
/// concept (AD_ID permission covers ad personalization instead), so this is
/// a no-op there.
class TrackingService {
  static Future<void> requestIfNeeded() async {
    if (!Platform.isIOS) return;

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
