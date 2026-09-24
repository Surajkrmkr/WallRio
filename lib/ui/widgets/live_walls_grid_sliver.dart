import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/live_detail_page.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LiveWallsGridSliver extends StatelessWidget {
  const LiveWallsGridSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final columnsCount = ResponsiveHelper.getGridCrossAxisCount(context);
    return Consumer<LiveWallpaperProvider>(
      builder: (context, provider, _) {
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
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: provider.getListFromAPI,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.wallList.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Lottie.asset(
                'assets/lottie/empty.json',
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          );
        }

        final feedItems = _buildFeedItems(provider.wallList, columnsCount);
        return SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: feedItems.length,
              (context, index) {
                final item = feedItems[index];
                if (item == 'INLINE_BANNER_AD') {
                  return const InlineBannerAdWidget(
                    screenName: 'LiveWallpapersGrid',
                    placementName: 'GridChunkBanner',
                  );
                }
                return _buildWallRow(item as List<dynamic>, columnsCount, context);
              },
            ),
          ),
        );
      },
    );
  }

  List<List<dynamic>> _buildItemList(List<LiveWallpaper> walls, int columnsCount) {
    final allGridItems = <dynamic>[];
    int wallCounter = 0;

    for (int i = 0; i < walls.length; i++) {
      allGridItems.add(walls[i]);
      wallCounter++;

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

  List<dynamic> _buildFeedItems(List<LiveWallpaper> walls, int columnsCount) {
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
                      child: rowItems[i] is LiveWallpaper
                          ? Hero(
                              tag: 'live_${(rowItems[i] as LiveWallpaper).id}',
                              child: LiveWallCard(
                                wall: rowItems[i] as LiveWallpaper,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LiveDetailPage(wall: rowItems[i] as LiveWallpaper),
                                  ),
                                ),
                              ),
                            )
                          : const SponsoredAdCard(),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}
