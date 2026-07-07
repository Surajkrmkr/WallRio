import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
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

  void setWall(String url, BuildContext context) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ApplyWallDialogWidget(imgUrl: url));

  Future<void> applyLiveWall(BuildContext context, String url) async {
    setIsApplying = true;
    
    // Track progression
    Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.apply);
    
    if (Platform.isAndroid) {
      ToastWidget.showToast("Applying live wallpaper…");
    }
    
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      if (Platform.isAndroid) {
        await WallpaperManagerPlus().setLiveWallpaper(file);
        ToastWidget.showToast("Live wallpaper applied");
      } else {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: 'Use as Wallpaper');
      }
    } catch (error) {
      if (Platform.isAndroid) {
        ToastWidget.showToast("Failed to apply live wallpaper");
      }
      logger.e(error);
    } finally {
      setIsApplying = false;
    }
  }

  void applyWall(BuildContext context,
      {required String url, required int wallLocation}) async {
    FirebaseAnalytics.instance.logEvent(
        name: 'wallpaper_applied',
        parameters: {'location': wallLocation == 1 ? 'homescreen' : wallLocation == 2 ? 'lockscreen' : 'both'});
    
    // Track progression
    Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.apply);
    
    setIsApplying = true;
    Navigator.pop(context);
    
    if (Platform.isAndroid) {
      ToastWidget.showToast("Applying wallpaper");
    }
    
    var file = await DefaultCacheManager().getSingleFile(url);
    try {
      if (Platform.isAndroid) {
        await WallpaperManagerPlus().setWallpaper(file, wallLocation);
        ToastWidget.showToast("Wallpaper applied successfully");
      } else {
         // ignore: deprecated_member_use
         await Share.shareXFiles([XFile(file.path)], text: 'Set as Wallpaper');
      }
    } catch (error) {
      if (Platform.isAndroid) {
         ToastWidget.showToast("Failed to apply wallpaper");
      }
      logger.e(error);
    } finally {
      setIsApplying = false;
    }
  }
}
