import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CNImage extends StatelessWidget {
  const CNImage({super.key, required this.imageUrl, this.isOriginalImg = false});
  final String? imageUrl;
  final bool isOriginalImg;

  @override
  Widget build(BuildContext context) {
    // memCacheHeight is a target in physical pixels. For the full-screen
    // preview, a fixed 1080 cap left the image visibly upscaled/blurry on
    // taller, higher-density screens — match it to the actual device instead.
    final targetHeight = isOriginalImg
        ? (MediaQuery.of(context).size.height * MediaQuery.of(context).devicePixelRatio).round()
        : 800;
    return CachedNetworkImage(
      filterQuality: FilterQuality.high,
      errorWidget: (context, url, error) =>
          const Icon(Icons.error_outline_rounded, color: Colors.red),
      fit: BoxFit.cover,
      memCacheHeight: targetHeight,
      imageUrl: imageUrl!,
      placeholder: (context, url) {
        return const ShimmerWidget(
          height: 100,
          width: double.infinity,
        );
      },
    );
  }
}
