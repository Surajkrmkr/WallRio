import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:wallrio/services/firebase/export.dart';

class UserProfile {
  static String _avatarUrl = "";
  static String _email = "";
  static String _name = "";
  static bool _plusMember = false;
  static bool _hasCollectionAccess = false;

  static String get avatarUrl => _avatarUrl;
  static String get email => _email;
  static String get name => _name;
  /// Debug builds only: `--dart-define=FORCE_FREE_USER=true` makes the app
  /// behave as a free user so gates and paywalls can be tested with an
  /// account that already has Pro. Has no effect in profile or release builds.
  static const bool _forceFreeUser = bool.fromEnvironment('FORCE_FREE_USER');
  static bool get plusMember => !(kDebugMode && _forceFreeUser) && _plusMember;
  static bool get hasCollectionAccess => _hasCollectionAccess;

  static set _setAvatarUrl(String val) => _avatarUrl = val;
  static set _setEmail(String val) => _email = val;
  static set _setName(String val) => _name = val;
  static set _setPlusMember(bool val) => _plusMember = val;
  static set _setHasCollectionAccess(bool val) => _hasCollectionAccess = val;

  static void setUserData(User user) {
    _setName = user.displayName ?? user.email?.split('@').first ?? "User";
    _setEmail = user.email ?? "";
    _setAvatarUrl = user.photoURL ?? "";
  }

  static void setPlusMemberInfo(bool val, {bool hasCollectionAccess = false}) {
    _setPlusMember = val;
    _setHasCollectionAccess = hasCollectionAccess;
  }
}
