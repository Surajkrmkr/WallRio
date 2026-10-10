import 'dart:async';
import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _filterIndex = 0;
  bool _isPrefetched = false;
  Timer? _popupTimer;
  static bool _hasScheduledPopupThisSession = false;

  static const _filters = ['All', 'Free', 'Pro', 'Live'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _prefetchMedia();
        _schedulePromotionalPopup();
      }
    });
  }

  void _schedulePromotionalPopup() {
    if (_hasScheduledPopupThisSession) return;
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final wallRio = Provider.of<WallRio>(context, listen: false);
      final config = wallRio.popupConfig;
      if (config != null && config.status) {
        _hasScheduledPopupThisSession = true;
        await RemotePopupService.checkAndShowPopup(context, config);
      }
    });
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    _popupTimer = null;
    super.dispose();
  }

  void _prefetchMedia() {
    if (_isPrefetched) return;
    _isPrefetched = true;

    final wallRio = Provider.of<WallRio>(context, listen: false);
    final liveProvider =
        Provider.of<LiveWallpaperProvider>(context, listen: false);

    // 1. Prefetch next 10 wallpaper thumbnails
    final staticWalls = wallRio.originalWallList.take(10);
    for (final wall in staticWalls) {
      if (wall.thumbnail.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(wall.thumbnail),
          context,
          onError: (e, s) => logger
              .w('Error precaching static thumbnail ${wall.thumbnail}: $e'),
        );
      }
    }

    // 2. Prefetch next 2 live thumbnails & 1 preview video
    final liveWalls = liveProvider.wallList.take(2);
    for (final live in liveWalls) {
      if (live.thumbnail.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(live.thumbnail),
          context,
          onError: (e, s) =>
              logger.w('Error precaching live thumbnail ${live.thumbnail}: $e'),
        );
      }
    }
    if (liveWalls.isNotEmpty) {
      final firstLive = liveWalls.first;
      final videoUrl = firstLive.previewVideo.isNotEmpty
          ? firstLive.previewVideo
          : firstLive.videoUrl;
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
              controller: Provider.of<Navigation>(context, listen: false)
                  .tabController(0),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: true,
                    text: "Wall",
                    secondaryText: "Rio",
                    showUserProfileIcon: true,
                    showSaleChip: true),
                SliverToBoxAdapter(child: BannerWidget()),
                SliverToBoxAdapter(child: _buildFilterRow()),
                if (_filterIndex == 0) ...[
                  SliverToBoxAdapter(child: _buildTrendingLiveSection(context)),
                  SliverToBoxAdapter(
                      child: _buildDesktopWallpapersSection(context)),
                  if (AdsConfig.enabled)
                    const SliverToBoxAdapter(
                      child: AdsWidget(
                        clearNavBar: false,
                        bottomPadding: 0,
                        screenName: 'HomePage',
                        placementName: 'DesktopSectionBanner',
                      ),
                    ),
                  SliverToBoxAdapter(
                      child: _buildSectionHeader(context, "Explore Feed",
                          subtitle: "Handpicked walls, live picks mixed in")),
                ],
                if (_filterIndex == 3)
                  const LiveWallsGridSliver()
                else
                  TrendingWallGridWidget(
                      key: ValueKey('home_grid_$_filterIndex'),
                      filterIndex: _filterIndex),
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
                subtitle: "Motion wallpapers everyone's loving",
                onViewAll: () => Provider.of<Navigation>(context, listen: false)
                    .setIndex = 1,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: liveWalls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final wall = liveWalls[index];
                    return SizedBox(
                      width: 112,
                      child: LiveWallCard(
                        wall: wall,
                        onTap: () => Navigator.push(
                          context,
                          WallpaperRoute.pager(
                            items: liveWalls,
                            initial: wall,
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
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                "Desktop Wallpapers",
                subtitle: "Crisp 16:10 picks for your Mac & PC",
                onViewAll: () => Provider.of<Navigation>(context, listen: false)
                    .setIndex = 4,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final wall = displayList[index];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        WallpaperRoute.pager(
                          desktop: true,
                          items: displayList,
                          initial: wall,
                        ),
                      ),
                      child: Container(
                        width: 224,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CNImage(imageUrl: wall.thumbnail),
                              VerifyIconWidget(
                                visibility: !wall.isPremium,
                                padding: 10,
                              ),
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

  Widget _buildSectionHeader(BuildContext context, String title,
      {String? subtitle, VoidCallback? onViewAll}) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onViewAll();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: colors.accent),
                  ],
                ),
              ),
            ),
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
          color: context.appColors.accent,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? whiteColor : const Color(0xFF1C1C1E);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? bgDark2Color : const Color(0xFFF1F1F5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: fg.withValues(alpha: 0.05)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                  -1.0 + _filterIndex * (2.0 / (_filters.length - 1)), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / _filters.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appColors.accent,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(
                _filters.length,
                (i) => Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == _filterIndex) return;
                      HapticFeedback.selectionClick();
                      setState(() => _filterIndex = i);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily: appFontFamily,
                          color: i == _filterIndex
                              ? whiteColor
                              : fg.withValues(alpha: 0.55),
                          fontWeight: i == _filterIndex
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        child: Text(_filters[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
