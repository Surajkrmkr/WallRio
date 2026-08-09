import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
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

  void _onLongPressHandler(BuildContext context, dynamic model) {
    CNBottomSheet.show(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        showDragHandle: Platform.isIOS,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(BuildContext context, dynamic model) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
  }

  List<Walls> _resolveWalls(WallRio provider) {
    List<Walls> fullList;
    if (isActionGrid) {
      fullList = provider.actionWallList;
    } else {
      switch (filterIndex) {
        case 1:
          fullList = provider.originalWallList.where((w) => !w.isPremium).toList();
          break;
        case 2:
          fullList = provider.originalWallList.where((w) => w.isPremium).toList();
          break;
        default:
          fullList = provider.originalWallList;
      }
    }
    if (fullList.length <= provider.visibleCount) return fullList;
    return fullList.sublist(0, provider.visibleCount);
  }

  // Builds grid rows where every element is either a Wall or an 'AD_TILE' marker occupying 1 grid slot
  List<List<dynamic>> _buildItemList(List<Walls> walls, int columnsCount) {
    final allGridItems = <dynamic>[];
    int wallCounter = 0;

    for (int i = 0; i < walls.length; i++) {
      allGridItems.add(walls[i]);
      wallCounter++;

      // Insert 1 native ad tile after every 6 wallpapers
      if (!UserProfile.plusMember && wallCounter == 6 && (i + 1) < walls.length) {
        allGridItems.add('AD_TILE');
        wallCounter = 0;
      }
    }

    final rows = <List<dynamic>>[];
    for (int i = 0; i < allGridItems.length; i += columnsCount) {
      final end = (i + columnsCount).clamp(0, allGridItems.length);
      rows.add(allGridItems.sublist(i, end));
    }
    return rows;
  }

  List<dynamic> _buildFeedItems(List<Walls> walls, int columnsCount) {
    final rows = _buildItemList(walls, columnsCount);
    final feed = <dynamic>[];
    for (int i = 0; i < rows.length; i++) {
      feed.add(rows[i]);
      if (!UserProfile.plusMember && (i + 1) % 4 == 0 && (i + 1) < rows.length) {
        feed.add('INLINE_BANNER_AD');
      }
    }
    return feed;
  }

  @override
  Widget build(BuildContext context) {
    final int columnsCount = ResponsiveHelper.getGridCrossAxisCount(context);

    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 15),
          sliver: SliverGrid.count(
            crossAxisCount: columnsCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.55,
            children: List.generate(
              columnsCount * 3,
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
      final feedItems = _buildFeedItems(walls, columnsCount);
      return SliverPadding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: feedItems.length,
            (context, index) {
              final item = feedItems[index];
              if (item == 'INLINE_BANNER_AD') {
                return const InlineBannerAdWidget();
              }
              final row = item as List<dynamic>;

              // Only apply featured layout for the first row of "All" filter in main grid on phones if all 3 items are Walls
              if (index == 0 && !isActionGrid && filterIndex == 0 && row.length == 3 && row.every((element) => element is Walls) && !ResponsiveHelper.isTablet(context)) {
                return _buildFeaturedRow(row.cast<Walls>(), context);
              }

              return _buildWallRow(row, columnsCount, context);
            },
          ),
        ),
      );
    });
  }

  Widget _buildFeaturedRow(List<Walls> rowWalls, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Large Featured
              Expanded(
                flex: 2,
                child: _buildImgUI(rowWalls[0], context, isFeatured: true, rank: 1),
              ),
              const SizedBox(width: 10),
              // Right: Two Small Featured
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.55,
                        child: _buildImgUI(rowWalls[1], context, isSmallFeatured: true, rank: 2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.55,
                        child: _buildImgUI(rowWalls[2], context, isSmallFeatured: true, rank: 3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWallRow(List<dynamic> rowItems, int columnsCount, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columnsCount; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: i < rowItems.length
                  ? AspectRatio(
                      aspectRatio: 0.55,
                      child: rowItems[i] is Walls
                          ? _buildImgUI(rowItems[i] as Walls, context)
                          : const SponsoredAdCard(),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Hero _buildImgUI(Walls wall, BuildContext context,
      {bool isFeatured = false, bool isSmallFeatured = false, int? rank}) {
    return Hero(
      tag: wall.url,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CNImage(imageUrl: wall.thumbnail),
            // Name Overlay ONLY for top 3 featured items
            if (isFeatured || isSmallFeatured)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(isFeatured ? 16 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    wall.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isFeatured ? 16 : 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Rank Chip
            if (rank != null)
              Positioned(
                top: isFeatured ? 16 : 10,
                left: isFeatured ? 16 : 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: _getRankGradient(rank),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRankIcon(rank),
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rank.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onTapHandler(context, wall),
                onLongPress: () => _onLongPressHandler(context, wall),
                splashColor: blackColor.withValues(alpha: 0.3),
              ),
            ),
            if (!isFeatured && !isSmallFeatured)
              VerifyIconWidget(visibility: !wall.isPremium)
          ],
        ),
      ),
    );
  }

  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events_rounded; // Trophy
    if (rank == 2) return Icons.workspace_premium_rounded; // Medal with star
    return Icons.military_tech_rounded; // Medal/Ribbon
  }

  Gradient _getRankGradient(int rank) {
    if (rank == 1) {
      return const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (rank == 2) {
      return const LinearGradient(
        colors: [Color(0xFFC0C0C0), Color(0xFF808080)], // Silver
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFCD7F32), Color(0xFF8B4513)], // Bronze
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}
