import 'package:flutter/material.dart';
import 'package:wallrio/services/theme_data.dart';

/// Empty/error state for the Collections page.
class CollectionEmptyState extends StatelessWidget {
  final String message;
  const CollectionEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fg = isDarkMode ? whiteColor : blackColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgDarkAccentColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.collections_bookmark_rounded,
                size: 38,
                color: bgDarkAccentColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No collections yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
