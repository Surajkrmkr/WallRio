import 'package:flutter/material.dart';
import 'package:wallrio/model/collection_model.dart';
import 'package:wallrio/services/export.dart';

class WallRioModel {
  final List<Banners> banners;
  final Search search;
  final List<Walls> walls;
  WallRioCollection collection;
  String error = "";

  WallRioModel(
      {this.banners = const [],
      this.walls = const [],
      this.collection = const WallRioCollection(),
      this.search = const Search()});

  set setCollection(WallRioCollection value) => collection = value;

  factory WallRioModel.fromJson(Map<String, dynamic> json) => WallRioModel(
      search: json['search'] == null
          ? const Search()
          : Search.fromJson(json["search"]),
      banners: json['banners'] == null
          ? []
          : (json['banners'] as List<dynamic>)
              .map((v) => Banners.fromJson(v))
              .toList(),
      walls: json['walls'] == null
          ? []
          : (json['walls'] as List<dynamic>)
              .map((v) => Walls.fromJson(v))
              .toList());
}

class Banners {
  final int id;
  final String url;
  final String category;
  final String link;

  const Banners({this.id = 0, this.url = "", this.category = "", this.link = ""});

  factory Banners.fromJson(Map<String, dynamic> json) => Banners(
        id: json['id'] ?? 0,
        url: json['url'] ?? "",
        category: json['category'] ?? "",
        link: json['link'] ?? "",
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
        banner: json['banner'] != null
            ? Banners.fromJson(json["banner"])
            : const Banners(),
        categories:
            json['categories'] != null ? json['categories'].cast<String>() : [],
        tags: json['tags'] != null ? json['tags'].cast<String>() : [],
        hotTags: json['hotTags'] != null ? json['hotTags'].cast<String>() : [],
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
        id: json['id'] != null ? int.parse(json['id'].toString()) : 0,
        name: json['name'] ?? "",
        subjectId: json['subjectId'] ?? "",
        author: json['author'] ?? "",
        url: json['url'] ?? "",
        thumbnail: json['thumbnail'] ?? "",
        isPremium: json['isPremium'] ?? false,
        tags: json['tags'] != null ? json['tags'].cast<String>() : [],
        category: json['category'] ?? "",
        colorsString: json['color'] != null ? json['color'].cast<String>() : [],
        colorList: json['color'] != null
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
