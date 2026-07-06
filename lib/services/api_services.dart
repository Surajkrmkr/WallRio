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
        return WallRioModel.fromJson(json.decode(response.data));
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
        return WallRioCollection.fromJson(json.decode(response.data));
      } else {
        return WallRioCollection(collections: []);
      }
    } catch (error) {
      debugPrint(error.toString());
      return WallRioCollection(collections: []);
    }
  }
}
