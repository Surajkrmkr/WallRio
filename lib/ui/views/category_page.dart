import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  void _onLongPressHandler(context, model) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _showPlusDialog(context) {
    showDialog(
        context: context,
        builder: (context) =>
            AdsWidget.getPlusDialog(context, isExplorePlus: true));
  }

  void _onTapHandler(context, model) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ImageViewPage(wallModel: model)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicatorWidget(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: Provider.of<Navigation>(context).controller,
              slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: true,
                    text: "Wall",
                    secondaryText: "Rio",
                    userProfileIconRight: false,
                    showUserProfileIcon: true),
                _buildCategoryUI()
              ],
            ),
          ),
          const AdsWidget()
        ],
      ),
    );
  }

  Widget _buildCategoryUI() {
    return Consumer<WallRio>(builder: (context, provider, _) {
      return provider.isLoading
          ? SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
              sliver: _buildShimmerUI(),
            )
          : provider.error.isEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                      childCount: provider.categories!.length,
                      (context, index) {
                  final categoryName =
                      provider.categories!.keys.elementAt(index);
                  final categoryWalls =
                      provider.categories!.values.elementAt(index);
                  return Column(children: [
                    _buildCategoryHeaderUI(
                        categoryName, categoryWalls, context),
                    _buildListViewUI(categoryWalls),
                    if (index == provider.categories!.length - 1)
                      const SizedBox(height: 20)
                  ]);
                }))
              : SliverFillRemaining(child: Center(child: Text(provider.error)));
    });
  }

  SliverList _buildShimmerUI() {
    return SliverList(
        delegate: SliverChildBuilderDelegate(childCount: 4, (context, index) {
      return Column(
        children: [
          const ShimmerWidget(height: 40, width: double.infinity),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                  6,
                  (index) => const Padding(
                        padding: EdgeInsets.only(right: 10.0),
                        child:
                            ShimmerWidget(height: 200, width: 120, radius: 25),
                      )),
            ),
          ),
          const SizedBox(height: 20)
        ],
      );
    }));
  }

  SizedBox _buildListViewUI(List<Walls?> categoryWalls) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categoryWalls.length < 8 ? categoryWalls.length : 8,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, i) {
            return Hero(
              tag: categoryWalls[i]!.url,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  width: 120,
                  child: Stack(fit: StackFit.expand, children: [
                    CNImage(imageUrl: categoryWalls[i]!.thumbnail),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onTapHandler(context, categoryWalls[i]),
                        onLongPress: () =>
                            _onLongPressHandler(context, categoryWalls[i]),
                        splashColor: blackColor.withOpacity(0.3),
                      ),
                    ),
                    // buildImgBottomUI(categoryWalls[i]!),
                    VerifyIconWidget(visibility: !categoryWalls[i]!.isPremium)
                  ]),
                ),
              ),
            );
          }),
    );
  }

  Widget buildImgBottomUI(Walls wall) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        height: 65,
        padding: const EdgeInsets.only(right: 5, bottom: 5),
        alignment: Alignment.bottomRight,
        child: _buildFavIcon(wall),
      ),
    );
  }

  Consumer<FavouriteProvider> _buildFavIcon(Walls wall) {
    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      final bool isFav = provider.isSelectedAsFav(wall.url);
      if (provider.isLoading) {
        return _buildFavBtn(
            color: whiteColor,
            iconData: Icons.favorite_border_rounded,
            onTap: () {});
      }
      return _buildFavBtn(
          color: isFav ? Colors.redAccent : whiteColor,
          iconData:
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onTap: () => UserProfile.plusMember
              ? isFav
                  ? provider.removeFromFav(id: wall.id)
                  : provider.addToFav(wall: wall)
              : _showPlusDialog(context));
    });
  }

  IconButton _buildFavBtn(
      {required Function() onTap,
      required IconData iconData,
      required Color color}) {
    return IconButton(onPressed: onTap, icon: Icon(iconData, color: color));
  }

  Widget _buildCategoryHeaderUI(
      String categoryName, List<Walls?> walls, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: ListTile(
          title: Row(
            children: [
              Text(categoryName, style: Theme.of(context).textTheme.bodyMedium),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100)),
                padding: EdgeInsets.symmetric(horizontal: 10),
                margin: EdgeInsets.only(left: 10),
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(walls.length.toString(),
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ],
          ),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GridPage(
                        categoryName: categoryName,
                        walls: walls,
                      ))),
          trailing:
              Text("View all", style: Theme.of(context).textTheme.labelLarge)),
    );
  }
}
