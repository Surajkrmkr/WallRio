import 'package:flutter/material.dart';
import 'package:wallrio/model/collection_model.dart';
import 'package:wallrio/model/popup_config.dart';
import 'package:wallrio/services/export.dart';

class SubscriptionPlan {
  final String id;
  final int actualPrice;

  const SubscriptionPlan({required this.id, required this.actualPrice});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id']?.toString() ?? '',
        actualPrice: json['actual price'] != null
            ? int.tryParse(json['actual price'].toString()) ?? 0
            : 0,
      );
}

class WallRioModel {
  final List<Banners> banners;
  final Search search;
  final List<Walls> walls;
  final List<SubscriptionPlan> subscriptionPlans;
  final PopupConfig? popupConfig;
  WallRioCollection collection;
  String error = "";

  WallRioModel({
    this.banners = const [],
    this.walls = const [],
    this.collection = const WallRioCollection(),
    this.search = const Search(),
    this.subscriptionPlans = const [],
    this.popupConfig,
  });

  set setCollection(WallRioCollection value) => collection = value;

  factory WallRioModel.fromJson(Map<String, dynamic> json) => WallRioModel(
      search: json['search'] == null || json['search'] is! Map
          ? const Search()
          : Search.fromJson(Map<String, dynamic>.from(json["search"] as Map)),
      banners: json['banners'] == null || json['banners'] is! List
          ? []
          : (json['banners'] as List<dynamic>)
              .whereType<Map>()
              .map((v) => Banners.fromJson(Map<String, dynamic>.from(v)))
              .toList(),
      walls: json['walls'] == null || json['walls'] is! List
          ? []
          : (json['walls'] as List<dynamic>)
              .whereType<Map>()
              .map((v) => Walls.fromJson(Map<String, dynamic>.from(v)))
              .toList(),
      subscriptionPlans: json['subscription'] == null || json['subscription'] is! List
          ? []
          : (json['subscription'] as List<dynamic>)
              .whereType<Map>()
              .map((v) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(v)))
              .toList(),
      popupConfig: json['pop-up'] != null && json['pop-up'] is Map
          ? PopupConfig.fromJson(json['pop-up'] as Map)
          : (json['popup'] != null && json['popup'] is Map
              ? PopupConfig.fromJson(json['popup'] as Map)
              : null));
}

class Banners {
  final int id;
  final String url;
  final String category;
  final String link;
  final String title;
  final int? wallId;

  const Banners({
    this.id = 0,
    this.url = "",
    this.category = "",
    this.link = "",
    this.title = "",
    this.wallId,
  });

  factory Banners.fromJson(Map<String, dynamic> json) => Banners(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        url: json['url']?.toString() ?? "",
        category: json['category']?.toString() ?? "",
        link: json['link']?.toString() ?? "",
        title: (json['title'] ??
                json['text'] ??
                json['banner_title'] ??
                json['caption'] ??
                json['label'] ??
                "")
            .toString(),
        wallId: json['wall_id'] is int
            ? json['wall_id'] as int
            : int.tryParse(json['wall_id']?.toString() ?? ''),
      );
}

class Search {
  final Banners banner;
  final List<String> categories;
  final List<String> tags;
  final List<String> hotTags;

  const Search(
      {this.banner = const Banners(),
      this.categories = const [],
      this.tags = const [],
      this.hotTags = const []});

  factory Search.fromJson(Map<String, dynamic> json) => Search(
        banner: json['banner'] != null && json['banner'] is Map
            ? Banners.fromJson(Map<String, dynamic>.from(json["banner"] as Map))
            : const Banners(),
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        hotTags: (json['hotTags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class Walls {
  final int id;
  final String name;
  final String subjectId;
  final String author;
  final String url;
  final String thumbnail;
  final bool isPremium;
  final List<String> tags;
  final String category;
  final List<String> colorsString;
  final List<Color> colorList;

  Walls(
      {required this.id,
      required this.name,
      required this.subjectId,
      required this.author,
      required this.url,
      required this.isPremium,
      required this.thumbnail,
      required this.tags,
      required this.category,
      required this.colorsString,
      required this.colorList});

  factory Walls.fromJson(Map<String, dynamic> json) => Walls(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        name: json['name']?.toString() ?? "",
        subjectId: json['subjectId']?.toString() ?? "",
        author: json['author']?.toString() ?? "",
        url: json['url']?.toString() ?? "",
        thumbnail: json['thumbnail']?.toString() ?? "",
        isPremium: json['isPremium'] == true ||
            json['isPremium']?.toString().toLowerCase() == 'true',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        category: json['category']?.toString() ?? "",
        colorsString: (json['color'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        colorList: json['color'] != null && json['color'] is List
            ? (json['color'] as List<dynamic>)
                .map((color) => color.toString().toLowerCase().toColor())
                .toList()
            : [Colors.black],
      );

  static Map<String, dynamic> toJson(Walls wall) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = wall.id;
    data['name'] = wall.name;
    data['author'] = wall.author;
    data['url'] = wall.url;
    data['thumbnail'] = wall.thumbnail;
    data['isPremium'] = wall.isPremium;
    data['tags'] = wall.tags;
    data['category'] = wall.category;
    data['color'] = wall.colorsString;
    return data;
  }
}
