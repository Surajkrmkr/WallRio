import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';

import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

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
          builder: (context) => DesktopWallpaperDetailPage(wallModel: model)),
    );
  }

  List<Walls> _getDesktopWalls(WallRio provider) {
    return provider.desktopWallList;
  }

  String _getResolutionLabel(Walls wall) {
    final lowerTags = wall.tags.map((t) => t.toLowerCase()).toList();
    final lowerName = wall.name.toLowerCase();
    if (lowerTags.any((t) => t.contains('8k')) || lowerName.contains('8k')) {
      return '8K';
    }
    if (lowerTags.any((t) => t.contains('5k')) || lowerName.contains('5k')) {
      return '5K';
    }
    return '4K';
  }

  // Groups wallpapers and native ads (every 8 wallpapers) into 2-column rows, and inserts inline banner ads after every 4 completed rows
  List<dynamic> _buildFeedItems(List<Walls> walls, int columnsCount) {
    final allGridItems = <dynamic>[];
    int wallCounter = 0;

    for (int i = 0; i < walls.length; i++) {
      allGridItems.add(walls[i]);
      wallCounter++;

      // Insert 1 native ad tile after every 8 desktop wallpapers
      if (wallCounter == 8 && (i + 1) < walls.length) {
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
      if ((i + 1) % 4 == 0 && (i + 1) < rows.length) {
        feed.add('INLINE_BANNER_AD');
      }
    }

    return feed;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 2-column landscape grid for wide desktop preview cards
    final int columnsCount = 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildMinimalHeader(context, isDarkMode),
            Consumer<WallRio>(builder: (context, provider, _) {
              if (provider.isLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverGrid.count(
                    crossAxisCount: columnsCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 16 / 9,
                    children: List.generate(
                      columnsCount * 3,
                      (_) => const ShimmerWidget(
                        height: 120,
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: feedItems.length,
                    (context, index) {
                      final item = feedItems[index];
                      if (item == 'INLINE_BANNER_AD') {
                        return const InlineBannerAdWidget(verticalPadding: 12.0);
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

  // Minimal Header: Back button, Desktop Wallpapers title, Search icon, and small subtitle
  Widget _buildMinimalHeader(BuildContext context, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackBtnWidget(color: isDarkMode ? Colors.white : Colors.black),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GridPage(
                          categoryName: "Desktop Wallpapers",
                          walls: [],
                          isSearchMode: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Desktop Wallpapers",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "4K & 8K wallpapers for monitors and laptops",
              style: TextStyle(
                fontSize: 13,
                color: (isDarkMode ? Colors.white : Colors.black)
                    .withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
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
                      aspectRatio: 16 / 9,
                      child: rowItems[i] is Walls
                          ? _buildDesktopCard(
                              rowItems[i] as Walls, context, isDarkMode)
                          : const SponsoredAdCard(),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopCard(Walls wall, BuildContext context, bool isDarkMode) {
    final resolution = _getResolutionLabel(wall);

    return Hero(
      tag: 'desktop_${wall.url}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Large landscape wallpaper preview
              CNImage(imageUrl: wall.thumbnail),
              // Subtle gradient overlay for typography contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.70),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              // Small "Desktop" badge top-right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.desktop_windows_rounded,
                          color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text(
                        'DESKTOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Premium badge top-right (if applicable)
              VerifyIconWidget(visibility: !wall.isPremium),
              // Wallpaper title & resolution label bottom-left
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        wall.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        resolution,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTapHandler(context, wall),
                  onLongPress: () => _onLongPressHandler(context, wall),
                  splashColor: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
