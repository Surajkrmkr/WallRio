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
        id: json['id'] != null ? int.parse(json['id'].toString()) : 0,
        type: json['type'] ?? 'live',
        name: json['name'] ?? '',
        author: json['author'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        thumbnail: json['thumbnail'] ?? '',
        previewVideo: json['previewVideo'] ?? '',
        tags: json['tags'] != null ? json['tags'].cast<String>() : [],
        category: json['category'] ?? '',
        colorsString:
            json['color'] != null ? json['color'].cast<String>() : [],
        colorList: json['color'] != null
            ? (json['color'] as List<dynamic>)
                .map((c) => c.toString().toLowerCase().toColor())
                .toList()
            : [Colors.black],
        isPremium: json['isPremium'] ?? false,
        subjectId: json['subjectId'] ?? '',
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
            .map((v) => LiveWallpaper.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
    }
    if (json is Map<String, dynamic>) {
      final list = json['walls'] ?? json['data'] ?? [];
      return LiveWallpaperModel(
        walls: (list as List<dynamic>)
            .map((v) => LiveWallpaper.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
    }
    return LiveWallpaperModel();
  }
}
