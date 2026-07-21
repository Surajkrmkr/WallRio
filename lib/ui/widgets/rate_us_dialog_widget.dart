import 'package:flutter/material.dart';
import 'package:wallrio/services/theme_data.dart';

class RateUsDialog extends StatelessWidget {
  final VoidCallback onRateNow;
  final VoidCallback onDismiss;

  const RateUsDialog({
    super.key,
    required this.onRateNow,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? bgDark2Color : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1D26);
    final subtitleColor = isDark ? Colors.grey.shade400 : const Color(0xFF3A3D4A);

    final btnBg = isDark ? bgDarkAccentColor : const Color(0xFF191C26);
    final btnTextColor = isDark ? Colors.black : Colors.white;

    return Dialog(
      backgroundColor: cardBg,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Stack(
          children: [
            // Close (X) button top right
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Enjoy Our App",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),

                // 5-Star Graphic matching the reference design
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    _GoldenStar(size: 26),
                    SizedBox(width: 4),
                    _GoldenStar(size: 40),
                    SizedBox(width: 4),
                    _GoldenStar(size: 56),
                    SizedBox(width: 4),
                    _GoldenStar(size: 40),
                    SizedBox(width: 4),
                    _GoldenStar(size: 26),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  "If you enjoy using our app,\nPlease rate us",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 26),

                // Rate Now Button
                SizedBox(
                  width: 170,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onRateNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnBg,
                      foregroundColor: btnTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      "Rate Now",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: btnTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldenStar extends StatelessWidget {
  final double size;
  const _GoldenStar({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
          ],
        ).createShader(bounds);
      },
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: Colors.amber,
      ),
    );
  }
}
