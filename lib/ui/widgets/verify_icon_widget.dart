import 'package:flutter/material.dart';
import 'package:wallrio/services/export.dart';

import '../../services/packages/export.dart';

class VerifyIconWidget extends StatelessWidget {
  final double padding;
  final Alignment alignment;
  final bool visibility;
  const VerifyIconWidget(
      {super.key,
      this.padding = 15,
      this.alignment = Alignment.topRight,
      this.visibility = false});

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: visibility,
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: SvgPicture.asset(
              "assets/icons/Prowalls.svg",
              semanticsLabel: 'Pro',
              height: 12,
            ),
          ),
        ),
      ),
    );
  }
}
