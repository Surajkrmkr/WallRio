import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Diwali 2026 (8 Nov) festive touches. Everything here switches itself on
/// and off by date, so no remote config or follow-up release is needed.
class Diwali {
  Diwali._();

  /// Inclusive start, exclusive end (local time): 4 Nov to 12 Nov covers
  /// Dhanteras to Bhai Dooj.
  static final DateTime start = DateTime(2026, 11, 4);
  static final DateTime end = DateTime(2026, 11, 13);

  /// Flip to true to preview the decorations outside the festival window.
  static const bool forceOn = false;

  /// Android only: the festive launcher icon and the offer are Android-side,
  /// so the iOS app stays untouched.
  static bool get active {
    if (!Platform.isAndroid) return false;
    if (forceOn) return true;
    final now = DateTime.now();
    return !now.isBefore(start) && now.isBefore(end);
  }

  /// Launcher icon key used while the festival is on (see MainActivity aliases).
  static const String iconKey = 'icon_diwali';
}

const List<Color> _bulbColors = [
  Color(0xFFFF9514),
  Color(0xFFFF3D71),
  Color(0xFFFFD60A),
  Color(0xFF3DDC84),
  Color(0xFF46BEFF),
];

/// A thin string of twinkling coloured bulbs running around [child].
class DiwaliLights extends StatefulWidget {
  final Widget child;
  const DiwaliLights({super.key, required this.child});

  @override
  State<DiwaliLights> createState() => _DiwaliLightsState();
}

class _DiwaliLightsState extends State<DiwaliLights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Diwali.active) return widget.child;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _LightsPainter(_c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Bulb {
  final Offset wire; // where the bulb hangs from the wire
  final double radius;
  final Color color;
  final int speed; // twinkle cycles per loop (integers keep the loop seamless)
  final double phase;
  final double chase; // position used for the travelling "chase" wave
  final double flicker; // 0 = steady, otherwise phase of its quick flicker
  _Bulb(
    this.wire,
    this.radius,
    this.color,
    this.speed,
    this.phase,
    this.chase,
    this.flicker,
  );
}

/// Hand-draped strands of fairy lights: a few uneven swags that cross the
/// child, with bulbs hanging at uneven spacing. Each bulb has its own blink
/// rhythm plus an occasional quick flicker, like cheap real string lights.
class _LightsPainter extends CustomPainter {
  final Animation<double> t;
  _LightsPainter(this.t) : super(repaint: t);

  Size? _cachedFor;
  final List<_Bulb> _bulbs = [];
  final List<Path> _wires = [];

  // start, end (normalised to the box) and how far the swag sags, in box heights.
  static const _strands = [
    [0.00, 0.14, 1.00, 0.04, 0.34],
    [0.00, 0.52, 0.97, 0.74, 0.11],
    [0.46, 0.00, 0.80, 0.60, 0.12],
  ];

  void _build(Size size) {
    _cachedFor = size;
    _bulbs.clear();
    _wires.clear();
    final rnd = math.Random(26);
    var chaseIdx = 0.0;
    for (final s in _strands) {
      final p0 = Offset(s[0] * size.width, s[1] * size.height);
      final p2 = Offset(s[2] * size.width, s[3] * size.height);
      final mid = Offset((p0.dx + p2.dx) / 2, (p0.dy + p2.dy) / 2);
      final p1 = Offset(
        mid.dx + (rnd.nextDouble() - .5) * size.width * .12,
        mid.dy + s[4] * size.height * 2,
      );
      _wires.add(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy),
      );

      Offset at(double u) {
        final v = 1 - u;
        return Offset(
          v * v * p0.dx + 2 * v * u * p1.dx + u * u * p2.dx,
          v * v * p0.dy + 2 * v * u * p1.dy + u * u * p2.dy,
        );
      }

      final len = (p2 - p0).distance + s[4] * size.height * 1.4;
      final n = (len / 21).round().clamp(4, 18);
      var u = 0.04 + rnd.nextDouble() * 0.04;
      for (var i = 0; i < n && u < 0.97; i++) {
        _bulbs.add(
          _Bulb(
            at(u),
            2.4 + rnd.nextDouble() * 1.2,
            _bulbColors[rnd.nextInt(_bulbColors.length)],
            1 + rnd.nextInt(3),
            rnd.nextDouble(),
            chaseIdx++,
            rnd.nextInt(4) == 0 ? rnd.nextDouble() : -1,
          ),
        );
        u += (0.8 + rnd.nextDouble() * 0.5) / n; // uneven spacing
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedFor != size) _build(size);
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xAA4A4A52);
    for (final w in _wires) {
      canvas.drawPath(w, wirePaint);
    }

    final total = _bulbs.length.toDouble();
    for (final b in _bulbs) {
      // slow individual twinkle
      var k = 0.5 + 0.5 * math.sin(2 * math.pi * (t.value * b.speed + b.phase));
      k = math.pow(k, 1.6).toDouble();
      // travelling chase wave across the whole string
      final wave =
          0.5 + 0.5 * math.sin(2 * math.pi * (t.value * 2 - b.chase / total));
      var a = 0.22 + 0.78 * math.max(k, math.pow(wave, 6).toDouble());
      // occasional quick flicker on some bulbs
      if (b.flicker >= 0) {
        final f = (t.value * 5 + b.flicker) % 1.0;
        if (f > 0.86) a *= 0.12;
      }
      a = a.clamp(0.0, 1.0);

      final c = b.wire.translate(0.4, b.radius + 2.2); // bulb hangs below wire
      // socket
      canvas.drawLine(
        b.wire,
        b.wire.translate(0.2, 2.6),
        Paint()
          ..color = const Color(0xFF3A3A44)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // halo
      canvas.drawCircle(
        c,
        b.radius * 2.8,
        Paint()
          ..color = b.color.withValues(alpha: 0.5 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // glass
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: b.radius * 1.7,
          height: b.radius * 2.2,
        ),
        Paint()
          ..color = Color.lerp(b.color.withValues(alpha: 0.35), b.color, a)!,
      );
      // hot core when the bulb is bright
      canvas.drawCircle(
        c.translate(-0.3, -0.5),
        b.radius * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.8 * a * a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightsPainter old) => false;
}

/// A small clay diya with a gently flickering flame.
class DiwaliDiya extends StatefulWidget {
  final double size;
  const DiwaliDiya({super.key, this.size = 24});

  @override
  State<DiwaliDiya> createState() => _DiwaliDiyaState();
}

class _DiwaliDiyaState extends State<DiwaliDiya>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Diwali.active) return const SizedBox.shrink();
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _DiyaPainter(_c)),
      ),
    );
  }
}

class _DiyaPainter extends CustomPainter {
  final Animation<double> t;
  _DiyaPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final flick = 0.5 + 0.5 * math.sin(t.value * 2 * math.pi * 2);
    final sway = math.sin(t.value * 2 * math.pi * 3) * 0.04 * w;

    // Flame glow
    final flameC = Offset(w * 0.5, h * 0.36);
    canvas.drawCircle(
      flameC,
      w * (0.26 + 0.05 * flick),
      Paint()
        ..color = const Color(0xFFFFA726).withValues(alpha: 0.35 + 0.2 * flick)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.16),
    );

    // Flame (teardrop)
    final fh = h * (0.34 + 0.04 * flick);
    final flame = Path()
      ..moveTo(w * 0.5 + sway, h * 0.60 - fh)
      ..cubicTo(
        w * 0.72,
        h * 0.50 - fh * 0.3,
        w * 0.66,
        h * 0.60,
        w * 0.5,
        h * 0.60,
      )
      ..cubicTo(
        w * 0.34,
        h * 0.60,
        w * 0.28,
        h * 0.50 - fh * 0.3,
        w * 0.5 + sway,
        h * 0.60 - fh,
      );
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE066), Color(0xFFFF8A00)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.53),
          width: w * 0.12,
          height: h * 0.16,
        ),
      ),
      Paint()..color = const Color(0xFFFFF6D6),
    );

    // Clay bowl
    final bowl = Path()
      ..moveTo(w * 0.06, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.64, w * 0.94, h * 0.62)
      ..quadraticBezierTo(w * 0.86, h * 0.94, w * 0.5, h * 0.94)
      ..quadraticBezierTo(w * 0.14, h * 0.94, w * 0.06, h * 0.62)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2A83B), Color(0xFFB8561A)],
        ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.36)),
    );
    // Rim highlight
    canvas.drawLine(
      Offset(w * 0.12, h * 0.645),
      Offset(w * 0.88, h * 0.645),
      Paint()
        ..color = const Color(0xFFFFD98A)
        ..strokeWidth = h * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DiyaPainter old) => false;
}
