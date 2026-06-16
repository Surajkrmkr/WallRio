import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AutoWallpaperProvider extends ChangeNotifier {
  static const String keyEnabled = 'auto_wall_enabled';
  static const String keyInterval = 'auto_wall_interval';
  static const String keyCategories = 'auto_wall_categories';
  static const String keyCollections = 'auto_wall_collections';
  static const String keyColors = 'auto_wall_colors';
  static const String keyLocation = 'auto_wall_location';
  static const String taskName = 'autoWallpaperChangeTask';

  bool _isEnabled = false;
  int _interval = 60; // default 60 minutes
  List<String> _selectedCategories = [];
  List<String> _selectedCollections = [];
  List<int> _selectedColors = [];
  int _wallLocation = 1; // 1: Home, 2: Lock, 3: Both

  bool get isEnabled => _isEnabled;
  int get interval => _interval;
  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedCollections => _selectedCollections;
  List<int> get selectedColors => _selectedColors;
  int get wallLocation => _wallLocation;

  AutoWallpaperProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(keyEnabled) ?? false;
    _interval = prefs.getInt(keyInterval) ?? 60;
    _selectedCategories = prefs.getStringList(keyCategories) ?? [];
    _selectedCollections = prefs.getStringList(keyCollections) ?? [];
    _selectedColors = (prefs.getStringList(keyColors) ?? []).map((e) => int.parse(e)).toList();
    _wallLocation = prefs.getInt(keyLocation) ?? 1;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyEnabled, value);
    if (value) {
      _scheduleTask();
    } else {
      _cancelTask();
    }
    notifyListeners();
  }

  Future<void> setInterval(int value) async {
    _interval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyInterval, value);
    if (_isEnabled) {
      _scheduleTask();
    }
    notifyListeners();
  }

  Future<void> setLocation(int value) async {
    _wallLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLocation, value);
    notifyListeners();
  }

  Future<void> toggleCategory(String category) async {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyCategories, _selectedCategories);
    notifyListeners();
  }

  Future<void> toggleCollection(String collectionId) async {
    if (_selectedCollections.contains(collectionId)) {
      _selectedCollections.remove(collectionId);
    } else {
      _selectedCollections.add(collectionId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyCollections, _selectedCollections);
    notifyListeners();
  }

  Future<void> toggleColor(int colorValue) async {
    if (_selectedColors.contains(colorValue)) {
      _selectedColors.remove(colorValue);
    } else {
      _selectedColors.add(colorValue);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyColors, _selectedColors.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void _scheduleTask() {
    Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: Duration(minutes: _interval),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  void _cancelTask() {
    Workmanager().cancelByUniqueName("1");
  }

  Future<void> changeWallpaperNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> categories = prefs.getStringList(keyCategories) ?? [];
      final List<String> collections = prefs.getStringList(keyCollections) ?? [];
      final List<String> colorsStr = prefs.getStringList(keyColors) ?? [];
      final List<int> colors = colorsStr.map((e) => int.parse(e)).toList();
      final int location = prefs.getInt(keyLocation) ?? 1;

      final model = await ApiServices.getData();
      if (model.walls.isEmpty) return;

      List<Walls> filteredWalls = model.walls;

      if (categories.isNotEmpty) {
        filteredWalls = filteredWalls.where((w) => categories.contains(w.category)).toList();
      }

      if (collections.isNotEmpty) {
        final collectionWalls = model.collection.collections
            .where((c) => collections.contains(c.name))
            .expand((c) => c.walls ?? [])
            .map((w) => w.url)
            .toSet();
        
        if (collectionWalls.isNotEmpty) {
          filteredWalls = filteredWalls.where((w) => collectionWalls.contains(w.url)).toList();
        }
      }

      if (colors.isNotEmpty) {
         filteredWalls = filteredWalls.where((w) {
           return w.colorList.any((c) => colors.contains(c.value));
         }).toList();
      }

      if (filteredWalls.isEmpty) {
        filteredWalls = model.walls;
      }

      final randomWall = filteredWalls[Random().nextInt(filteredWalls.length)];
      final file = await DefaultCacheManager().getSingleFile(randomWall.url);
      await WallpaperManagerPlus().setWallpaper(file, location);
    } catch (e) {
      debugPrint("Manual wallpaper change failed: $e");
    }
  }

  // This function will be called by Workmanager
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final bool isEnabled = prefs.getBool(keyEnabled) ?? false;
        if (!isEnabled) return Future.value(true);

        final List<String> categories = prefs.getStringList(keyCategories) ?? [];
        final List<String> collections = prefs.getStringList(keyCollections) ?? [];
        final List<String> colorsStr = prefs.getStringList(keyColors) ?? [];
        final List<int> colors = colorsStr.map((e) => int.parse(e)).toList();
        final int location = prefs.getInt(keyLocation) ?? 1;

        final model = await ApiServices.getData();
        if (model.walls.isEmpty) return Future.value(false);

        List<Walls> filteredWalls = model.walls;

        if (categories.isNotEmpty) {
          filteredWalls = filteredWalls.where((w) => categories.contains(w.category)).toList();
        }

        if (collections.isNotEmpty) {
          // Find walls in these collections
          final collectionWalls = model.collection.collections
              .where((c) => collections.contains(c.name)) // Use name or ID? model shows name is used as identifier in toggle
              .expand((c) => c.walls ?? [])
              .map((w) => w.url)
              .toSet();
          
          if (collectionWalls.isNotEmpty) {
            filteredWalls = filteredWalls.where((w) => collectionWalls.contains(w.url)).toList();
          }
        }

        if (colors.isNotEmpty) {
           filteredWalls = filteredWalls.where((w) {
             return w.colorList.any((c) => colors.contains(c.value));
           }).toList();
        }

        if (filteredWalls.isEmpty) {
          filteredWalls = model.walls; // fallback to all walls if filters return nothing
        }

        final randomWall = filteredWalls[Random().nextInt(filteredWalls.length)];
        final file = await DefaultCacheManager().getSingleFile(randomWall.url);
        await WallpaperManagerPlus().setWallpaper(file, location);
        
        return Future.value(true);
      } catch (e) {
        return Future.value(false);
      }
    });
  }
}
