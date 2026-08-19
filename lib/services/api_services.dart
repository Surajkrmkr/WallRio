import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/packages/export.dart';

class ApiServices {
  static final rioJson = "rio.Json";
  static final collectionJson = "collection.json";

  static Future<WallRioModel> getData() async {
    final WallRioModel model = await getRioData();
    final WallRioCollection collection = await getCollectionData();
    model.setCollection = collection;
    return model;
  }

  static Future<WallRioModel> getRioData() async {
    final client = Dio();
    String url =
        'https://gitlab.com/teamshadowsupp/wallriojson/-/raw/main/rio.Json';

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded = response.data is String
            ? json.decode(response.data as String)
            : response.data;
        if (decoded is Map<String, dynamic>) {
          return WallRioModel.fromJson(decoded);
        } else if (decoded is Map) {
          return WallRioModel.fromJson(Map<String, dynamic>.from(decoded));
        }
        return WallRioModel(walls: [])..error = "Invalid format";
      } else {
        return WallRioModel(walls: [])..error = "Something went wrong";
      }
    } catch (error) {
      debugPrint(error.toString());
      return WallRioModel(walls: [])..error = "Something went wrong";
    }
  }

  static Future<WallRioCollection> getCollectionData() async {
    final client = Dio();
    String url =
        'https://gitlab.com/teamshadowsupp/wallriojson/-/raw/main/collections.json';

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded = response.data is String
            ? json.decode(response.data as String)
            : response.data;
        if (decoded is Map<String, dynamic>) {
          return WallRioCollection.fromJson(decoded);
        } else if (decoded is Map) {
          return WallRioCollection.fromJson(Map<String, dynamic>.from(decoded));
        }
        return const WallRioCollection(collections: []);
      } else {
        return const WallRioCollection(collections: []);
      }
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
    final client = Dio();
    String url =
        'https://gitlab.com/teamshadowsupp/wallriojson/-/raw/main/desktop.json';

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded = response.data is String
            ? json.decode(response.data)
            : response.data;
        List<dynamic> rawList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('walls')) {
          rawList = _flattenList(decoded['walls']);
        } else if (decoded is List) {
          rawList = _flattenList(decoded);
        }
        return rawList
            .map((v) => Walls.fromJson(Map<String, dynamic>.from(v)))
            .toList();
      } else {
        return [];
      }
    } catch (error) {
      debugPrint('getDesktopData error: $error');
      return [];
    }
  }
}
