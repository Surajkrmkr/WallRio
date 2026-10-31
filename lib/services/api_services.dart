import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/packages/export.dart';

class ApiServices {
  static final rioJson = "rio.Json";
  static final collectionJson = "collection.json";

  // JSON lives in Firebase Storage under wallriojson/ (moved off GitLab raw, which rate-limits with 429).
  static const jsonBaseUrl =
      'https://firebasestorage.googleapis.com/v0/b/wallrio-e551b.firebasestorage.app/o/wallriojson%2F';

  static String jsonUrl(String file) => '$jsonBaseUrl$file?alt=media';

  /// Loads a JSON file through the wallpaper cache. Within max-age (5 min) the
  /// cached copy is used; after that it is revalidated by ETag, so an unchanged
  /// file costs a 304 with no body. The last copy is used when offline.
  static Future<dynamic> fetchJson(String file) async {
    final url = jsonUrl(file);
    final cache = WallCacheManager.instance;
    final cached = await cache.getFileFromCache(url);
    FileInfo info;
    try {
      info = cached != null && cached.validTill.isAfter(DateTime.now())
          ? cached
          : await cache.downloadFile(url);
    } catch (error) {
      if (cached == null) rethrow;
      debugPrint('Using cached $file: $error');
      info = cached;
    }
    return json.decode(await info.file.readAsString());
  }

  static Future<WallRioModel> getData() async {
    final WallRioModel model = await getRioData();
    final WallRioCollection collection = await getCollectionData();
    model.setCollection = collection;
    return model;
  }

  static Future<WallRioModel> getRioData() async {
    try {
      final dynamic decoded = await fetchJson('rio.Json');
      if (decoded is Map<String, dynamic>) {
        return WallRioModel.fromJson(decoded);
      } else if (decoded is Map) {
        return WallRioModel.fromJson(Map<String, dynamic>.from(decoded));
      }
      return WallRioModel(walls: [])..error = "Invalid format";
    } catch (error) {
      debugPrint(error.toString());
      return WallRioModel(walls: [])..error = "Something went wrong";
    }
  }

  static Future<WallRioCollection> getCollectionData() async {
    try {
      final dynamic decoded = await fetchJson('collections.json');
      if (decoded is Map<String, dynamic>) {
        return WallRioCollection.fromJson(decoded);
      } else if (decoded is Map) {
        return WallRioCollection.fromJson(Map<String, dynamic>.from(decoded));
      }
      return const WallRioCollection(collections: []);
    } catch (error) {
      debugPrint(error.toString());
      return const WallRioCollection(collections: []);
    }
  }

  static List<dynamic> _flattenList(dynamic item) {
    if (item is! List) return [];
    List<dynamic> result = [];
    for (var element in item) {
      if (element is List) {
        result.addAll(_flattenList(element));
      } else if (element is Map<String, dynamic> || element is Map) {
        result.add(element);
      }
    }
    return result;
  }

  static Future<List<Walls>> getDesktopData() async {
    try {
      final dynamic decoded = await fetchJson('desktop.json');
      List<dynamic> rawList = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('walls')) {
        rawList = _flattenList(decoded['walls']);
      } else if (decoded is List) {
        rawList = _flattenList(decoded);
      }
      return rawList
          .map((v) => Walls.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    } catch (error) {
      debugPrint('getDesktopData error: $error');
      return [];
    }
  }
}
