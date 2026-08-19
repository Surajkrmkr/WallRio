import 'dart:collection';
import 'package:video_player/video_player.dart';
import 'package:wallrio/services/packages/export.dart';

class LivePreviewManager {
  static final LivePreviewManager instance = LivePreviewManager._internal();
  LivePreviewManager._internal();

  static const int maxControllers = 3;
  static const String qualityPrefKey = 'preview_quality_setting';

  final LinkedHashMap<String, VideoPlayerController> _controllers =
      LinkedHashMap<String, VideoPlayerController>();

  String _qualityMode = 'auto'; // 'auto', 'high', 'datasaver'
  bool _isScrollingFast = false;

  String get qualityMode => _qualityMode;

  Future<void> initSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _qualityMode = prefs.getString(qualityPrefKey) ?? 'auto';
    } catch (_) {}
  }

  Future<void> setQualityMode(String mode) async {
    _qualityMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(qualityPrefKey, mode);
    } catch (_) {}
    if (mode == 'datasaver') {
      disposeAll();
    }
  }

  void setScrollingFast(bool isFast) {
    _isScrollingFast = isFast;
    if (isFast) {
      pauseAll();
    }
  }

  Future<VideoPlayerController?> getController(String url) async {
    if (url.isEmpty || _qualityMode == 'datasaver' || _isScrollingFast) {
      return null;
    }

    if (_controllers.containsKey(url)) {
      final controller = _controllers.remove(url)!;
      _controllers[url] = controller;
      if (!controller.value.isPlaying) {
        controller.play();
      }
      return controller;
    }

    while (_controllers.length >= maxControllers) {
      final oldestKey = _controllers.keys.first;
      final oldestController = _controllers.remove(oldestKey);
      try {
        oldestController?.pause();
        oldestController?.dispose();
      } catch (e) {
        logger.e('Error disposing old video controller: $e');
      }
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      _controllers[url] = controller;
      return controller;
    } catch (e) {
      logger.e('Failed to initialize video preview controller for $url: $e');
      return null;
    }
  }

  void pauseAll() {
    for (final controller in _controllers.values) {
      try {
        if (controller.value.isPlaying) {
          controller.pause();
        }
      } catch (_) {}
    }
  }

  void resumeVisible(List<String> visibleUrls) {
    for (final entry in _controllers.entries) {
      if (visibleUrls.contains(entry.key)) {
        try {
          if (!entry.value.value.isPlaying) {
            entry.value.play();
          }
        } catch (_) {}
      } else {
        try {
          if (entry.value.value.isPlaying) {
            entry.value.pause();
          }
        } catch (_) {}
      }
    }
  }

  void disposeAll() {
    for (final controller in _controllers.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (_) {}
    }
    _controllers.clear();
  }
}
