import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wallrio/model/export.dart';
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

  Future<bool> deleteAccount() async {
    setIsLoading = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEmail = user.email ?? UserProfile.email;

        // 1. Delete user data from Cloud Firestore
        if (userEmail.isNotEmpty) {
          try {
            final favDocRef = FirebaseFirestore.instance
                .collection('favourite')
                .doc(userEmail);
            final favItems = await favDocRef.collection('favouriteItems').get();
            for (final doc in favItems.docs) {
              await doc.reference.delete();
            }
            await favDocRef.delete();
          } catch (e) {
            logger.e('Error cleaning up Firestore data during account deletion: $e');
          }

          // Delete user personalization local preferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('local_personalization_$userEmail');
          } catch (e) {
            logger.e('Error clearing local personalization prefs: $e');
          }
        }

        // 2. Disconnect Google Sign-in session if applicable
        try {
          await googleSignIn.disconnect();
        } catch (e) {
          // May throw if not signed in with Google, can be safely ignored
        }

        // 3. Delete user account from Firebase Auth
        await user.delete();

        // 4. Reset in-memory state
        _user = null;
        UserProfile.setPlusMemberInfo(false, hasCollectionAccess: false);

        await FirebaseAnalytics.instance.logEvent(name: 'user_account_deleted');
        ToastWidget.showToast("Account deleted successfully");
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      logger.e('FirebaseAuthException during deleteAccount: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        ToastWidget.showToast('For security, please log out and sign back in to confirm account deletion.');
      } else {
        ToastWidget.showToast(e.message ?? 'Failed to delete account.');
      }
      return false;
    } catch (error) {
      logger.e('Error deleting account: $error');
      ToastWidget.showToast('Failed to delete account. Please try again.');
      return false;
    } finally {
      setIsLoading = false;
    }
  }
}

