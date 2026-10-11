import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/model/export.dart';
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
  }) : _items = _pagerItems(items, initial),
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
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return WallpaperCardPager(
      count: _builder != null ? 1 : _items.length,
      initialIndex: _initialIndex,
      pageBuilder: _pageFor,
      thumbOf: _thumbOf,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(opacity: curved, child: child);
  }
}

class WallpaperCardPager extends StatefulWidget {
  const WallpaperCardPager({
    super.key,
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
  State<WallpaperCardPager> createState() => _CardPagerState();
}

class _CardPagerState extends State<WallpaperCardPager> with TickerProviderStateMixin {
  // A full-width PageView; card insets and neighbour peeking are drawn by
  // _CardSlot so expand/collapse can animate continuously.
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Animation<double> get _t => _expand;
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  double _gestureDelta = 0;
  double _gestureStartExpansion = 0;
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
    _drag.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    _expand.animateTo(_expanded ? 1 : 0, curve: Curves.easeOutCubic);
    _drag.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _expand.stop();
    _drag.stop();
    _gestureDelta = 0;
    _gestureStartExpansion = _expand.value;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _gestureDelta += details.delta.dy;
    final travel = MediaQuery.sizeOf(context).height * 0.3;
    if (_gestureDelta < 0) {
      _drag.value = 0;
      _expand.value = (_gestureStartExpansion - _gestureDelta / travel).clamp(
        0.0,
        1.0,
      );
    } else {
      if (_gestureStartExpansion > 0) {
        _expand.value = (_gestureStartExpansion - _gestureDelta / travel).clamp(
          0.0,
          1.0,
        );
        _drag.value = 0;
      } else {
        _drag.value = _gestureDelta;
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final height = MediaQuery.sizeOf(context).height;
    if (_gestureDelta > 0 &&
        (_gestureDelta > height * 0.16 || velocity > 700)) {
      if (_gestureStartExpansion > 0) {
        setState(() => _expanded = false);
        _settleDrag();
        return;
      }
      Navigator.of(context).pop();
      return;
    }
    final expand =
        _gestureDelta < 0 && (_expand.value > 0.5 || velocity < -700);
    setState(() => _expanded = expand || _gestureStartExpansion == 1);
    _settleDrag();
  }

  void _settleDrag() {
    _expand.animateTo(_expanded ? 1 : 0, curve: Curves.easeOutCubic);
    _drag.animateTo(0, curve: Curves.easeOutCubic);
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
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onVerticalDragCancel: _settleDrag,
      child: PopScope(
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
              child: const _BlurredBackdrop(),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final width = MediaQuery.sizeOf(context).width;
                  final page = _controller.hasClients &&
                          _controller.position.hasContentDimensions
                      ? _controller.page ?? widget.initialIndex.toDouble()
                      : widget.initialIndex.toDouble();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      for (var index = page.floor() - 1;
                          index <= page.ceil() + 1;
                          index++)
                        if (index >= 0 && index < widget.count)
                          Positioned(
                            key: ValueKey('wallpaper-peek-$index'),
                            top: 0,
                            bottom: 0,
                            left: (index - page) * width,
                            width: width,
                            child: _CardSlot(
                              controller: _controller,
                              expand: _t,
                              drag: _drag,
                              index: index,
                              child: _Preview(url: widget.thumbOf(index)),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.count,
                allowImplicitScrolling: true,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemBuilder: (context, i) => _CardSlot(
                  controller: _controller,
                  expand: _t,
                  drag: _drag,
                  index: i,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: i == _current && !_expanded
                        ? _toggleExpanded
                        : null,
                    child: RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Current and adjacent cards build the real page so the
                        // details sheet is already there while swiping.
                        (i == _current ||
                                (_settled && (i - _current).abs() <= 1))
                            ? HeroMode(
                                enabled: i == _current,
                                child: WallpaperCardFocus(
                                  focused: i == _current,
                                  expanded: _expanded && i == _current,
                                  child: ChangeNotifierProvider(
                                    key: ValueKey(i),
                                    create: (_) => WallDetails(),
                                    child: Builder(
                                      builder: (context) =>
                                          widget.pageBuilder(context, i),
                                    ),
                                  ),
                                ),
                              )
                            : _Preview(url: widget.thumbOf(i)),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredBackdrop extends StatelessWidget {
  const _BlurredBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
      ),
    );
  }
}

/// Lays out one wallpaper as a card (inset, rounded, neighbours peeking) or
/// full screen, interpolating between the two with [expand].
class _CardSlot extends StatelessWidget {
  const _CardSlot({
    required this.controller,
    required this.expand,
    required this.drag,
    required this.index,
    required this.child,
  });

  static const _cardFraction = 0.82;
  static const _maxCardWidth = 560.0;
  static const _gap = 10.0;

  final PageController controller;
  final Animation<double> expand;
  final Animation<double> drag;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final pad = mq.padding;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, expand, drag]),
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
          offset: Offset(-d * (peek + 16) * card, drag.value),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              (pad.top + 56) * card,
              side,
              (pad.bottom + 40) * card,
            ),
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
                          bottom: pad.bottom * expand.value,
                        ),
                      ),
                      child: child!,
                    ),
                    if (dist * card > 0.01)
                      IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(
                            alpha: 0.25 * dist * card,
                          ),
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
class WallpaperDetailsTransition extends StatelessWidget {
  const WallpaperDetailsTransition({
    super.key,
    required this.visible,
    required this.builder,
  });

  final bool visible;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.16),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? SizedBox.expand(
              key: const ValueKey('wallpaper-details'),
              child: builder(context),
            )
          : const SizedBox.shrink(key: ValueKey('hidden-details')),
          ),
    );
  }
}

class WallpaperCardFocus extends InheritedWidget {
  const WallpaperCardFocus({
    super.key,
    required this.focused,
    this.expanded = false,
    required super.child,
  });

  final bool focused;
  final bool expanded;

  static bool isExpanded(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WallpaperCardFocus>()
          ?.expanded ??
      true;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WallpaperCardFocus>()
          ?.focused ??
      true;

  @override
  bool updateShouldNotify(WallpaperCardFocus oldWidget) =>
      focused != oldWidget.focused || expanded != oldWidget.expanded;
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
