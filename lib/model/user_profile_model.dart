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
  static bool get plusMember => _plusMember;
  static bool get hasCollectionAccess => _hasCollectionAccess;

  static set _setAvatarUrl(String val) => _avatarUrl = val;
  static set _setEmail(String val) => _email = val;
  static set _setName(String val) => _name = val;
  static set _setPlusMember(bool val) => _plusMember = val;
  static set _setHasCollectionAccess(bool val) => _hasCollectionAccess = val;

  static void setUserData(User user) {
    _setName = user.displayName!;
    _setEmail = user.email!;
    _setAvatarUrl = user.photoURL!;
  }

  static void setPlusMemberInfo(bool val, {bool hasCollectionAccess = false}) {
    _setPlusMember = val;
    _setHasCollectionAccess = hasCollectionAccess;
  }
}
