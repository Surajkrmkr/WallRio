import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalizationModel {
  String activeAppIcon;
  String activeProfileFrame;
  String activeBadge;
  DateTime? subscriptionStartDate;

  PersonalizationModel({
    this.activeAppIcon = 'icon_default',
    this.activeProfileFrame = 'none',
    this.activeBadge = 'none',
    this.subscriptionStartDate,
  });

  factory PersonalizationModel.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    if (json['subscriptionStartDate'] != null) {
      if (json['subscriptionStartDate'] is Timestamp) {
        start = (json['subscriptionStartDate'] as Timestamp).toDate().toLocal();
      } else if (json['subscriptionStartDate'] is String) {
        start = DateTime.tryParse(json['subscriptionStartDate'])?.toLocal();
      }
    }
    return PersonalizationModel(
      activeAppIcon: json['activeAppIcon'] ?? 'icon_default',
      activeProfileFrame: json['activeProfileFrame'] ?? 'none',
      activeBadge: json['activeBadge'] ?? 'none',
      subscriptionStartDate: start,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeAppIcon': activeAppIcon,
      'activeProfileFrame': activeProfileFrame,
      'activeBadge': activeBadge,
      'subscriptionStartDate': subscriptionStartDate?.toUtc().toIso8601String(),
    };
  }
}
