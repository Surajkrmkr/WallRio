import 'package:flutter/material.dart';
import 'package:wallrio/services/export.dart';

class LiveWallpaper {
  final int id;
  final String type;
  final String name;
  final String author;
  final String videoUrl;
  final String thumbnail;
  final String previewVideo;
  final List<String> tags;
  final String category;
  final List<String> colorsString;
  final List<Color> colorList;
  final bool isPremium;
  final String subjectId;

  const LiveWallpaper({
    required this.id,
    required this.type,
    required this.name,
    required this.author,
    required this.videoUrl,
    required this.thumbnail,
    required this.previewVideo,
    required this.tags,
    required this.category,
    required this.colorsString,
    required this.colorList,
    required this.isPremium,
    required this.subjectId,
  });

  factory LiveWallpaper.fromJson(Map<String, dynamic> json) => LiveWallpaper(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        type: json['type']?.toString() ?? 'live',
        name: json['name']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        videoUrl: json['videoUrl']?.toString() ?? '',
        thumbnail: json['thumbnail']?.toString() ?? '',
        previewVideo: json['previewVideo']?.toString() ?? '',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        category: json['category']?.toString() ?? '',
        colorsString: (json['color'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        colorList: json['color'] != null && json['color'] is List
            ? (json['color'] as List<dynamic>)
                .map((c) => c.toString().toLowerCase().toColor())
                .toList()
            : [Colors.black],
        isPremium: json['isPremium'] == true ||
            json['isPremium']?.toString().toLowerCase() == 'true',
        subjectId: json['subjectId']?.toString() ?? '',
      );

  static Map<String, dynamic> toJson(LiveWallpaper wall) => {
        'id': wall.id,
        'name': wall.name,
        'author': wall.author,
        'videoUrl': wall.videoUrl,
        'thumbnail': wall.thumbnail,
        'isPremium': wall.isPremium,
        'tags': wall.tags,
        'category': wall.category,
        'color': wall.colorsString,
      };
}

class LiveWallpaperModel {
  final List<LiveWallpaper> walls;
  String error;

  LiveWallpaperModel({this.walls = const [], this.error = ''});

  factory LiveWallpaperModel.fromJson(dynamic json) {
    if (json is List) {
      return LiveWallpaperModel(
        walls: json
            .whereType<Map>()
            .map((v) => LiveWallpaper.fromJson(Map<String, dynamic>.from(v)))
            .toList(),
      );
    }
    if (json is Map<String, dynamic>) {
      final list = json['walls'] ?? json['data'] ?? [];
      if (list is List) {
        return LiveWallpaperModel(
          walls: list
              .whereType<Map>()
              .map((v) => LiveWallpaper.fromJson(Map<String, dynamic>.from(v)))
              .toList(),
        );
      }
    }
    return LiveWallpaperModel();
  }
}
