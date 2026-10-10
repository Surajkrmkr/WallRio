import 'package:flutter/foundation.dart';

class PopupConfig {
  final String title;
  final String url;
  final String buttonText;
  final String _buttonLink;
  final String _description;
  final bool _status;
  final String buttonIosLink;
  final String descriptionIos;
  final bool statusIos;

  String get buttonLink =>
      defaultTargetPlatform == TargetPlatform.iOS ? buttonIosLink : _buttonLink;
  String get description => defaultTargetPlatform == TargetPlatform.iOS
      ? descriptionIos
      : _description;
  bool get status =>
      defaultTargetPlatform == TargetPlatform.iOS ? statusIos : _status;

  const PopupConfig({
    this.title = 'WallRio Update',
    this.url = '',
    this.buttonText = '',
    String buttonLink = '',
    String description = '',
    bool status = false,
    this.buttonIosLink = '',
    this.descriptionIos = '',
    this.statusIos = false,
  }) : _buttonLink = buttonLink,
       _description = description,
       _status = status;

  factory PopupConfig.fromJson(Map<dynamic, dynamic> json) => PopupConfig(
    title: (json['title'] ?? 'WallRio Update').toString(),
    url: json['url']?.toString() ?? '',
    buttonText: (json['button text'] ?? json['button_text'] ?? '').toString(),
    buttonLink: (json['button link'] ?? json['button_link'] ?? '').toString(),
    description: json['description']?.toString() ?? '',
    status:
        json['status'] == true ||
        json['status']?.toString().toLowerCase() == 'true',
    buttonIosLink: json['button_ios_link']?.toString() ?? '',
    descriptionIos: json['description_ios']?.toString() ?? '',
    statusIos:
        json['status_ios'] == true ||
        json['status_ios']?.toString().toLowerCase() == 'true',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'button text': buttonText,
    'button link': _buttonLink,
    'description': _description,
    'status': _status,
    'button_ios_link': buttonIosLink,
    'description_ios': descriptionIos,
    'status_ios': statusIos,
  };
}
