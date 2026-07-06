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
    return PersonalizationModel(
      activeAppIcon: json['activeAppIcon'] ?? 'icon_default',
      activeProfileFrame: json['activeProfileFrame'] ?? 'none',
      activeBadge: json['activeBadge'] ?? 'none',
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? (json['subscriptionStartDate'] as Timestamp).toDate().toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeAppIcon': activeAppIcon,
      'activeProfileFrame': activeProfileFrame,
      'activeBadge': activeBadge,
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!.toUtc()) : null,
    };
  }
}
