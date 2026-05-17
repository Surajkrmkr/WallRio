import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/live_detail_page.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LiveWallsGridSliver extends StatelessWidget {
  const LiveWallsGridSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveWallpaperProvider>(
      builder: (context, provider, _) {
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

        final items = _buildItemList(provider.wallList);
        return SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: items.length,
              (context, index) {
                final item = items[index];
                if (item is bool) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                        child: AdsWidget(size: AdSize.mediumRectangle)),
                  );
                }
                return _buildWallRow(item as List<LiveWallpaper>, context);
              },
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _buildItemList(List<LiveWallpaper> walls) {
    final items = <dynamic>[];
    int wallIndex = 0;
    int rowCount = 0;
    while (wallIndex < walls.length) {
      final end = (wallIndex + 3).clamp(0, walls.length);
      items.add(walls.sublist(wallIndex, end));
      wallIndex += 3;
      rowCount++;
      if (rowCount % 3 == 0 && wallIndex < walls.length) items.add(true);
    }
    return items;
  }

  Widget _buildWallRow(List<LiveWallpaper> rowWalls, BuildContext context) {
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
                      child: Hero(
                        tag: 'live_${rowWalls[i].id}',
                        child: LiveWallCard(
                          wall: rowWalls[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LiveDetailPage(wall: rowWalls[i]),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}
