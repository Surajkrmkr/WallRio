import 'package:flutter/material.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';

/// Firebase Storage only serves wallpapers to signed-in requests.
///
/// Google/Apple users send their own ID token. Guests get one from a separate
/// Firebase app instance signed in anonymously, so the main app's sign-in state
/// is untouched. Anonymous sign-ups are capped per IP per hour, which is why
/// they are only created for guests.
class StorageAuth {
  static const _appName = 'storage';
  static const _storageHost = 'firebasestorage.googleapis.com';

  static FirebaseAuth? _auth;
  static Future<void>? _initializing;

  /// Signs guests in ahead of the first wallpaper request; no-op for users
  /// already signed in with Google/Apple.
  static void warmUp() {
    if (FirebaseAuth.instance.currentUser == null) init();
  }

  static Future<void> init() => _initializing ??= _init();

  static Future<void> _init() async {
    try {
      FirebaseApp app;
      try {
        app = Firebase.app(_appName);
      } catch (_) {
        app = await Firebase.initializeApp(
          name: _appName,
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final auth = FirebaseAuth.instanceFor(app: app);
      if (auth.currentUser == null) await auth.signInAnonymously();
      _auth = auth;
    } catch (error) {
      debugPrint('StorageAuth init failed: $error');
      _initializing = null; // allow a retry on the next request
    }
  }

  static bool needsAuth(String url) => url.contains(_storageHost);

  /// Auth headers for [url]; empty for anything not served by Firebase Storage.
  /// getIdToken() returns the cached token and refreshes it once it expires.
  static Future<Map<String, String>> headersFor(String url) async {
    if (!needsAuth(url)) return const {};
    final token = await _signedInToken() ?? await _anonymousToken();
    return token == null ? const {} : {'Authorization': 'Firebase $token'};
  }

  static Future<String?> _signedInToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (error) {
      debugPrint('StorageAuth signed-in token failed: $error');
      return null;
    }
  }

  static Future<String?> _anonymousToken() async {
    await init();
    try {
      return await _auth?.currentUser?.getIdToken();
    } catch (error) {
      debugPrint('StorageAuth anonymous token failed: $error');
      return null;
    }
  }
}

class _AuthFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    return super.get(
      url,
      headers: {...?headers, ...await StorageAuth.headersFor(url)},
    );
  }
}

/// Cache manager for wallpapers that adds the Storage auth header on download.
/// Use it instead of DefaultCacheManager for any wallpaper URL.
class WallCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'wallrioAuthCache';

  static final WallCacheManager instance = WallCacheManager._();

  // Storage egress is billed, so keep far more than the package default of 200:
  // scrolling a few categories would otherwise evict and re-download thumbnails.
  WallCacheManager._()
    : super(
        Config(
          key,
          maxNrOfCacheObjects: 1000,
          fileService: _AuthFileService(),
        ),
      );
}
