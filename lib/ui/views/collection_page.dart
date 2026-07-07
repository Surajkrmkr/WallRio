import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicatorWidget(
        child: Column(
          children: [
            Expanded(
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
                  _buildCollectionUI(isDarkMode),
                ],
              ),
            ),
            const AdsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionUI(bool isDarkMode) {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 3,
              (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: ShimmerWidget(height: 300, width: double.infinity, radius: 40),
              ),
            ),
          ),
        );
      }
      if (provider.error.isNotEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Text(
              provider.error, 
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        );
      }

      final collections = provider.collections;
      if (collections.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Text(
              "No collections found", 
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        );
      }

      // Pre-calculate rows to avoid O(n^2) in build
      final rows = <Widget>[];
      int currentItem = 0;
      int rowIndex = 0;
      
      while (currentItem < collections.length) {
        if (rowIndex == 0) {
          // Row 1: Large Landscape Cinematic
          final collection = collections[currentItem];
          rows.add(
            CollectionCard(
              collection: collection,
              type: CollectionCardType.landscapeCinematic,
              onTap: () => _navigateToGrid(context, collection),
            ),
          );
          currentItem += 1;
        } else if (rowIndex == 1) {
          // Row 2: Medium Square (2 per row)
          rows.add(_buildMediumSquareRow(context, currentItem, collections));
          currentItem += 2;
        } else {
          // All subsequent rows: Tall Vertical (2 per row)
          rows.add(_buildTallVerticalRow(context, currentItem, collections));
          currentItem += 2;
        }
        rowIndex++;
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => rows[index],
            childCount: rows.length,
          ),
        ),
      );
    });
  }

  Widget _buildMediumSquareRow(BuildContext context, int startIndex, List<Collections> collections) {
    List<Widget> cards = [];
    for (int i = 0; i < 2 && (startIndex + i) < collections.length; i++) {
      final collection = collections[startIndex + i];
      cards.add(
        Expanded(
          child: CollectionCard(
            collection: collection,
            type: CollectionCardType.mediumSquare,
            onTap: () => _navigateToGrid(context, collection),
          ),
        ),
      );
      if (i == 0 && (startIndex + 1) < collections.length) {
        cards.add(const SizedBox(width: 16));
      }
    }
    return Row(children: cards);
  }

  Widget _buildTallVerticalRow(BuildContext context, int startIndex, List<Collections> collections) {
    List<Widget> cards = [];
    for (int i = 0; i < 2 && (startIndex + i) < collections.length; i++) {
      final collection = collections[startIndex + i];
      cards.add(
        Expanded(
          child: CollectionCard(
            collection: collection,
            type: CollectionCardType.tallVertical,
            onTap: () => _navigateToGrid(context, collection),
          ),
        ),
      );
      if (i == 0 && (startIndex + 1) < collections.length) {
        cards.add(const SizedBox(width: 16));
      }
    }
    return Row(children: cards);
  }

  void _navigateToGrid(BuildContext context, Collections collection) {
    _openGrid(context, collection);
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
