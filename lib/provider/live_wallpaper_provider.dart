import 'package:flutter/material.dart';
import 'package:wallrio/model/live_wallpaper_model.dart';
import 'package:wallrio/services/live_wallpaper_service.dart';

class LiveWallpaperProvider extends ChangeNotifier {
  List<LiveWallpaper> _wallList = [];
  bool isLoading = false;
  String error = '';
  bool _isDataLoaded = false;

  List<LiveWallpaper> get wallList => _wallList;

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setError(String msg) {
    error = msg;
    notifyListeners();
  }

  set setWallList(List<LiveWallpaper> list) {
    _wallList = list;
    notifyListeners();
  }

  Future<void> getListFromAPI() async {
    if (_isDataLoaded) return;
    setIsLoading = true;
    setWallList = [];
    error = '';

    final model = await LiveWallpaperService.getData();
    if (model.error.isEmpty) {
      setWallList = model.walls;
      _isDataLoaded = true;
    } else {
      setError = model.error;
    }
    await Future.delayed(const Duration(seconds: 2));
    setIsLoading = false;
  }
}
