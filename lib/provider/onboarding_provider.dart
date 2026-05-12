import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const String _stepKey = 'onboarding_step';
  static const String _completedKey = 'onboarding_completed';
  static const String _vibesKey = 'selected_vibes';

  int currentStep = 0;
  bool isCompleted = false;
  bool isStateLoaded = false;
  List<String> selectedVibes = [];

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    isCompleted = prefs.getBool(_completedKey) ?? false;
    currentStep = prefs.getInt(_stepKey) ?? 0;
    final vibesJson = prefs.getString(_vibesKey);
    if (vibesJson != null) {
      selectedVibes = List<String>.from(jsonDecode(vibesJson) as List);
    }
    isStateLoaded = true;
    notifyListeners();
  }

  Future<void> saveStep(int step) async {
    currentStep = step;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey, step);
    notifyListeners();
  }

  Future<void> saveVibes(List<String> vibes) async {
    selectedVibes = vibes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vibesKey, jsonEncode(vibes));
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    isCompleted = true;
    currentStep = 4;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.setInt(_stepKey, 4);
    notifyListeners();
  }
}
