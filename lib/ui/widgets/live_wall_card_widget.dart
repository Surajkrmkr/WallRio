import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LiveWallCard extends StatelessWidget {
  final LiveWallpaper wall;
  final VoidCallback onTap;
  final double radius;

  const LiveWallCard({
    super.key,
    required this.wall,
    required this.onTap,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CNImage(imageUrl: wall.thumbnail),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: blackColor.withValues(alpha: 0.3),
            ),
          ),
          _buildLiveBadge(),
          VerifyIconWidget(visibility: !wall.isPremium),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/Live.svg',
                  height: 11,
                  colorFilter:
                      const ColorFilter.mode(whiteColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
