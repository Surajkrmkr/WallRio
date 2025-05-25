import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class GridPage extends StatefulWidget {
  final String categoryName;
  final List<Walls?> walls;
  final bool isSearchMode;
  const GridPage(
      {super.key,
      required this.categoryName,
      required this.walls,
      this.isSearchMode = false});

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    textEditingController.text = widget.categoryName;
    super.initState();
  }

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
            builder: (context) => FullImage(wallModel: model)));
  }

  void _cancelSearchBar(BuildContext context) {
    textEditingController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                widget.isSearchMode
                    ? _buildSearchBarUI()
                    : SliverAppBarWidget(
                        showLogo: false,
                        showSearchBtn: false,
                        text: widget.categoryName,
                        showBackBtn: true),
                _buildListUI(context)
              ],
            ),
            const AdsWidget()
          ],
        ),
      ),
    );
  }

  Widget _buildListUI(context) {
    return SliverPadding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
        sliver: Consumer<WallRio>(builder: (context, provider, _) {
          return SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.6),
              delegate: SliverChildBuilderDelegate(
                  childCount: widget.isSearchMode
                      ? provider.queryWallList.length
                      : widget.walls.length, (context, index) {
                final wall = widget.isSearchMode
                    ? provider.queryWallList[index]
                    : widget.walls[index];
                return Hero(
                  tag: wall!.url,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(fit: StackFit.expand, children: [
                      CNImage(imageUrl: wall.thumbnail),
                      Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: () => _onTapHandler(context, wall),
                              onLongPress: () =>
                                  _onLongPressHandler(context, wall),
                              splashColor: blackColor.withOpacity(0.3))),
                      // _buildImgDetailsUI(context, wall),
                      VerifyIconWidget(visibility: !wall.isPremium)
                    ]),
                  ),
                );
              }));
        }));
  }

  Align _buildImgDetailsUI(BuildContext context, Walls wall) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          padding: const EdgeInsets.only(left: 15, right: 5),
          height: 65,
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wall.name,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 12),
                    ),
                    Text(
                      "Designed by ${wall.author}",
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
              _buildFavIcon(wall)
            ],
          ),
        ));
  }

  Consumer<FavouriteProvider> _buildFavIcon(Walls wall) {
    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      final bool isFav = provider.isSelectedAsFav(wall.url);
      if (provider.isLoading) {
        return _buildFavBtn(
            color: Colors.white,
            iconData: Icons.favorite_border_rounded,
            onTap: () {});
      }
      return _buildFavBtn(
          color: isFav ? Colors.redAccent : Colors.white,
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

  Widget _buildSearchBarUI() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Consumer<WallRio>(builder: (context, provider, _) {
          return TextFormField(
            controller: textEditingController,
            cursorColor: Theme.of(context).primaryColorLight,
            cursorWidth: 3,
            cursorRadius: const Radius.circular(10),
            onTap: () {
              provider.clearSelectedTags();
              scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut);
            },
            onChanged: (query) => provider.onSearchTap(query),
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorLight.withOpacity(0.05),
              hintText: 'Search by wall name, tags, etc',
              hintStyle: const TextStyle(fontSize: 14),
              suffixIcon: IconButton(
                  onPressed: textEditingController.text.isNotEmpty
                      ? () {
                          provider.resetToDefault();
                          _cancelSearchBar(context);
                        }
                      : null,
                  icon: Icon(textEditingController.text.isNotEmpty
                      ? Icons.cancel
                      : Icons.search_rounded)),
              prefixIcon:
                  BackBtnWidget(color: Theme.of(context).primaryColorLight),
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              hoverColor: blackColor.withOpacity(0.05),
              border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(100))),
            ),
          );
        }),
      ),
    );
  }
}
