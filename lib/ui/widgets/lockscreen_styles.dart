import 'package:flutter/material.dart';
import 'package:wallrio/ui/widgets/lockscreen_style.dart';

/// Renders a decorative, non-interactive lockscreen-style overlay for a
/// wallpaper preview. Purely visual — no real device data is shown.
class LockscreenOverlay extends StatelessWidget {
  final LockscreenStyle style;
  final bool isLight;

  const LockscreenOverlay({super.key, required this.style, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final fg = isLight ? Colors.black.withValues(alpha: 0.82) : Colors.white.withValues(alpha: 0.92);
    final fgDim = isLight ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.65);

    return Stack(
      fit: StackFit.expand,
      children: [_buildStyle(fg, fgDim)],
    );
  }

  Widget _buildStyle(Color fg, Color fgDim) {
    switch (style) {
      case LockscreenStyle.minimalCentered:
        return _MinimalCentered(fg: fg, fgDim: fgDim);
      case LockscreenStyle.edgeToEdge:
        return _EdgeToEdge(fg: fg, fgDim: fgDim);
      case LockscreenStyle.vertical:
        return _VerticalClock(fg: fg, fgDim: fgDim);
      case LockscreenStyle.split:
        return _SplitClock(fg: fg, fgDim: fgDim);
      case LockscreenStyle.glassmorphism:
        return _Glassmorphism(fg: fg, fgDim: fgDim);
      case LockscreenStyle.calendarFocused:
        return _CalendarFocused(fg: fg, fgDim: fgDim);
      case LockscreenStyle.editorialSerif:
        return _EditorialSerif(fg: fg, fgDim: fgDim);
      case LockscreenStyle.geometric:
        return _Geometric(fg: fg, fgDim: fgDim);
      case LockscreenStyle.bottomAligned:
        return _BottomAligned(fg: fg, fgDim: fgDim);
      case LockscreenStyle.asymmetrical:
        return _Asymmetrical(fg: fg, fgDim: fgDim);
    }
  }
}

String get _demoDate {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final now = DateTime.now();
  return '${days[now.weekday - 1]}, ${now.day} ${_month(now.month)}';
}

String _month(int m) {
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  return months[m - 1];
}

class _NotificationDots extends StatelessWidget {
  final Color color;
  const _NotificationDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

// 1. Minimal centered — thin, airy, centered composition.
class _MinimalCentered extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _MinimalCentered({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        alignment: const Alignment(0, -0.3),
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('9:41', style: TextStyle(color: fg, fontSize: 46, fontWeight: FontWeight.w200, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// 2. Edge to edge — huge, tight, dominant typography.
class _EdgeToEdge extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _EdgeToEdge({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.45),
      child: FittedBox(
        child: Text('9:41',
            style: TextStyle(color: fg, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -3, height: 0.9)),
      ),
    );
  }
}

// 3. Vertical — stacked hour/minute, left aligned, tall.
class _VerticalClock extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _VerticalClock({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      top: 44,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('09', style: TextStyle(color: fg, fontSize: 34, fontWeight: FontWeight.w300, height: 1)),
          Text('41', style: TextStyle(color: fg.withValues(alpha: 0.55), fontSize: 34, fontWeight: FontWeight.w300, height: 1)),
          const SizedBox(height: 8),
          Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// 4. Split — hour left, minute right, wide divide.
class _SplitClock extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _SplitClock({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      top: 50,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('09', style: TextStyle(color: fg, fontSize: 40, fontWeight: FontWeight.w700)),
                const SizedBox(width: 14),
                Container(width: 18, height: 1.5, color: fgDim),
                const SizedBox(width: 14),
                Text('41', style: TextStyle(color: fg, fontSize: 40, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// 5. Glassmorphism — frosted floating card.
class _Glassmorphism extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _Glassmorphism({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        alignment: const Alignment(0, -0.25),
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: (fg.computeLuminance() > 0.5 ? Colors.white : Colors.black).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: fg.withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('9:41', style: TextStyle(color: fg, fontSize: 32, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// 6. Calendar focused — big date, small time.
class _CalendarFocused extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _CalendarFocused({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Positioned(
      left: 18,
      top: 46,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_demoDate.split(', ').first, style: TextStyle(color: fgDim, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
          Text('${now.day}', style: TextStyle(color: fg, fontSize: 54, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 6),
          Text('9:41 AM', style: TextStyle(color: fgDim, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// 7. Editorial serif — elegant magazine styling.
class _EditorialSerif extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _EditorialSerif({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        alignment: const Alignment(0, -0.3),
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('9:41',
                style: TextStyle(
                    color: fg, fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 42, fontWeight: FontWeight.w400)),
            const SizedBox(height: 8),
            Container(width: 30, height: 1, color: fgDim),
            const SizedBox(height: 8),
            Text(_demoDate,
                style: TextStyle(color: fgDim, fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// 8. Geometric — bold condensed with a shape accent.
class _Geometric extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _Geometric({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg.withValues(alpha: 0.18), width: 1.5)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('9:41', style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// 9. Bottom aligned — clock anchored low, minimal top.
class _BottomAligned extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _BottomAligned({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 20,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('9:41', style: TextStyle(color: fg, fontSize: 30, fontWeight: FontWeight.w500)),
                Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 16),
            _NotificationDots(color: fg),
          ],
        ),
      ),
    );
  }
}

// 10. Asymmetrical — off-center, scattered composition.
class _Asymmetrical extends StatelessWidget {
  final Color fg;
  final Color fgDim;
  const _Asymmetrical({required this.fg, required this.fgDim});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          top: 46,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('9', style: TextStyle(color: fg, fontSize: 48, fontWeight: FontWeight.w300, height: 0.9)),
              Text(':41', style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 22, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 52,
          child: Text(_demoDate, style: TextStyle(color: fgDim, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
