import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/wallpaper_preview_tile.dart';

/// Horizontally scrollable, snap-paged stack of wallpaper previews shown on
/// a [PremiumCollectionCard]. Only the first 6 wallpapers of the collection
/// are shown here — these are preview-only, opening the collection still
/// goes through the existing GridPage flow.
class ScrollableWallpaperStack extends StatefulWidget {
  final List<Walls> walls;
  final double height;
  final double viewportFraction;

  const ScrollableWallpaperStack({
    super.key,
    required this.walls,
    this.height = 300,
    this.viewportFraction = 0.6,
  });

  @override
  State<ScrollableWallpaperStack> createState() => _ScrollableWallpaperStackState();
}

class _ScrollableWallpaperStackState extends State<ScrollableWallpaperStack> {
  late final PageController _controller;
  double _page = 0;
  Timer? _autoTimer;
  late int _itemCount;

  @override
  void initState() {
    super.initState();
    _itemCount = widget.walls.take(6).length;
    _controller = PageController(
      initialPage: 0,
      viewportFraction: widget.viewportFraction,
    );
    _controller.addListener(() {
      if (mounted) setState(() => _page = _controller.page ?? 0);
    });
    _startAutoRotate();
  }

  void _startAutoRotate() {
    if (_itemCount <= 1) return;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = ((_controller.page ?? 0).round() + 1) % _itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoRotate() => _autoTimer?.cancel();

  void _resumeAutoRotate() {
    _pauseAutoRotate();
    _startAutoRotate();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewWalls = widget.walls.take(6).toList();
    if (previewWalls.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Only react to real user drags — animateToPage from the auto-rotate
          // timer also emits scroll notifications but with no drag details.
          if (notification is ScrollStartNotification && notification.dragDetails != null) {
            _pauseAutoRotate();
          } else if (notification is ScrollEndNotification) {
            _resumeAutoRotate();
          }
          return false;
        },
        child: PageView.builder(
          controller: _controller,
          padEnds: false,
          itemCount: previewWalls.length,
          itemBuilder: (context, index) {
            final delta = (_page - index).clamp(-1.0, 1.0);
            final scale = 1 - (delta.abs() * 0.05);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Transform.scale(
                scale: scale,
                child: WallpaperPreviewTile(wall: previewWalls[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
