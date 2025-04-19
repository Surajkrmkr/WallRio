import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';
// import 'package:android_download_manager/android_download_manager.dart';

class WallActionProvider extends ChangeNotifier {
  bool isDownloading = false;
  bool isApplying = false;

  set setIsDownloading(bool val) {
    isDownloading = val;
    notifyListeners();
  }

  set setIsApplying(bool val) {
    isApplying = val;
    notifyListeners();
  }

  void downloadImg(url, name) async {
    ToastWidget.showToast("Downloading wallpaper");
    setIsDownloading = true;
    try {
      // final String downloadDir = await AndroidPathProvider.downloadsPath;
      final Directory? appStorageDir = await getExternalStorageDirectory();
      // await AndroidDownloadManager.enqueue(
      //   downloadUrl: url,
      //   downloadPath: appStorageDir != null ? appStorageDir.path.replaceFirst("data", "media") : downloadDir,
      //   fileName: "$name.png",
      // );
      ToastWidget.showToast("Wallpaper Downloaded successfully");
    } catch (error) {
      logger.e(error);
      ToastWidget.showToast("Failed to download wallpaper");
    }

    setIsDownloading = false;
  }

  void setWall(url, context) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApplyWallDialogWidget(imgUrl: url));

  void applyWall(context,
      {required String url,
      required int wallLocation,
      required bool isNative}) async {
    setIsApplying = true;
    Navigator.pop(context);
    ToastWidget.showToast("Applying wallpaper");
    var file = await DefaultCacheManager().getSingleFile(url);
    try {
      isNative
          ? await WallpaperManagerFlutter()
              .setWallpaper(file.path, wallLocation)
          : await WallpaperManagerFlutter().setWallpaper(
              file.path,
              wallLocation,
            );
      ToastWidget.showToast("Wallpaper applied successfully");
    } catch (error) {
      ToastWidget.showToast("Failed to apply wallpaper");
      logger.e(error);
    } finally {
      setIsApplying = false;
    }
  }
}
