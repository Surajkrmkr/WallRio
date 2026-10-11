import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/shimmer_widget.dart';

class MacOSWallpaperCard extends StatefulWidget {
  final Walls wall;
  final VoidCallback onTap;
  final VoidCallback? onSetDesktop;
  final VoidCallback? onDownload;
  final bool isLandscape;

  const MacOSWallpaperCard({
    super.key,
    required this.wall,
    required this.onTap,
    this.onSetDesktop,
    this.onDownload,
    this.isLandscape = true,
  });

  @override
  State<MacOSWallpaperCard> createState() => _MacOSWallpaperCardState();
}

class _MacOSWallpaperCardState extends State<MacOSWallpaperCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hoverAnim = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  String _getQualityBadge(Walls wall) {
    final lowerTags = wall.tags.map((t) => t.toLowerCase()).toList();
    final lowerName = wall.name.toLowerCase();

    if (lowerTags.any((t) => t.contains('8k') || t.contains('7680')) ||
        lowerName.contains('8k') ||
        lowerName.contains('7680')) {
      return '8K';
    }
    if (lowerTags.any((t) => t.contains('5k') || t.contains('5120')) ||
        lowerName.contains('5k') ||
        lowerName.contains('5120')) {
      return '5K';
    }
    if (lowerTags.any((t) => t.contains('4k') || t.contains('3840')) ||
        lowerName.contains('4k') ||
        lowerName.contains('3840')) {
      return '4K';
    }
    return 'HD';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.appColors.accent;
    final qualityBadge = _getQualityBadge(widget.wall);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverAnim,
          builder: (context, child) {
            final scale = 1.0 + _hoverAnim.value * 0.025;
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isHovered
                        ? accent.withValues(alpha: 0.6)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: _isHovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    // Primary shadow
                    BoxShadow(
                      color: _isHovered
                          ? accent.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: _isHovered ? 24 : 8,
                      offset: Offset(0, _isHovered ? 8 : 3),
                    ),
                    // Liquid glow when hovered
                    if (_isHovered)
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Wallpaper image
                      CachedNetworkImage(
                        imageUrl: widget.wall.thumbnail.isNotEmpty
                            ? widget.wall.thumbnail
                            : widget.wall.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ShimmerWidget(
                          height: double.infinity,
                          width: double.infinity,
                          radius: 17,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark
                              ? const Color(0xFF1A1A25)
                              : const Color(0xFFE8EAF0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                  size: 28),
                              const SizedBox(height: 6),
                              Text(
                                "Failed to load",
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top gradient for badge readability
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 65,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Top badges (Quality & Premium)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quality badge with glass
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    qualityBadge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.wall.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFB300),
                                      Color(0xFFFF8F00),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB300)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.diamond_rounded,
                                        color: Colors.white, size: 11),
                                    SizedBox(width: 3),
                                    Text(
                                      "PRO",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Bottom hover action overlay with glassmorphism
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        bottom: _isHovered ? 0 : -90,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Wallpaper name
                                  Text(
                                    widget.wall.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (widget.wall.author.isNotEmpty)
                                    Text(
                                      "by ${widget.wall.author}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  // Action buttons
                                  Row(
                                    children: [
                                      // Set Desktop button
                                      if (Platform.isMacOS)
                                        Expanded(
                                          child: _LiquidActionButton(
                                            label: "Set Desktop",
                                            icon: Icons.desktop_mac_rounded,
                                            accent: accent,
                                            onTap: widget.onSetDesktop,
                                          ),
                                        ),
                                      const SizedBox(width: 6),

                                      // Download
                                      _LiquidIconAction(
                                        icon: Icons.download_rounded,
                                        onTap: widget.onDownload,
                                      ),
                                      const SizedBox(width: 6),

                                      // Favorite
                                      Consumer<FavouriteProvider>(
                                        builder: (context, favProvider, _) {
                                          final isFav = favProvider
                                              .isSelectedAsFav(widget.wall.url,
                                                  id: widget.wall.id);
                                          return _LiquidIconAction(
                                            icon: isFav
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            isFilled: isFav,
                                            onTap: () {
                                              if (UserProfile.plusMember) {
                                                if (isFav) {
                                                  favProvider.removeFromFav(
                                                      id: widget.wall.id);
                                                } else {
                                                  favProvider.addToFav(context,
                                                      wall: widget.wall);
                                                }
                                              } else {
                                                widget.onTap();
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Liquid Action Button (e.g. "Set Desktop") ───
class _LiquidActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _LiquidActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  State<_LiquidActionButton> createState() => _LiquidActionButtonState();
}

class _LiquidActionButtonState extends State<_LiquidActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accent,
                widget.accent.withValues(alpha: _hovered ? 1.0 : 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Liquid Icon Action (download / favorite) ───
class _LiquidIconAction extends StatefulWidget {
  final IconData icon;
  final bool isFilled;
  final VoidCallback? onTap;

  const _LiquidIconAction({
    required this.icon,
    this.isFilled = false,
    this.onTap,
  });

  @override
  State<_LiquidIconAction> createState() => _LiquidIconActionState();
}

class _LiquidIconActionState extends State<_LiquidIconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: widget.isFilled
                ? Colors.redAccent.withValues(alpha: _hovered ? 0.5 : 0.3)
                : Colors.white.withValues(alpha: _hovered ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: widget.isFilled ? Colors.redAccent : Colors.white,
          ),
        ),
      ),
    );
  }
}
