import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
import 'package:wallrio/provider/ads.dart';
import 'package:wallrio/services/firebase/export.dart';
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

  void downloadImg(BuildContext context, String url, String name) async {
    FirebaseAnalytics.instance
        .logEvent(name: 'wallpaper_download', parameters: {'name': name});
    
    // Track progression
    Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.download);
    
    ToastWidget.showToast("Downloading wallpaper");
    setIsDownloading = true;
    setProgress = 0.0;
    bool downloadFailed = false;
    try {
      
      await FileDownloader.downloadFile(
          notificationType: NotificationType.completionOnly,
          downloadService: DownloadService.httpConnection,
          downloadDestination: DownloadDestinations.publicDownloads,
          url: url,
          onProgress: (String? fileName, double pros) {
            if (fileName != null) {
              final pro = pros / 100;
              setProgress = pro;

              
              
            }
          },
          onDownloadCompleted: (String path) {
            
          },
          onDownloadError: (String error) {
            downloadFailed = true;
          });
      
      if (downloadFailed) {
        setProgress = 0.0;
        ToastWidget.showToast("Failed to download wallpaper");
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        ToastWidget.showToast("Wallpaper Downloaded successfully");
        if (context.mounted) {
          Provider.of<AdsProvider>(context, listen: false).handleSuccessfulDownload(context);
        }
      }
    } catch (error) {
      setProgress = 0.0;
      logger.e(error);
      ToastWidget.showToast("Failed to download wallpaper");
    }

    setIsDownloading = false;
  }

  void setWall(String url, BuildContext context) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApplyWallDialogWidget(imgUrl: url));

  /// Saves an image or video to the device's Photos library. This is the
  /// iOS counterpart to [downloadImg]/[applyLiveWall] — iOS has no API to set
  /// a wallpaper or write to shared storage, so saving to Photos and letting
  /// the user set it manually is the closest equivalent.
  Future<void> saveToPhotos(BuildContext context, String url,
      {bool isVideo = false}) async {
    FirebaseAnalytics.instance
        .logEvent(name: 'wallpaper_save_to_photos', parameters: {'name': url});
    Provider.of<ProgressionProvider>(context, listen: false)
        .trackAction(ActionType.download);

    setIsDownloading = true;
    setProgress = 0.0;
    ToastWidget.showToast(isVideo ? "Saving video to Photos" : "Saving to Photos");

    try {
      // toAlbum: true — we save into a custom "WallRio" album, which needs
      // the elevated album-write permission, not just add-to-camera-roll.
      final hasAccess = await Gal.hasAccess(toAlbum: true) ||
          await Gal.requestAccess(toAlbum: true);
      if (!hasAccess) {
        if (context.mounted) _showPhotosAccessDeniedDialog(context);
        return;
      }

      final file = await DefaultCacheManager().getSingleFile(url);
      if (isVideo) {
        await Gal.putVideo(file.path, album: 'WallRio');
      } else {
        await Gal.putImage(file.path, album: 'WallRio');
      }
      ToastWidget.showToast(isVideo ? "Video saved to Photos" : "Saved to Photos");
    } catch (error) {
      logger.e(error);
      ToastWidget.showToast("Failed to save to Photos");
    } finally {
      setIsDownloading = false;
    }
  }

  /// Once Photos access is denied, iOS/Android won't show the system
  /// permission prompt again — the only way back is the app's Settings page.
  void _showPhotosAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text("Photos Access Needed"),
        content: const Text(
            "WallRio needs permission to save images to your Photos library. Please enable it in Settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// Shares an image or video through the native share sheet.
  Future<void> shareFile(BuildContext context, String url,
      {String text = 'Wallpaper from WallRio'}) async {
    Provider.of<ProgressionProvider>(context, listen: false)
        .trackAction(ActionType.apply);
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (error) {
      logger.e(error);
      ToastWidget.showToast("Failed to share");
    }
  }

  /// Sets a live (video) wallpaper. Android-only — there is no iOS API to set
  /// a live wallpaper; iOS uses [saveToPhotos] instead.
  Future<void> applyLiveWall(BuildContext context, String url) async {
    if (!Platform.isAndroid) return;

    setIsApplying = true;
    Provider.of<ProgressionProvider>(context, listen: false)
        .trackAction(ActionType.apply);
    ToastWidget.showToast("Applying live wallpaper…");

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      await WallpaperManagerPlus().setLiveWallpaper(file);
      ToastWidget.showToast("Live wallpaper applied");
    } catch (error) {
      ToastWidget.showToast("Failed to apply live wallpaper");
      logger.e(error);
    } finally {
      setIsApplying = false;
    }
  }

  /// Sets a static wallpaper. Android-only — there is no iOS API to set a
  /// wallpaper; iOS uses [saveToPhotos] instead.
  void applyWall(BuildContext context,
      {required String url, required int wallLocation}) async {
    if (!Platform.isAndroid) return;

    FirebaseAnalytics.instance.logEvent(
        name: 'wallpaper_applied',
        parameters: {'location': wallLocation == 1 ? 'homescreen' : wallLocation == 2 ? 'lockscreen' : 'both'});

    // Track progression
    Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.apply);

    setIsApplying = true;
    Navigator.pop(context);
    ToastWidget.showToast("Applying wallpaper");

    var file = await DefaultCacheManager().getSingleFile(url);
    try {
      await WallpaperManagerPlus().setWallpaper(file, wallLocation);
      ToastWidget.showToast("Wallpaper applied successfully");
    } catch (error) {
      ToastWidget.showToast("Failed to apply wallpaper");
      logger.e(error);
    } finally {
      setIsApplying = false;
    }
  }
}
