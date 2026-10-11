import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';
import 'package:wallrio/services/export.dart';

/// Compact collection tile: static 3-image mosaic with name, count and
/// access badge. Purchase flow still lives in GridPage/CollectionUnlockSheet.
class PremiumCollectionCard extends StatelessWidget {
  final Collections collection;
  final VoidCallback onTap;

  const PremiumCollectionCard(
      {super.key, required this.collection, required this.onTap});

  bool _hasAccessToCollection(BuildContext context) {
    if (UserProfile.hasCollectionAccess) return true;
    final progression = Provider.of<ProgressionProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isRedeemed = progression.isCollectionUnlocked(collection.productId);
    final shortId = collection.productId.split('.').last;
    final isPurchased =
        subProvider.purchasedCollections.contains(collection.productId) ||
            subProvider.purchasedCollections.contains(shortId);
    return isRedeemed || isPurchased;
  }

  String? _unlockPrice(BuildContext context, {bool listen = true}) {
    final subProvider =
        Provider.of<SubscriptionProvider>(context, listen: listen);
    final String shortId = collection.productId.split('.').last;
    final fullProductId =
        collection.productId.startsWith('com.wallrio.collection.')
            ? collection.productId
            : 'com.wallrio.collection.${collection.productId}';
    final product = subProvider.products.cast<dynamic>().firstWhere(
        (p) =>
            p != null &&
            (p.id == fullProductId ||
                p.id == shortId ||
                p.id.endsWith(shortId)),
        orElse: () => null);
    return product?.price;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasAccess = _hasAccessToCollection(context);
    final unlockPrice = hasAccess ? null : _unlockPrice(context);
    final walls = collection.walls ?? [];
    final fg = isDarkMode ? whiteColor : blackColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: fg.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMosaic(walls)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${walls.length} wallpapers',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: fg.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (hasAccess)
                    _buildUnlockedBadge(context, isDarkMode)
                  else
                    GestureDetector(
                      onTap: () {
                        final subProvider = Provider.of<SubscriptionProvider>(
                            context,
                            listen: false);
                        subProvider.buyProductById(collection.productId);
                      },
                      child: _buildBadge(context, unlockPrice ?? 'Unlock'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static 3-image mosaic: one tall preview plus two stacked thumbnails.
  Widget _buildMosaic(List<Walls> walls) {
    Widget tile(int i) => i < walls.length
        ? CNImage(imageUrl: walls[i].thumbnail)
        : const ColoredBox(color: Color(0x14808080));
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: tile(0)),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(1)),
                const SizedBox(height: 3),
                Expanded(child: tile(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedBadge(BuildContext context, bool isDarkMode) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: context.appColors.accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child:
          Icon(Icons.check_rounded, color: context.appColors.accent, size: 16),
    );
  }

  Widget _buildBadge(BuildContext context, String unlockPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.appColors.accent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.black, size: 11),
          const SizedBox(width: 3),
          Text(
            unlockPrice,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 10.5,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
