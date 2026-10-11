import 'package:flutter/material.dart';

import '../../services/packages/export.dart';

class VerifyIconWidget extends StatelessWidget {
  final double padding;
  final Alignment alignment;
  final bool visibility;
  const VerifyIconWidget(
      {super.key,
      this.padding = 10,
      this.alignment = Alignment.topLeft,
      this.visibility = false});

  @override
  Widget build(BuildContext context) {
    if (visibility) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: const ProBadge(),
        ),
      ),
    );
  }
}

const List<Color> proGoldGradient = [
  Color(0xFFFFE08A),
  Color(0xFFF9B93B),
  Color(0xFFE88A17),
];

/// Gold "PRO" pill used as the shared visual identity for premium content.
class ProBadge extends StatelessWidget {
  final double scale;
  const ProBadge({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3B2300);
    return Container(
      padding:
          EdgeInsets.fromLTRB(6 * scale, 3.5 * scale, 7 * scale, 3.5 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: proGoldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A524).withValues(alpha: 0.45),
            blurRadius: 10 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            "assets/icons/Prowalls.svg",
            semanticsLabel: 'Pro',
            height: 9 * scale,
            colorFilter: const ColorFilter.mode(ink, BlendMode.srcIn),
          ),
          SizedBox(width: 4 * scale),
          Text(
            'PRO',
            style: TextStyle(
              color: ink,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
