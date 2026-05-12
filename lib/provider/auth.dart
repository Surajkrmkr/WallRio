import 'package:flutter/material.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  bool _googleSignInInitialized = false;

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  User? _user;

  User get user => _user!;

  set setIsLoading(val) {
    isLoading = val;
    notifyListeners();
  }

  set setSignedInUser(User user) {
    _user = user;
  }

  AuthProvider() {
    if (FirebaseAuth.instance.currentUser != null) {
      setSignedInUser = FirebaseAuth.instance.currentUser!;
    }
  }

  Future<void> signIn() async {
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
      }
      ToastWidget.showToast("Logged in as ${firebaseAuth.currentUser!.email}");
    } on Exception catch (exception) {
      logger.e(exception.toString());
      signOut();
      ToastWidget.showToast('Something went wrong');
    } catch (error) {
      logger.e(error.toString());
      ToastWidget.showToast('Unexpected error occurred');
    } finally {
      setIsLoading = false;
    }
  }

  Future<void> signOut() async {
    setIsLoading = true;
    try {
      await FirebaseAuth.instance.signOut();
      await googleSignIn.disconnect();
      ToastWidget.showToast("Logged Out");
    } on Exception catch (exception) {
      debugPrint(exception.toString());
    } catch (error) {
      debugPrint(error.toString());
    } finally {
      setIsLoading = false;
    }
  }
}
