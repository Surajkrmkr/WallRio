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
          primary: false,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverAppBarWidget(
              showLogo: false,
              showSearchBtn: true,
              text: "Collections",
              secondaryText: "",
              userProfileIconRight: false,
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
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: isTablet
              ? SliverGrid.count(
                  crossAxisCount: isLandscape ? 3 : 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: isLandscape ? 1.05 : 0.95,
                  children: List.generate(
                    4,
                    (_) => const CollectionLoadingSkeleton(),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: 3,
                    (context, index) => const CollectionLoadingSkeleton(),
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
            message: "Check back soon — new premium collections are on the way.",
          ),
        );
      }

      final int crossAxisCount = isLandscape ? 3 : 2;

      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 20,
          8,
          isTablet ? 24 : 20,
          24,
        ),
        sliver: isTablet
            ? SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: isLandscape ? 1.02 : 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PremiumCollectionCard(
                    collection: collections[index],
                    onTap: () => _openGrid(context, collections[index]),
                  ),
                  childCount: collections.length,
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PremiumCollectionCard(
                    collection: collections[index],
                    onTap: () => _openGrid(context, collections[index]),
                  ),
                  childCount: collections.length,
                ),
              ),
      );
    });
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
