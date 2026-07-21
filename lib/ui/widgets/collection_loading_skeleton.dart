import 'package:flutter/material.dart';
import 'package:wallrio/ui/widgets/shimmer_widget.dart';

/// Shimmer placeholder mirroring the shape of [PremiumCollectionCard] while
/// collections are loading.
class CollectionLoadingSkeleton extends StatelessWidget {
  const CollectionLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget(height: 300, width: double.infinity, radius: 22),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget(height: 18, width: 160, radius: 6),
                const SizedBox(height: 8),
                const ShimmerWidget(height: 12, width: 100, radius: 6),
                const SizedBox(height: 6),
                const ShimmerWidget(height: 11, width: 90, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
