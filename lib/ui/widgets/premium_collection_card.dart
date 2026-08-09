import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/scrollable_wallpaper_stack.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/toast_widget.dart';

/// Premium showcase card for a single collection: a horizontally scrollable
/// wallpaper stack up front, with the collection's name/designer/wallpaper
/// count below. Reuses the existing premium-access check only for the lock
/// badge — unlocking/purchase flow itself is untouched and still lives in
/// GridPage/CollectionUnlockSheet.
class PremiumCollectionCard extends StatelessWidget {
  final Collections collection;
  final VoidCallback onTap;

  const PremiumCollectionCard({super.key, required this.collection, required this.onTap});

  bool _hasAccessToCollection(BuildContext context) {
    if (UserProfile.hasCollectionAccess) return true;
    final progression = Provider.of<ProgressionProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isRedeemed = progression.isCollectionUnlocked(collection.productId);
    final shortId = collection.productId.split('.').last;
    final isPurchased = subProvider.purchasedCollections.contains(collection.productId) ||
        subProvider.purchasedCollections.contains(shortId);
    return isRedeemed || isPurchased;
  }

  String? _unlockPrice(BuildContext context, {bool listen = true}) {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: listen);
    final String shortId = collection.productId.split('.').last;
    final fullProductId = collection.productId.startsWith('com.wallrio.collection.')
        ? collection.productId
        : 'com.wallrio.collection.${collection.productId}';
    final product = subProvider.products
        .cast<dynamic>()
        .firstWhere((p) => p != null && (p.id == fullProductId || p.id == shortId || p.id.endsWith(shortId)), orElse: () => null);
    return product?.price;
  }



  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasAccess = _hasAccessToCollection(context);
    final unlockPrice = hasAccess ? null : _unlockPrice(context);
    final walls = collection.walls ?? [];
    final sheetColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7);
    final double stackHeight = isTablet ? 270.0 : 320.0;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 0 : 28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScrollableWallpaperStack(walls: walls, height: stackHeight),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collection.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode ? whiteColor : blackColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${walls.length} Wallpapers',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (isDarkMode ? whiteColor : blackColor).withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (hasAccess)
                        _buildUnlockedBadge(isDarkMode)
                      else
                        GestureDetector(
                          onTap: () {
                            final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
                            subProvider.buyProductById(collection.productId);
                          },
                          child: _buildBadge(unlockPrice ?? 'Unlock'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedBadge(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgDarkAccentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: bgDarkAccentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: bgDarkAccentColor, size: 14),
          const SizedBox(width: 4),
          Text(
            'Unlocked',
            style: TextStyle(color: bgDarkAccentColor, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String unlockPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgDarkAccentColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: bgDarkAccentColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.black, size: 13),
          const SizedBox(width: 4),
          Text(
            unlockPrice,
            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
