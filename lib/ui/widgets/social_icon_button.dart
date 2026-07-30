import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String tooltip;
  final double size;

  const SocialIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.tooltip,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  if (Platform.isIOS) HapticFeedback.lightImpact();
                  onTap!();
                },
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
