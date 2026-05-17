import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LiveWallCard extends StatelessWidget {
  final LiveWallpaper wall;
  final VoidCallback onTap;

  const LiveWallCard({super.key, required this.wall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CNImage(imageUrl: wall.thumbnail),
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
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          'assets/icons/Live.svg',
          height: 16,
          colorFilter: const ColorFilter.mode(whiteColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
