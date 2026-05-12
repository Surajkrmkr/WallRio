import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class TrendingWallGridWidget extends StatelessWidget {
  final bool isShuffled;
  final bool isActionGrid;
  // 0 = All, 1 = Free, 2 = Pro (only used when isActionGrid is false)
  final int filterIndex;
  const TrendingWallGridWidget(
      {super.key,
      this.isShuffled = false,
      this.isActionGrid = false,
      this.filterIndex = 0});

  void _onLongPressHandler(context, model) {
    showModalBottomSheet(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(context, model) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
  }

  List<Walls> _resolveWalls(WallRio provider) {
    if (isActionGrid) return provider.actionWallList;
    switch (filterIndex) {
      case 1:
        return provider.originalWallList.where((w) => !w.isPremium).toList();
      case 2:
        return provider.originalWallList.where((w) => w.isPremium).toList();
      default:
        return provider.originalWallList;
    }
  }

  // Returns a list where each element is either List<Walls> (a row) or true (ad marker).
  List<dynamic> _buildItemList(List<Walls> walls) {
    final items = <dynamic>[];
    int wallIndex = 0;
    int rowCount = 0;
    while (wallIndex < walls.length) {
      final end = (wallIndex + 3).clamp(0, walls.length);
      items.add(walls.sublist(wallIndex, end));
      wallIndex += 3;
      rowCount++;
      // Insert ad after every 3 rows (9 walls), but not at the very end
      if (rowCount % 3 == 0 && wallIndex < walls.length) {
        items.add(true);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 15),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.5,
            children: List.generate(
              9,
              (_) => const ShimmerWidget(
                  height: 100, width: double.infinity, radius: 16),
            ),
          ),
        );
      }
      if (provider.error.isNotEmpty) {
        return SliverFillRemaining(child: Center(child: Text(provider.error)));
      }
      final walls = _resolveWalls(provider);
      if (walls.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Lottie.asset('assets/lottie/empty.json',
                width: MediaQuery.of(context).size.width * 0.7),
          ),
        );
      }
      final items = _buildItemList(walls);
      return SliverPadding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: items.length,
            (context, index) {
              final item = items[index];
              if (item is bool) return _buildAdRow();
              return _buildWallRow(item as List<Walls>, context);
            },
          ),
        ),
      );
    });
  }

  Widget _buildWallRow(List<Walls> rowWalls, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: i < rowWalls.length
                  ? AspectRatio(
                      aspectRatio: 0.5,
                      child: _buildImgUI(rowWalls[i], context),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: AdsWidget(size: AdSize.mediumRectangle),
      ),
    );
  }

  Hero _buildImgUI(Walls wall, BuildContext context) {
    return Hero(
      tag: wall.url,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          CNImage(imageUrl: wall.thumbnail),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onTapHandler(context, wall),
              onLongPress: () => _onLongPressHandler(context, wall),
              splashColor: blackColor.withValues(alpha: 0.3),
            ),
          ),
          VerifyIconWidget(visibility: !wall.isPremium)
        ]),
      ),
    );
  }
}
