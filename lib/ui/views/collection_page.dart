import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicatorWidget(
        child: CustomScrollView(
          controller:
              Provider.of<Navigation>(context, listen: false).tabController(2),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBarWidget(
              showSaleChip: true,
              showLogo: false,
              showSearchBtn: true,
              text: "Collections",
              secondaryText: "",
              showUserProfileIcon: true,
            ),
            _buildCollectionUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionUI() {
    return Consumer<WallRio>(builder: (context, provider, _) {
      final isTablet = ResponsiveHelper.isTablet(context);
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      final int crossAxisCount = isTablet ? (isLandscape ? 4 : 3) : 2;
      const double tileAspect = 0.78;
      final double hPad = isTablet ? 24 : 16;

      if (provider.isLoading) {
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
          sliver: SliverGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: tileAspect,
            children: List.generate(
              crossAxisCount * 3,
              (_) => const ShimmerWidget(
                  height: 100, width: double.infinity, radius: 22),
            ),
          ),
        );
      }
      if (provider.error.isNotEmpty) {
        return SliverFillRemaining(
          child: CollectionEmptyState(message: provider.error),
        );
      }

      final collections = provider.collections;
      if (collections.isEmpty) {
        return const SliverFillRemaining(
          child: CollectionEmptyState(
            message:
                "Check back soon — new premium collections are on the way.",
          ),
        );
      }

      final totalWalls =
          collections.fold<int>(0, (sum, c) => sum + (c.walls?.length ?? 0));

      return SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(
          child: _buildQuickAccessStrip(context, collections),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad + 4, 8, hPad, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'All collections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                const Spacer(),
                Text(
                  '${collections.length} sets · $totalWalls walls',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              hPad, 0, hPad, MediaQuery.paddingOf(context).bottom + 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: tileAspect,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => AppearAnimation(
                child: PremiumCollectionCard(
                  collection: collections[index],
                  onTap: () => _openGrid(context, collections[index]),
                ),
              ),
              childCount: collections.length,
            ),
          ),
        ),
      ]);
    });
  }

  // Story-style row so every collection is visible at a glance.
  Widget _buildQuickAccessStrip(
      BuildContext context, List<Collections> collections) {
    final colors = context.appColors;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: collections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = collections[i];
          final walls = c.walls ?? const [];
          return GestureDetector(
            onTap: () => _openGrid(context, c),
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.accent, colors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: ClipOval(
                        child: walls.isNotEmpty
                            ? CNImage(imageUrl: walls.first.thumbnail)
                            : ColoredBox(color: colors.card),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGrid(BuildContext context, Collections collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GridPage(
          categoryName: collection.name,
          walls: collection.walls ?? [],
          collection: collection,
        ),
      ),
    );
  }
}
