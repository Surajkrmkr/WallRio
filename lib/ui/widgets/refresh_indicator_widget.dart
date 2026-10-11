import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';

/// Shared pull-to-refresh used by every scrollable page so the gesture,
/// spinner style and position are identical app-wide.
class RefreshIndicatorWidget extends StatelessWidget {
  final Widget child;
  // Defaults to reloading the main wallpaper feed.
  final Future<void> Function()? onRefresh;
  const RefreshIndicatorWidget(
      {super.key, required this.child, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        if (onRefresh != null) {
          await onRefresh!();
          return;
        }
        Provider.of<WallRio>(context, listen: false).getListFromAPI(context);
        await Future.delayed(const Duration(seconds: 1));
      },
      backgroundColor: context.appColors.surfaceElevated,
      color: context.appColors.accent,
      strokeWidth: 2.6,
      displacement: 36,
      edgeOffset: MediaQuery.paddingOf(context).top + 56,
      child: child,
    );
  }
}
