import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/packages/export.dart'
    show CachedNetworkImageProvider;
import 'package:wallrio/provider/wall_details.dart';
import 'package:wallrio/ui/views/desktop_wallpaper_detail_page.dart';
import 'package:wallrio/ui/views/full_image.dart';
import 'package:wallrio/ui/views/live_detail_page.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';

/// Blinkit-style detail route: the page opens as a rounded card over a dimmed
/// backdrop, neighbouring wallpapers peek at the sides and the user swipes
/// left/right to move between them.
class WallpaperRoute<T> extends PageRoute<T> {
  /// Single card, no neighbours.
  WallpaperRoute({required WidgetBuilder builder, bool zoom = false})
      : _items = const [],
        _initialIndex = 0,
        _builder = builder,
        _desktop = false;

  /// Swipeable cards over [items] (Walls / LiveWallpaper), opened at [initial].
  WallpaperRoute.pager({
    required List<Object?> items,
    required Object initial,
    bool desktop = false,
  })  : _items = _pagerItems(items, initial),
        _initialIndex = _pagerItems(items, initial).indexOf(initial),
        _builder = null,
        _desktop = desktop;

  final List<Object> _items;
  final int _initialIndex;
  final WidgetBuilder? _builder;
  final bool _desktop;

  static List<Object> _pagerItems(List<Object?> items, Object initial) {
    final list = items
        .whereType<Object>()
        .where((e) => e is Walls || e is LiveWallpaper)
        .toList();
    return list.contains(initial) ? list : [initial];
  }

  Widget _pageFor(BuildContext context, int index) {
    final builder = _builder;
    if (builder != null) return builder(context);
    final item = _items[index];
    if (item is LiveWallpaper) return LiveDetailPage(wall: item);
    final wall = item as Walls;
    return _desktop
        ? DesktopWallpaperDetailPage(wallModel: wall)
        : FullImage(wallModel: wall);
  }

  String? _thumbOf(int index) {
    if (_builder != null) return null;
    final item = _items[index];
    if (item is LiveWallpaper) return item.thumbnail;
    return (item as Walls).thumbnail;
  }

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.6);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // Hero flights into a scaled, clipped card stutter; the fade+zoom is enough.
    return HeroMode(
      enabled: false,
      child: _CardPager(
        count: _builder != null ? 1 : _items.length,
        initialIndex: _initialIndex,
        pageBuilder: _pageFor,
        thumbOf: _thumbOf,
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Fade + slight zoom is cheap to composite, unlike a full-screen slide
    // that moves a freshly built page across the screen.
    final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}

class _CardPager extends StatefulWidget {
  const _CardPager({
    required this.count,
    required this.initialIndex,
    required this.pageBuilder,
    required this.thumbOf,
  });

  final int count;
  final int initialIndex;
  final Widget Function(BuildContext, int) pageBuilder;
  final String? Function(int) thumbOf;

  @override
  State<_CardPager> createState() => _CardPagerState();
}

class _CardPagerState extends State<_CardPager>
    with SingleTickerProviderStateMixin {
  // A full-width PageView; card insets and neighbour peeking are drawn by
  // _CardSlot so expand/collapse can animate continuously.
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late final AnimationController _expand = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  late final Animation<double> _t =
      CurvedAnimation(parent: _expand, curve: Curves.easeInOutCubic);
  late int _current = widget.initialIndex;
  bool _expanded = false;
  // Neighbour pages are built only after the open transition finishes, so
  // the opening frames render just one page.
  bool _settled = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final anim = ModalRoute.of(context)?.animation;
    if (anim == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = anim;
    if (anim == null || anim.isCompleted) {
      _settled = true;
    } else {
      anim.addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_settled && mounted) {
      setState(() => _settled = true);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _expand.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    _expanded ? _expand.forward() : _expand.reverse();
  }

  // Swap in the heavy detail page only once the swipe settles, so dragging
  // never rebuilds a full page mid-gesture.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification && n.depth == 0) {
      final page = _controller.page?.round() ?? _current;
      if (page != _current) {
        HapticFeedback.selectionClick();
        setState(() => _current = page);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // System back first collapses full view back to the card.
      canPop: !_expanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _expanded) _toggleExpanded();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: ReverseAnimation(_t),
            child: _BlurredBackdrop(url: widget.thumbOf(_current)),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.count,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemBuilder: (context, i) => _CardSlot(
                controller: _controller,
                expand: _t,
                index: i,
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Current and adjacent cards build the real page so the
                      // details sheet is already there while swiping.
                      (i == _current || (_settled && (i - _current).abs() <= 1))
                          ? WallpaperCardFocus(
                              focused: i == _current,
                              child: ChangeNotifierProvider(
                                key: ValueKey(i),
                                create: (_) => WallDetails(),
                                child: Builder(
                                    builder: (context) =>
                                        widget.pageBuilder(context, i)),
                              ),
                            )
                          : _Preview(url: widget.thumbOf(i)),
                      if (i == _current)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Builder(
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.paddingOf(context).top + 14,
                                  right: 14),
                              child: _ExpandButton(
                                expanded: _expanded,
                                onTap: _toggleExpanded,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurred, tinted copy of the focused wallpaper filling the space around
/// the card. A tiny decoded thumbnail upscaled with smoothing is already soft,
/// so only a light, cached blur is needed.
class _BlurredBackdrop extends StatelessWidget {
  const _BlurredBackdrop({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: url == null
            ? const ColoredBox(key: ValueKey('none'), color: Colors.black)
            : Stack(
                key: ValueKey(url),
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Image(
                      image: ResizeImage(CachedNetworkImageProvider(url),
                          width: 48),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Colors.black),
                    ),
                  ),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                ],
              ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: expanded ? 'Exit full screen' : 'Full screen',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(
            expanded
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Lays out one wallpaper as a card (inset, rounded, neighbours peeking) or
/// full screen, interpolating between the two with [expand].
class _CardSlot extends StatelessWidget {
  const _CardSlot(
      {required this.controller,
      required this.expand,
      required this.index,
      required this.child});

  static const _cardFraction = 0.86;
  static const _maxCardWidth = 560.0;
  static const _gap = 6.0;

  final PageController controller;
  final Animation<double> expand;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final pad = mq.padding;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, expand]),
      child: child,
      builder: (context, child) {
        final page =
            controller.hasClients && controller.position.hasContentDimensions
                ? controller.page ?? index.toDouble()
                : controller.initialPage.toDouble();
        final d = index - page;
        final dist = d.abs().clamp(0.0, 1.0);
        final card = 1 - expand.value;
        // Tablets cap the card width so it keeps a phone-like shape.
        final cardW = (w * _cardFraction).clamp(0.0, _maxCardWidth);
        final peek = w - cardW;
        final side = (peek / 2 + _gap) * card;
        return Transform.translate(
          // Pull neighbours in so they peek beside the centred card.
          offset: Offset(-d * peek * card, 0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                side, (pad.top + 56) * card, side, (pad.bottom + 40) * card),
            child: Transform.scale(
              scale: 1 - 0.05 * dist * card,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28 * card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaQuery(
                      data: mq.copyWith(
                        padding: EdgeInsets.only(
                            top: pad.top * expand.value,
                            bottom: pad.bottom * expand.value),
                      ),
                      child: child!,
                    ),
                    if (dist * card > 0.01)
                      IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black
                              .withValues(alpha: 0.25 * dist * card),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tells a detail page whether its card is the centred one (e.g. so only that
/// card plays video).
class WallpaperCardFocus extends InheritedWidget {
  const WallpaperCardFocus(
      {super.key, required this.focused, required super.child});

  final bool focused;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WallpaperCardFocus>()
          ?.focused ??
      true;

  @override
  bool updateShouldNotify(WallpaperCardFocus oldWidget) =>
      focused != oldWidget.focused;
}

class _Preview extends StatelessWidget {
  const _Preview({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: url == null ? null : CNImage(imageUrl: url),
    );
  }
}

/// Fade + gentle zoom used when grid content first appears.
class AppearAnimation extends StatelessWidget {
  final Widget child;
  const AppearAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
