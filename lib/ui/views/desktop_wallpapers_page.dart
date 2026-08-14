import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

/// Premium Desktop Wallpapers Gallery matching the clean visual language of the Dynamic tab.
class DesktopWallpapersPage extends StatefulWidget {
  final List<Walls>? initialWalls;
  const DesktopWallpapersPage({super.key, this.initialWalls});

  @override
  State<DesktopWallpapersPage> createState() => _DesktopWallpapersPageState();
}

class _DesktopWallpapersPageState extends State<DesktopWallpapersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WallRio>(context, listen: false).fetchDesktopWallpapers();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        Provider.of<WallRio>(context, listen: false).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onLongPressHandler(BuildContext context, Walls model) {
    CNBottomSheet.show(
      context: context,
      enableDrag: true,
      isScrollControlled: true,
      isDismissible: true,
      showDragHandle: Platform.isIOS,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => ImageBottomSheet(wallModel: model),
    );
  }

  void _onTapHandler(BuildContext context, Walls model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesktopWallpaperDetailPage(wallModel: model),
      ),
    );
  }

  List<Walls> _getDesktopWalls(WallRio provider) {
    return provider.desktopWallList;
  }

  /// Groups wallpapers and native ads (every 8 wallpapers) into 2-column rows,
  /// and inserts inline banner ads after every 4 completed rows.
  List<dynamic> _buildFeedItems(List<Walls> walls, int columnsCount) {
    final allGridItems = <dynamic>[];
    int wallCounter = 0;

    for (int i = 0; i < walls.length; i++) {
      allGridItems.add(walls[i]);
      wallCounter++;

      // Insert 1 native ad tile after every 8 desktop wallpapers
      if (!UserProfile.plusMember && wallCounter == 8 && (i + 1) < walls.length) {
        allGridItems.add('AD_TILE');
        wallCounter = 0;
      }
    }

    final rows = <List<dynamic>>[];
    for (int i = 0; i < allGridItems.length; i += columnsCount) {
      final end = (i + columnsCount).clamp(0, allGridItems.length);
      rows.add(allGridItems.sublist(i, end));
    }

    final feed = <dynamic>[];
    for (int i = 0; i < rows.length; i++) {
      feed.add(rows[i]);
      // Insert 1 banner ad after every 4 completed rows
      if (!UserProfile.plusMember && (i + 1) % 4 == 0 && (i + 1) < rows.length) {
        feed.add('INLINE_BANNER_AD');
      }
    }

    return feed;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const int columnsCount = 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar matching the Dynamic Tab
            const SliverAppBarWidget(
              showLogo: false,
              showSearchBtn: true,
              text: 'Desktop',
              secondaryText: '',
              showBackBtn: true,
              userProfileIconRight: false,
              showUserProfileIcon: false,
            ),
            Consumer<WallRio>(builder: (context, provider, _) {
              if (provider.isLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverGrid.count(
                    crossAxisCount: columnsCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 16 / 10,
                    children: List.generate(
                      columnsCount * 3,
                      (_) => const ShimmerWidget(
                        height: 110,
                        width: double.infinity,
                        radius: 22,
                      ),
                    ),
                  ),
                );
              }

              final walls = _getDesktopWalls(provider);
              final pagedWalls = walls.length > provider.visibleCount
                  ? walls.sublist(0, provider.visibleCount)
                  : walls;

              if (pagedWalls.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/empty.json',
                      width: MediaQuery.of(context).size.width * 0.7,
                    ),
                  ),
                );
              }

              final feedItems = _buildFeedItems(pagedWalls, columnsCount);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: feedItems.length,
                    (context, index) {
                      final item = feedItems[index];
                      if (item == 'INLINE_BANNER_AD') {
                        return const InlineBannerAdWidget(
                          verticalPadding: 12.0,
                          screenName: 'DesktopWallpapersPage',
                          placementName: 'GridChunkBanner',
                        );
                      }
                      return _buildDesktopRow(
                        item as List<dynamic>,
                        columnsCount,
                        context,
                        isDarkMode,
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRow(
    List<dynamic> rowItems,
    int columnsCount,
    BuildContext context,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columnsCount; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: i < rowItems.length
                  ? AspectRatio(
                      aspectRatio: 16 / 10,
                      child: rowItems[i] is Walls
                          ? _buildDesktopCard(
                              rowItems[i] as Walls, context, isDarkMode)
                          : const SponsoredAdCard(borderRadius: 22.0),
                    )
                  : const IgnorePointer(
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: SizedBox.shrink(),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopCard(Walls wall, BuildContext context, bool isDarkMode) {
    return Hero(
      tag: 'desktop_${wall.url}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.28 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dominant 16:10 Landscape Wallpaper Image (100% Clean Visual Focus)
              CNImage(imageUrl: wall.thumbnail),

              // 2. Top-Left: Standard Pro Diamond Icon (VerifyIconWidget)
              VerifyIconWidget(
                visibility: !wall.isPremium,
                padding: 10,
              ),

              // 3. Interactive Touch Layer
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTapHandler(context, wall),
                  onLongPress: () => _onLongPressHandler(context, wall),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
