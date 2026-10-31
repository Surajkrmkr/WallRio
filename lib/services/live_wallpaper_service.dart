import 'package:flutter/material.dart';
import 'package:wallrio/model/live_wallpaper_model.dart';
import 'package:wallrio/services/api_services.dart';

class LiveWallpaperService {
  static Future<LiveWallpaperModel> getData() async {
    try {
      return LiveWallpaperModel.fromJson(
          await ApiServices.fetchJson('live_wall.json'));
    } catch (error) {
      debugPrint(error.toString());
      return LiveWallpaperModel()..error = 'Something went wrong';
    }
  }
}
