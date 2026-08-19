import 'dart:io';

import 'package:wallrio/model/wall_rio_model.dart';

class WallRioCollection {
  final List<Collections> collections;

  const WallRioCollection({this.collections = const []});

  factory WallRioCollection.fromJson(Map<String, dynamic> json) =>
      WallRioCollection(
        collections: json['collections'] == null || json['collections'] is! List
            ? []
            : (json['collections'] as List<dynamic>)
                .whereType<Map>()
                .map((v) => Collections.fromJson(Map<String, dynamic>.from(v)))
                .where((c) => !(Platform.isIOS && c.hideForIOS))
                .toList(),
      );
}

class Collections {
  int id;
  String productId;
  String name;
  List<Walls>? walls;
  bool hideForIOS;

  Collections({
    required this.id,
    required this.productId,
    required this.name,
    required this.walls,
    this.hideForIOS = false,
  });

  factory Collections.fromJson(Map<String, dynamic> json) => Collections(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        productId: json['productId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        walls: json['walls'] == null || json['walls'] is! List
            ? []
            : (json['walls'] as List<dynamic>)
                .whereType<Map>()
                .map((v) => Walls.fromJson(Map<String, dynamic>.from(v)))
                .toList(),
        hideForIOS: json['hideForIOS'] == true ||
            json['hideForIOS']?.toString().toLowerCase() == 'true',
      );
}
