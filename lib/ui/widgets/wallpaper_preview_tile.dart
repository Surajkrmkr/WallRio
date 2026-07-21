import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';
import 'package:wallrio/ui/widgets/lockscreen_style.dart';
import 'package:wallrio/ui/widgets/lockscreen_styles.dart';

/// A single wallpaper preview tile used inside [ScrollableWallpaperStack] —
/// the wallpaper image with a decorative, randomly-styled lockscreen overlay
/// on top so it reads like a real lockscreen instead of a plain thumbnail.
class WallpaperPreviewTile extends StatelessWidget {
  final Walls wall;

  const WallpaperPreviewTile({super.key, required this.wall});

  /// Uses the color palette already computed server-side for this wallpaper
  /// (`Walls.colorList`) instead of re-analyzing the image on-device — free,
  /// synchronous, and avoids extra network/decode cost while scrolling.
  static bool _isLightWallpaper(List<Color> colors) {
    if (colors.isEmpty) return false;
    final sample = colors.length > 3 ? colors.sublist(0, 3) : colors;
    final avgLuminance =
        sample.map((c) => c.computeLuminance()).reduce((a, b) => a + b) / sample.length;
    return avgLuminance > 0.55;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLightWallpaper(wall.colorList);
    final style = LockscreenStyleManager.styleForWall(wall.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CNImage(imageUrl: wall.thumbnail),
          // Flat scrim so the lockscreen overlay stays legible on light or
          // busy/high-detail wallpapers, on top of the directional gradient.
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.05)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: LockscreenOverlay(style: style, isLight: isLight),
          ),
        ],
      ),
    );
  }
}
