import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class WallActionProvider extends ChangeNotifier {
  bool isDownloading = false;
  double progress = 0.0;
  bool isApplying = false;

  set setIsDownloading(bool val) {
    isDownloading = val;
    notifyListeners();
  }

  set setIsApplying(bool val) {
    isApplying = val;
    notifyListeners();
  }

  set setProgress(double data) {
    progress = data;
    notifyListeners();
  }

  void downloadImg(url, name) async {
    ToastWidget.showToast("Downloading wallpaper");
    setIsDownloading = true;
    setProgress = 0.0;
    try {
      Directory downloadDirectory = await getDownloadDirectory();
      await FileDownloader.downloadFile(
          notificationType: NotificationType.completionOnly,
          downloadService: DownloadService.httpConnection,
          downloadDestination: DownloadDestinations.publicDownloads,
          url: url,
          onProgress: (String? fileName, double pros) {
            if (fileName != null) {
              final pro = pros / 100;
              setProgress = pro;

              print(pro);
              print(fileName);
            }
          },
          onDownloadCompleted: (String path) {
            print('FILE DOWNLOADED TO PATH: $path');
          },
          onDownloadError: (String error) {
            print('DOWNLOAD ERROR: $error');
          });
      await Future.delayed(Duration(milliseconds: 500));
      ToastWidget.showToast("Wallpaper Downloaded successfully");
    } catch (error) {
      setProgress = 0.0;
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
