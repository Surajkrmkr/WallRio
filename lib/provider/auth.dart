import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  bool _googleSignInInitialized = false;

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String get displayName => _user?.displayName ?? _user?.email?.split('@').first ?? "Guest User";
  String get email => _user?.email ?? "";
  String get photoUrl => _user?.photoURL ?? "";

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setSignedInUser(User? user) {
    _user = user;
    notifyListeners();
  }

  AuthProvider() {
    if (FirebaseAuth.instance.currentUser != null) {
      _user = FirebaseAuth.instance.currentUser;
    }
  }

  Future<bool> signIn() async {
    setIsLoading = true;
    try {
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId:
              '340316492418-fcakfi05k8p05sa1c3jjui61ngjpc9jd.apps.googleusercontent.com',
        );
        _googleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.signInWithCredential(credential);
      if (firebaseAuth.currentUser != null) {
        setSignedInUser = firebaseAuth.currentUser!;
        await FirebaseAnalytics.instance
            .logLogin(loginMethod: 'google');
        ToastWidget.showToast("Logged in as ${firebaseAuth.currentUser!.email}");
        return true;
      }
      return false;
    } on Exception catch (exception) {
      logger.e(exception.toString());
      signOut();
      ToastWidget.showToast('Something went wrong');
      return false;
    } catch (error) {
      logger.e(error.toString());
      ToastWidget.showToast('Unexpected error occurred');
      return false;
    } finally {
      setIsLoading = false;
    }
  }

  Future<void> signOut() async {
    setIsLoading = true;
    try {
      await FirebaseAuth.instance.signOut();
      await googleSignIn.disconnect();
      _user = null;
      FirebaseAnalytics.instance.logEvent(name: 'user_sign_out');
      ToastWidget.showToast("Logged Out");
    } on Exception catch (exception) {
      debugPrint(exception.toString());
    } catch (error) {
      debugPrint(error.toString());
    } finally {
      setIsLoading = false;
    }
  }

  Future<bool> signInWithApple() async {
    setIsLoading = true;
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final AuthCredential oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.signInWithCredential(oauthCredential);
      if (firebaseAuth.currentUser != null) {
        setSignedInUser = firebaseAuth.currentUser!;
        await FirebaseAnalytics.instance.logLogin(loginMethod: 'apple');
        ToastWidget.showToast("Logged in successfully");
        return true;
      }
      return false;
    } on Exception catch (exception) {
      logger.e(exception.toString());
      signOut();
      ToastWidget.showToast('Something went wrong');
      return false;
    } catch (error) {
      logger.e(error.toString());
      ToastWidget.showToast('Unexpected error occurred');
      return false;
    } finally {
      setIsLoading = false;
    }
  }
}
