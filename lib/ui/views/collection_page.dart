import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

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
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
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
                _buildCollectionUI()
              ],
            ),
          ),
          const AdsWidget()
        ],
      ),
    );
  }

  Widget _buildCollectionUI() {
    return Consumer<WallRio>(builder: (context, provider, _) {
      return provider.isLoading
          ? SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildShimmerUI(),
            )
          : provider.error.isEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                      childCount: provider.collections.length,
                      (context, index) {
                    final collectionName = provider.collections[index].name;
                    final collectionsWalls = provider.collections[index].walls!;
                    return _buildCollectionItemUI(
                        collectionName,
                        collectionsWalls,
                        context,
                        index,
                        provider.collections.length);
                  }))
              : SliverFillRemaining(
                  child: Center(child: Text(provider.error)));
    });
  }

  Widget _buildCollectionItemUI(String collectionName, List<Walls?> walls,
      BuildContext context, int index, int totalLength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GridPage(
                        categoryName: collectionName,
                        walls: walls,
                      ))),
          child: Padding(
            padding:
                const EdgeInsets.only(right: 20, left: 20, top: 16, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(collectionName,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColorLight
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Text(walls.length.toString(),
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ),
        _CollectionRow(
          walls: walls,
          onTap: (wall) => _onTapHandler(context, wall),
          onLongPress: (wall) => _onLongPressHandler(context, wall),
          onFavTap: (wall, isFav, favProvider) => UserProfile.plusMember
              ? isFav
                  ? favProvider.removeFromFav(id: wall.id)
                  : favProvider.addToFav(wall: wall)
              : _showPlusDialog(context),
        ),
        if (index == totalLength - 1) const SizedBox(height: 20),
      ],
    );
  }

  SliverList _buildShimmerUI() {
    return SliverList(
        delegate: SliverChildBuilderDelegate(childCount: 4, (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const ShimmerWidget(height: 24, width: 150, radius: 8),
            const SizedBox(height: 10),
            SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 16),
                children: const [
                  ShimmerWidget(height: 230, width: 160, radius: 20),
                  SizedBox(width: 10),
                  ShimmerWidget(height: 230, width: 130, radius: 20),
                  SizedBox(width: 10),
                  ShimmerWidget(height: 230, width: 130, radius: 20),
                ],
              ),
            ),
          ],
        ),
      );
    }));
  }
}

class _CollectionRow extends StatefulWidget {
  final List<Walls?> walls;
  final void Function(Walls) onTap;
  final void Function(Walls) onLongPress;
  final void Function(Walls, bool, FavouriteProvider) onFavTap;

  const _CollectionRow({
    required this.walls,
    required this.onTap,
    required this.onLongPress,
    required this.onFavTap,
  });

  @override
  State<_CollectionRow> createState() => _CollectionRowState();
}

class _CollectionRowState extends State<_CollectionRow> {
  late final PageController _controller;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.62);
    _controller.addListener(() {
      setState(() => _currentPage = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.walls.length,
        itemBuilder: (context, index) {
          final distance = (_currentPage - index).abs();
          final scale = (1 - distance * 0.12).clamp(0.82, 1.0);
          final wall = widget.walls[index];
          if (wall == null) return const SizedBox.shrink();

          return Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => widget.onTap(wall),
              onLongPress: () => widget.onLongPress(wall),
              child: Container(
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CNImage(imageUrl: wall.url),
                      _buildImgBottomUI(wall),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImgBottomUI(Walls wall) {
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
        child: Consumer<FavouriteProvider>(builder: (context, favProvider, _) {
          final bool isFav = favProvider.isSelectedAsFav(wall.url);
          return IconButton(
            onPressed: favProvider.isLoading
                ? null
                : () => widget.onFavTap(wall, isFav, favProvider),
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : whiteColor,
            ),
          );
        }),
      ),
    );
  }
}
