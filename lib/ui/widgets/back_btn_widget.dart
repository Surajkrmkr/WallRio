import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';

class BackBtnWidget extends StatelessWidget {
  final Color color;
  final bool isActionReset;
  const BackBtnWidget({
    super.key,
    required this.color,
    this.isActionReset = false,
  });

  void _handleTap(BuildContext context) {
    if (Platform.isIOS) HapticFeedback.lightImpact();
    Navigator.pop(context);
    if (isActionReset) {
      Provider.of<WallRio>(context, listen: false).resetToDefault();
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
        onPressed: () => _handleTap(context),
        icon: Icon(
          Icons.navigate_before_rounded,
          size: 40,
          color: color,
          // shadows: const [Shadow(blurRadius: 20, color: Colors.black26)],
        ));

    return SafeArea(
      child: Platform.isIOS
          ? Theme(
              data: Theme.of(context)
                  .copyWith(splashFactory: NoSplash.splashFactory),
              child: button,
            )
          : button,
    );
  }
}
