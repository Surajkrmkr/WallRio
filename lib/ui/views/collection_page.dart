import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicatorWidget(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                key: const PageStorageKey('collections_scroll'),
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
            const AdsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionUI() {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList(
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

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        sliver: SliverList(
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
