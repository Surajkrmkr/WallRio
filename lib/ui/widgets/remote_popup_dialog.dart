import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class RemotePopupDialog extends StatelessWidget {
  final PopupConfig config;

  const RemotePopupDialog({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDarkMode ? const Color(0xFF161822) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE5E7EB);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final descriptionColor =
        isDarkMode ? Colors.white70 : const Color(0xFF4B5563);
    final notNowColor = isDarkMode ? Colors.white60 : const Color(0xFF6B7280);
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.08);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Top Image (Banner)
                if (config.url.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: config.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerWidget(
                          height: double.infinity,
                          width: double.infinity,
                          radius: 18,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDarkMode
                              ? Colors.black26
                              : const Color(0xFFF3F4F6),
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: isDarkMode
                                ? Colors.white38
                                : const Color(0xFF9CA3AF),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 2. Title from JSON (Adaptive)
                Text(
                  config.title.isNotEmpty ? config.title : "WallRio Update",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Description from JSON (Adaptive)
                if (config.description.isNotEmpty) ...[
                  Text(
                    config.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: descriptionColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // 4. Horizontal Action Buttons (Left: Not Now text button, Right: ~25% Wider Green CTA)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Not Now (Simple Text Button with secondary text color)
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () {
                            RemotePopupService.markPopupShown();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: notNowColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            "Not Now",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: notNowColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right: Primary CTA (Visually Dominant, ~20-25% wider)
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            RemotePopupService.markPopupShown();
                            Navigator.pop(context);
                            if (config.buttonLink.isNotEmpty) {
                              LaunchUrlWidget.launch(config.buttonLink);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bgDarkAccentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            config.buttonText.isNotEmpty
                                ? config.buttonText
                                : "Download",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
