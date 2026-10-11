import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';

/// Flies just the wallpaper image (not the whole detail page, which would
/// overflow at tile size), morphing the corner radius from the grid tile's
/// rounded shape to the full-screen square edges.
HeroFlightShuttleBuilder heroImageShuttle(String imageUrl,
    {double tileRadius = 20}) {
  return (flightContext, animation, direction, fromContext, toContext) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => ClipRRect(
        borderRadius:
            BorderRadius.circular(lerpDouble(tileRadius, 0, curved.value)!),
        child: child,
      ),
      child: CNImage(imageUrl: imageUrl),
    );
  };
}
