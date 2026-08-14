import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class FavouriteProvider extends ChangeNotifier {
  // Map<String, dynamic> favJson = {"walls": []};
  List<Walls> wallList = [];
  final String favouriteFirebasePath = "favourite";
  final String favouriteItemsFirebasePath = "favouriteItems";

  bool isLoading = false;

  set setIsLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  set setWallToList(List<Walls> walls) {
    wallList = walls;
    notifyListeners();
  }

  set addWallToList(Walls wall) {
    wallList.add(wall);
    notifyListeners();
  }

  set removeWallFromList(int id) {
    wallList.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  void clearData() {
    wallList.clear();
    notifyListeners();
  }

  String _getUserDocId() {
    if (UserProfile.email.isNotEmpty) return UserProfile.email;
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) return user.email!;
    if (user?.uid != null && user!.uid.isNotEmpty) return user.uid;
    return '';
  }

  void addToFav(BuildContext context, {required Walls wall}) async {
    if (!wallList.any((w) => w.id == wall.id || w.url == wall.url)) {
      addWallToList = wall;
    }
    ToastWidget.showToast("Added to Favourite");

    final bool isAdded = await saveToFirebase(wall: wall);
    if (isAdded) {
      FirebaseAnalytics.instance.logEvent(
          name: 'wallpaper_added_to_favourite',
          parameters: {'wall_id': wall.id});
          
      // Track progression
      if (!context.mounted) return;
      Provider.of<ProgressionProvider>(context, listen: false).trackAction(ActionType.favorite);
    }
  }

  void removeFromFav({required int id}) async {
    removeWallFromList = id;
    ToastWidget.showToast("Removed from Favourite");

    final bool isRemoved = await removeFromFirebase(id: id);
    if (isRemoved) {
      FirebaseAnalytics.instance.logEvent(
          name: 'wallpaper_removed_from_favourite',
          parameters: {'wall_id': id});
    }
  }

  bool isSelectedAsFav(String url, {int? id}) {
    if (UserProfile.plusMember) {
      final bool isFav = wallList.any((wall) => wall.url == url || (id != null && wall.id == id));
      return isFav;
    }
    return false;
  }

  void getFavouritesFromFirebase() async {
    if (UserProfile.plusMember) {
      final docId = _getUserDocId();
      if (docId.isEmpty) return;
      setIsLoading = true;
      try {
        final DocumentReference<Map<String, dynamic>> favourite =
            FirebaseFirestore.instance
                .collection(favouriteFirebasePath)
                .doc(docId);
        final QuerySnapshot<Map<String, dynamic>> querySnapshot = await favourite
            .collection(favouriteItemsFirebasePath)
            .orderBy('createdAt', descending: false)
            .get();
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> list =
            querySnapshot.docs;
        final Map<String, dynamic> favJson = {
          "walls": list.map((e) => e.data()).toList()
        };

        setWallToList = WallRioModel.fromJson(favJson).walls;
      } catch (error) {
        logger.e(error);
      } finally {
        setIsLoading = false;
      }
    }
  }

  Future<bool> saveToFirebase({required Walls wall}) async {
    if (UserProfile.plusMember) {
      final docId = _getUserDocId();
      if (docId.isEmpty) return false;
      bool isSuccessfullyAdded = false;
      try {
        final DocumentReference<Map<String, dynamic>> favouriteDocument =
            FirebaseFirestore.instance
                .collection(favouriteFirebasePath)
                .doc(docId);
        await favouriteDocument
            .collection(favouriteItemsFirebasePath)
            .doc(wall.id.toString())
            .set({...Walls.toJson(wall), "createdAt": Timestamp.now()});
        isSuccessfullyAdded = true;
      } catch (error) {
        logger.e(error);
      }
      return isSuccessfullyAdded;
    }
    return false;
  }

  Future<bool> removeFromFirebase({required int id}) async {
    if (UserProfile.plusMember) {
      final docId = _getUserDocId();
      if (docId.isEmpty) return false;
      bool isSuccessfullyRemoved = false;
      try {
        final DocumentReference<Map<String, dynamic>> favouriteDocument =
            FirebaseFirestore.instance
                .collection(favouriteFirebasePath)
                .doc(docId);
        await favouriteDocument
            .collection(favouriteItemsFirebasePath)
            .doc(id.toString())
            .delete();
        isSuccessfullyRemoved = true;
      } catch (error) {
        logger.e(error);
      }
      return isSuccessfullyRemoved;
    }
    return false;
  }
}
