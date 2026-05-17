import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wallrio/model/live_wallpaper_model.dart';
import 'package:wallrio/services/packages/export.dart';

class LiveWallpaperService {
  static const _url =
      'https://gitlab.com/teamshadowsupp/wallriojson/-/raw/main/live_wall.json';

  static Future<LiveWallpaperModel> getData() async {
    final client = Dio();
    try {
      final response = await client.get(_url);
      if (response.statusCode == 200) {
        // Dio 5.x may auto-decode JSON; handle both String and pre-parsed Map.
        final data = response.data is String
            ? json.decode(response.data as String)
            : response.data;
        return LiveWallpaperModel.fromJson(data);
      }
      return LiveWallpaperModel()..error = 'Something went wrong';
    } catch (error) {
      debugPrint(error.toString());
      return LiveWallpaperModel()..error = 'Something went wrong';
    }
  }
}
