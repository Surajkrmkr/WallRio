import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';

import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';


class WallRio extends ChangeNotifier {
  List<Walls> originalWallList = [];
  List<Walls> actionWallList = [];
  List<Walls> queryWallList = [];
  List<Banners> bannerList = [];
  List<Collections> collections = [];
  List<SubscriptionPlan> subscriptionPlans = [];
  Search search = const Search();
  List<Color> colors = [];

  Map<String, List<Walls?>>? categories = <String, List<Walls?>>{};
  Tag tag = Tag(selectedTags: [], unSelectedTags: []);

  String error = "";
  String currentVersion = "1.0.0";
  bool isLoading = false;
  String _activeQuery = '';

  int visibleCount = 21;
  bool _isLoadingMore = false;

  void resetPagination() {
    visibleCount = 21;
    notifyListeners();
  }

  void loadMore() async {
    if (_isLoadingMore) return;
    
    // Safety check - we check originalWallList length, but actual length depends on current filter
    // We will just increase it always, sublist will handle the overflow gracefully.
    
    _isLoadingMore = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    visibleCount += 21;
    _isLoadingMore = false;
    notifyListeners();
  }


  int bannerIndex = 0;

  set setBannerIndex(int index) {
    bannerIndex = index;
    notifyListeners();
  }

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setCurrentVersion(String version) {
    currentVersion = version;
    notifyListeners();
  }

  set setWallList(List<Walls> list) {
    originalWallList = list;
    notifyListeners();
  }

  set setBannerList(List<Banners> list) {
    bannerList = list;
    notifyListeners();
  }

  set setSubscriptionPlans(List<SubscriptionPlan> plans) {
    subscriptionPlans = plans;
    notifyListeners();
  }

  set setCollections(List<Collections> list) {
    collections = list;
    notifyListeners();
  }

  set setActionWallList(List<Walls> list) {
    actionWallList
      ..clear()
      ..addAll(list);
    // actionWallList.shuffle();
    notifyListeners();
  }

  set setQueryWallList(List<Walls> list) {
    queryWallList
      ..clear()
      ..addAll(list);
    // actionWallList.shuffle();
    notifyListeners();
  }

  set setSearchData(Search data) {
    search = data;
    notifyListeners();
  }

  set setColorData(List<Color> data) {
    colors = data;
    notifyListeners();
  }

  set setError(String msg) {
    error = msg;
    notifyListeners();
  }

  void clearSelectedTags() {
    for (String eachTag in tag.selectedTags) {
      tag.unSelectedTags.insert(0, eachTag);
    }
    tag.selectedTags.clear();
    notifyListeners();
  }

  Future<void> getCurrentVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    setCurrentVersion = version;
  }

  void getListFromAPI(BuildContext context) async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    setIsLoading = true;
    await getCurrentVersion();
    setWallList = [];
    setActionWallList = [];
    setBannerList = [];
    setCollections = [];
    setSearchData = const Search();
    WallRioModel model = await ApiServices.getData();
    if (model.error.isEmpty) {
      setWallList = model.walls;
      setBannerList = model.banners;

      for (var collection in model.collection.collections) {
        final name = collection.name.toLowerCase();
        if (name.contains('wild wonders') || name.contains('wildwonders')) {
          collection.productId = 'com.wallrio.collection.wildwonders';
        } else if (name.contains('christmas')) {
          collection.productId = 'com.wallrio.collection.christmas';
        } else if (name.contains('solitary')) {
          collection.productId = 'com.wallrio.collection.solitary';
        }
      }

      setCollections = model.collection.collections;
      
      subProvider.addCollectionProductIds(model.collection.collections.map((c) => c.productId).toList());
      
      setSearchData = model.search;
      setSubscriptionPlans = model.subscriptionPlans;
      setActionWallList =
          getFilteredWallList(model.walls, search.tags, search.categories);
      resetPagination();
      onSearchTap(_activeQuery);
      _buildCategoryAndTags();
    } else {
      setError = model.error;
    }
    await Future.delayed(const Duration(seconds: 2));
    setIsLoading = false;
  }

  void _buildCategoryAndTags() {
    categories!.clear();
    tag.selectedTags.clear();
    tag.unSelectedTags.clear();
    colors.clear();
    for (Walls? wall in originalWallList) {
      if (!categories!.containsKey(wall!.category)) {
        categories![wall.category] =
            []; // Initiating a Empty list of a category
      }
      for (String? eachTag in wall.tags) {
        if (!tag.unSelectedTags.contains(eachTag)) {
          tag.unSelectedTags.add(eachTag!); // Adding a tag to TagList
        }
      }
      for (Color? color in wall.colorList) {
        if (!colors.contains(color)) {
          colors.add(color!); // Adding a color to colors
        }
      }
      categories![wall.category]!.add(wall); // Adding a Wall to CategoryList
    }
    notifyListeners();
  }

  bool getTagIsSelected(String tagName) {
    return tag.unSelectedTags.contains(tagName) ? false : true;
  }

  // void onSelectedTag(String selectedTag) {
  //   if (tag.unSelectedTags.contains(selectedTag)) {
  //     tag.unSelectedTags.remove(selectedTag);
  //     tag.selectedTags.add(selectedTag);
  //   } else {
  //     tag.selectedTags.remove(selectedTag);
  //     tag.unSelectedTags.insert(0, selectedTag);
  //   }

  //   setActionWallList = getFilteredWallList();
  //   notifyListeners();
  // }

  List<Walls> getWallsByColor(Color color) {
    List<Walls> filteredWall =
        originalWallList.where((wa) => wa.colorList.contains(color)).toList();
    return filteredWall;
  }

  List<Walls> getFilteredWallList(
      List<Walls> orgWalls, List<String> tags, List<String> categories) {
    List<Walls> filteredWall = [];
    for (String tag in tags) {
      final eachTagwall =
          orgWalls.where((wall) => wall.tags.contains(tag)).toList();
      filteredWall.insertAll(0, eachTagwall);
    }
    if (tags.isNotEmpty) return filteredWall;
    for (String category in categories) {
      final eachWall =
          orgWalls.where((wall) => wall.category == category).toList();
      filteredWall.insertAll(0, eachWall);
    }

    return filteredWall;
  }

  void onSearchTap(String query) {
    if (query.isNotEmpty) {
      FirebaseAnalytics.instance
          .logSearch(searchTerm: query);
    }
    _activeQuery = query;
    if (query.isNotEmpty) {
      setQueryWallList = originalWallList
          .where((wall) =>
              wall.name.toLowerCase().contains(query.toLowerCase()) ||
              wall.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } else {
      setQueryWallList = originalWallList;
    }
  }

  void applyVibesFilter(List<String> vibes) {
    if (vibes.isEmpty) {
      setActionWallList =
          getFilteredWallList(originalWallList, search.tags, search.categories);
    } else {
      setActionWallList = getFilteredWallList(originalWallList, [], vibes);
    }
  }

  void resetToDefault() {
    _activeQuery = '';
    resetPagination();
    setQueryWallList = originalWallList;
    clearSelectedTags();
  }
}
