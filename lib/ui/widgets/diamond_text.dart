import 'package:flutter/material.dart';

const Color kDiamondColor = Color(0xFF4FC3F7);

/// Diamond currency glyph used instead of the 💎 emoji.
class DiamondIcon extends StatelessWidget {
  const DiamondIcon({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF8BE9FF), kDiamondColor, Color(0xFF2979FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(Icons.diamond_rounded, size: size, color: Colors.white),
    );
  }
}

/// Text where every "💎" is rendered as an inline [DiamondIcon].
class DiamondText extends StatelessWidget {
  const DiamondText(this.text,
      {super.key, this.style, this.maxLines, this.overflow, this.textAlign});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final size = (effective.fontSize ?? 14) * 1.05;
    final parts = text.split('💎');
    return Text.rich(
      TextSpan(children: [
        for (int i = 0; i < parts.length; i++) ...[
          TextSpan(text: parts[i]),
          if (i < parts.length - 1)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: DiamondIcon(size: size),
            ),
        ],
      ]),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
