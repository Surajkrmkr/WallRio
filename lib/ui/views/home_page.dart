import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _filterIndex = 0;
  bool _isPrefetched = false;

  static const _filters = ['All', 'Free', 'Pro', 'Live'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetchMedia();
    });
  }

  void _prefetchMedia() {
    if (_isPrefetched) return;
    _isPrefetched = true;

    final wallRio = Provider.of<WallRio>(context, listen: false);
    final liveProvider = Provider.of<LiveWallpaperProvider>(context, listen: false);

    // 1. Prefetch next 10 wallpaper thumbnails
    final staticWalls = wallRio.originalWallList.take(10);
    for (final wall in staticWalls) {
      if (wall.thumbnail.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(wall.thumbnail), context);
      }
    }

    // 2. Prefetch next 2 live thumbnails & 1 preview video
    final liveWalls = liveProvider.wallList.take(2);
    for (final live in liveWalls) {
      if (live.thumbnail.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(live.thumbnail), context);
      }
    }
    if (liveWalls.isNotEmpty) {
      final firstLive = liveWalls.first;
      final videoUrl = firstLive.previewVideo.isNotEmpty ? firstLive.previewVideo : firstLive.videoUrl;
      if (videoUrl.isNotEmpty) {
        LivePreviewManager.instance.getController(videoUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicatorWidget(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              primary: false,
              slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: true,
                    text: "Wall",
                    secondaryText: "Rio",
                    userProfileIconRight: false,
                    showUserProfileIcon: true,
                    showSaleChip: true),
                SliverToBoxAdapter(child: BannerWidget()),
                SliverToBoxAdapter(child: _buildFilterRow()),
                if (_filterIndex == 0) ...[
                  SliverToBoxAdapter(child: _buildTrendingLiveSection(context)),
                  SliverToBoxAdapter(child: _buildDesktopWallpapersSection(context)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: AdsWidget(clearNavBar: false, bottomPadding: 0),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildSectionHeader(context, "Explore Feed")),
                ],
                if (_filterIndex == 3)
                  const LiveWallsGridSliver()
                else
                  TrendingWallGridWidget(filterIndex: _filterIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Trending Live Row (Compact horizontal live wallpaper row with preview thumbnails only)
  Widget _buildTrendingLiveSection(BuildContext context) {
    return Consumer<LiveWallpaperProvider>(
      builder: (context, provider, _) {
        if (provider.wallList.isEmpty) return const SizedBox.shrink();
        final liveWalls = provider.wallList.take(10).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                "Trending Live",
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LivePage()),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: liveWalls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final wall = liveWalls[index];
                    return SizedBox(
                      width: 115,
                      child: LiveWallCard(
                        wall: wall,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveDetailPage(wall: wall),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Desktop Wallpapers Section
  Widget _buildDesktopWallpapersSection(BuildContext context) {
    return Consumer<WallRio>(
      builder: (context, provider, _) {
        if (provider.desktopWallList.isEmpty) return const SizedBox.shrink();
        final displayList = provider.desktopWallList;

        return Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                "Desktop Wallpapers",
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DesktopWallpapersPage(
                      initialWalls: displayList,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final wall = displayList[index];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DesktopWallpaperDetailPage(wallModel: wall),
                        ),
                      ),
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CNImage(imageUrl: wall.thumbnail),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text('DESKTOP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                              VerifyIconWidget(visibility: !wall.isPremium),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: bgDarkAccentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          if (onViewAll != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgDarkAccentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: bgDarkAccentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: bgDarkAccentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: bgDarkAccentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    if (Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: CNSegmentedControl(
          labels: _filters,
          selectedIndex: _filterIndex,
          onValueChanged: (i) => setState(() => _filterIndex = i),
          color: bgDarkAccentColor,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgDark2Color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: List.generate(
            _filters.length,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == _filterIndex
                        ? bgDarkAccentColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    _filters[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == _filterIndex
                          ? whiteColor
                          : whiteColor.withValues(alpha: 0.55),
                      fontWeight:
                          i == _filterIndex ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

