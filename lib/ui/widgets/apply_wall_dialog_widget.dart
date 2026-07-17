import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

/// Shown only from Android's Apply button — setting a wallpaper has no iOS
/// API, so iOS uses Save Image/Share instead and never opens this dialog.
class ApplyWallDialogWidget extends StatelessWidget {
  final String imgUrl;
  const ApplyWallDialogWidget({super.key, required this.imgUrl});

  void applyWall(BuildContext context, {required String url, required int wallLocation}) =>
      Provider.of<WallActionProvider>(context, listen: false)
          .applyWall(context, url: url, wallLocation: wallLocation);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text("Set Wallpaper"), CloseButton()],
      ),
      contentPadding: const EdgeInsets.all(20),
      children: [
        PrimaryBtnWidget(
          btnText: "Homescreen",
          onTap: () => applyWall(context,
              url: imgUrl, wallLocation: WallpaperManagerPlus.homeScreen),
        ),
        const SizedBox(height: 10),
        PrimaryBtnWidget(
          btnText: "Lockscreen",
          onTap: () => applyWall(context,
              url: imgUrl, wallLocation: WallpaperManagerPlus.lockScreen),
        ),
        const SizedBox(height: 10),
        PrimaryBtnWidget(
          btnText: "Both",
          onTap: () => applyWall(context,
              url: imgUrl, wallLocation: WallpaperManagerPlus.bothScreens),
        ),
      ],
    );
  }
}
