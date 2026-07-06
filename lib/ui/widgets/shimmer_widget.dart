import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  const ShimmerWidget(
      {super.key, required this.height, required this.width, this.radius = 25});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.2),
        highlightColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.5),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(radius)),
        ));
  }

  static Widget withWidget(Widget child, context) {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.2),
        highlightColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.5),
        child: IgnorePointer(child: child));
  }
}
