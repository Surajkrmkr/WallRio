import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';

class WallDetails extends ChangeNotifier {
  bool _isDisposed = false;
  List<Color> colorSwatch = [];
  bool isColorPaletteLoading = false;
  bool isImageDetailsLoading = false;
  String size = "0 MB";
  int height = 0;
  int width = 0;

  set setIsColorPaletteLoading(bool val) {
    if (_isDisposed) return;
    isColorPaletteLoading = val;
    notifyListeners();
  }

  set setIsImageDetailsLoading(bool val) {
    if (_isDisposed) return;
    isImageDetailsLoading = val;
    notifyListeners();
  }

  set setColorSwatches(List<Color> colors) {
    if (_isDisposed) return;
    colorSwatch = colors;
    notifyListeners();
  }

  set setImgSize(String newSize) {
    if (_isDisposed) return;
    size = newSize;
    notifyListeners();
  }

  void setImageResolution(int newHeight, int newWidth) {
    if (_isDisposed) return;
    height = newHeight;
    width = newWidth;
    notifyListeners();
  }

  void getColorPalette(String url) async {
    if (_isDisposed) return;
    setIsColorPaletteLoading = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (_isDisposed) return;
      // Decode a small copy: palette quantization runs on the UI isolate and
      // full-resolution 4K wallpapers were the top source of ANRs.
      PaletteGenerator? paletteGenerator =
          await PaletteGenerator.fromImageProvider(
            ResizeImage(
              CachedNetworkImageProvider(url,
                  cacheManager: WallCacheManager.instance),
              width: 120,
            ),
            maximumColorCount: 10,
          );
      setColorSwatches = paletteGenerator.colors.toList();
    } catch (error) {
      logger.w('Failed to get color palette for $url: $error');
      setColorSwatches = [];
    } finally {
      setIsColorPaletteLoading = false;
    }
  }

  void getWallDetails(String url) async {
    if (_isDisposed) return;
    setIsImageDetailsLoading = true;
    setImgSize = "0 MB";
    setImageResolution(0, 0);
    try {
      await getImgDetails(url);
    } catch (error, stackTrace) {
      logger.e(
        'Failed to get wall details for $url: $error',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      setIsImageDetailsLoading = false;
    }
  }

  /// Shows a video's file size without downloading it: from the cache when it
  /// is already there, otherwise from a HEAD request (no body).
  void getVideoDetails(String url) async {
    if (_isDisposed) return;
    setIsImageDetailsLoading = true;
    setImgSize = "0 MB";
    setImageResolution(0, 0);
    try {
      final cached = await WallCacheManager.instance.getFileFromCache(url);
      final bytes = cached != null
          ? await cached.file.length()
          : await _remoteSize(url);
      if (!_isDisposed && bytes > 0) setImgSize = formatBytes(bytes);
    } catch (error) {
      logger.w('Failed to get video details for $url: $error');
    } finally {
      if (!_isDisposed) setIsImageDetailsLoading = false;
    }
  }

  Future<int> _remoteSize(String url) async {
    final response = await Dio().head(
      url,
      options: Options(headers: await StorageAuth.headersFor(url)),
    );
    return int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
  }

  Future<void> getImgDetails(String url) async {
    if (_isDisposed) return;
    try {
      final cache = WallCacheManager.instance;
      final file = await cache.getSingleFile(url);
      if (_isDisposed) return;
      final fileBytes = await file.readAsBytes();
      if (_isDisposed || fileBytes.isEmpty) return;

      setImgSize = formatBytes(fileBytes.lengthInBytes);

      try {
        var decodedImage = await decodeImageFromList(fileBytes);
        setImageResolution(decodedImage.height, decodedImage.width);
      } catch (decodeError) {
        logger.w('Could not decode image resolution for $url: $decodeError');
        setImageResolution(0, 0);
      }
    } catch (error, stackTrace) {
      logger.e(
        'Error fetching img details for $url: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
