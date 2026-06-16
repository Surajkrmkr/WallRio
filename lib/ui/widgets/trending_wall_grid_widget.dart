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
              
              // Only apply featured layout for the first row of "All" filter in main grid
              if (index == 0 && !isActionGrid && filterIndex == 0 && (item as List<Walls>).length == 3) {
                return _buildFeaturedRow(item, context);
              }
              
              return _buildWallRow(item as List<Walls>, context);
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
              // Right: Two Small Featured (Matching standard grid items)
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
                      aspectRatio: 0.55,
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
                        Colors.black.withOpacity(0.7),
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
                        color: Colors.black.withOpacity(0.3),
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
