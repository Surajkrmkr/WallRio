import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';

/// Flies just the wallpaper image (not the whole detail page, which would
/// overflow at tile size), morphing the corner radius from the grid tile's
/// rounded shape to the destination card's corners.
HeroFlightShuttleBuilder heroImageShuttle(
  String imageUrl, {
  double tileRadius = 20,
}) {
  return (flightContext, animation, direction, fromContext, toContext) {
    final destination = direction == HeroFlightDirection.push
        ? toContext
        : fromContext;
    final source = direction == HeroFlightDirection.push
        ? fromContext
        : toContext;
    final sourceChild = (source.widget as Hero).child;
    final sourceRadius = sourceChild is ClipRRect
        ? sourceChild.borderRadius
        : null;
    final initialRadius = sourceRadius is BorderRadius
        ? sourceRadius.topLeft.x
        : tileRadius;
    final cardRadius = destination
        .findAncestorWidgetOfExactType<ClipRRect>()
        ?.borderRadius;
    final targetRadius = cardRadius is BorderRadius
        ? cardRadius.topLeft.x
        : 0.0;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(initialRadius, targetRadius, curved.value)!,
        ),
        child: child,
      ),
      child: CNImage(imageUrl: imageUrl),
    );
  };
}
