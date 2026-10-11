import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget>
    with SingleTickerProviderStateMixin {
  static const _autoPlay = Duration(seconds: 6);
  // Large virtual start page so the carousel loops in both directions.
  static const _loopBase = 10000;

  PageController? _pageController;
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _autoPlay)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _next();
        });
  int _count = 0;

  @override
  void dispose() {
    _progress.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int count, double viewportFraction) {
    if (_pageController != null &&
        _count == count &&
        _pageController!.viewportFraction == viewportFraction) {
      return;
    }
    final current = _pageController?.hasClients == true
        ? (_pageController!.page ?? 0).round() % (count == 0 ? 1 : count)
        : 0;
    _pageController?.dispose();
    _count = count;
    _pageController = PageController(
      viewportFraction: viewportFraction,
      initialPage: _loopBase - (_loopBase % count) + current,
    );
    _progress.forward(from: 0);
  }

  void _next() {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    c.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic);
  }

  void _jumpTo(int realIndex) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    final page = (c.page ?? 0).round();
    final target = page - (page % _count) + realIndex;
    c.animateToPage(target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic);
  }

  void _onTapHandler(BuildContext context, Banners banner) {
    if (banner.category.isEmpty) {
      LaunchUrlWidget.launch(banner.link);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      final provider = Provider.of<WallRio>(context, listen: false);
      final categoryWalls = provider.categories![banner.category];
      if (categoryWalls != null) {
        return GridPage(
          categoryName: banner.category,
          walls: categoryWalls,
        );
      }

      final collection = provider.collections.firstWhere(
        (c) => c.name.toLowerCase() == banner.category.toLowerCase(),
        orElse: () => Collections(id: 0, name: "", productId: "", walls: []),
      );
      if (collection.name.isNotEmpty) {
        return GridPage(
          categoryName: collection.name,
          walls: collection.walls ?? [],
          collection: collection,
        );
      }

      return GridPage(
        categoryName: banner.category,
        walls: const [],
      );
    }));
  }

  /// Same resolution rules as before: wallId, a direct image URL, or a
  /// rotating free wallpaper when no category/link is configured.
  Walls? _resolveWallOfTheDay(WallRio provider, Banners banner, int index) {
    final isSingleWallBanner = banner.wallId != null ||
        (banner.category.isEmpty && banner.link.isEmpty);
    if (!isSingleWallBanner || provider.originalWallList.isEmpty) return null;

    if (banner.wallId != null) {
      return provider.originalWallList.firstWhere(
        (w) => w.id == banner.wallId,
        orElse: () => provider.originalWallList.first,
      );
    }
    if (banner.url.contains('.jpg') ||
        banner.url.contains('.png') ||
        banner.url.contains('.jpeg')) {
      return provider.originalWallList.firstWhere(
        (w) => w.url == banner.url,
        orElse: () => Walls(
          id: banner.id,
          name: banner.title.isNotEmpty ? banner.title : "WallRio",
          author: "WallRio",
          url: banner.url,
          thumbnail: banner.url,
          category: "",
          tags: const [],
          colorsString: const [],
          colorList: const [],
          isPremium: false,
          subjectId: "",
        ),
      );
    }
    final freeWalls =
        provider.originalWallList.where((w) => !w.isPremium).toList();
    return freeWalls.isNotEmpty
        ? freeWalls[index % freeWalls.length]
        : provider.originalWallList.first;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final double carouselHeight =
        isTablet ? (isLandscape ? 340.0 : 300.0) : 210.0;
    final double viewportFraction =
        isTablet ? (isLandscape ? 0.78 : 0.84) : 0.88;

    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading || provider.bannerList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: ShimmerWidget(
            height: carouselHeight,
            width: double.infinity,
            radius: 28,
          ),
        );
      }

      final banners = provider.bannerList;
      _ensureController(banners.length, viewportFraction);
      final controller = _pageController!;

      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        child: Column(
          children: [
            SizedBox(
              height: carouselHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification && n.dragDetails != null) {
                    _progress.stop();
                  } else if (n is ScrollEndNotification &&
                      !_progress.isAnimating) {
                    _progress.forward(from: 0);
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    provider.setBannerIndex = page % banners.length;
                    _progress.forward(from: 0);
                  },
                  itemBuilder: (context, page) {
                    final index = page % banners.length;
                    final banner = banners[index];
                    final wall = _resolveWallOfTheDay(provider, banner, index);
                    return AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        double delta = 0;
                        if (controller.hasClients &&
                            controller.position.haveDimensions) {
                          delta = (controller.page ?? page.toDouble()) - page;
                        }
                        final d = delta.clamp(-1.0, 1.0);
                        return Transform.scale(
                          scale: 1 - d.abs() * 0.08,
                          child: _BannerCard(
                            parallax: d,
                            dim: d.abs(),
                            banner: banner,
                            wall: wall,
                            seed: index,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (wall != null) {
                                Navigator.push(
                                  context,
                                  WallpaperRoute(
                                    builder: (_) => FullImage(wallModel: wall),
                                  ),
                                );
                              } else {
                                _onTapHandler(context, banner);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 14),
              _StoryProgressBar(
                count: banners.length,
                activeIndex: provider.bannerIndex,
                progress: _progress,
                onTap: _jumpTo,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _BannerCard extends StatefulWidget {
  final Banners banner;
  final Walls? wall;
  final double parallax;
  // 0 for the centred card, up to 1 for side cards; darkens peeking cards.
  final double dim;
  final int seed;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.wall,
    required this.parallax,
    this.dim = 0,
    required this.seed,
    required this.onTap,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  // Slow Ken Burns drift for "wallpaper of the day" cards.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.wall != null) _drift.repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  static const _driftPaths = <List<Alignment>>[
    [Alignment.topLeft, Alignment.bottomRight],
    [Alignment.bottomRight, Alignment.topLeft],
    [Alignment.centerLeft, Alignment.centerRight],
    [Alignment.topCenter, Alignment.bottomCenter],
  ];

  @override
  Widget build(BuildContext context) {
    final wall = widget.wall;
    final banner = widget.banner;
    final isWallOfDay = wall != null;
    final title = isWallOfDay ? wall.name : banner.title.trim();
    final eyebrow = isWallOfDay
        ? (banner.title.trim().isNotEmpty
            ? banner.title.trim().replaceAll('\n', ' ')
            : 'Wallpaper of the day')
        : (banner.category.isNotEmpty ? banner.category : 'Featured');
    final subtitle = isWallOfDay
        ? 'by ${wall.author}'
        : (banner.category.isNotEmpty ? 'Tap to explore' : 'Learn more');
    final showText = isWallOfDay || title.isNotEmpty;
    final imageUrl = isWallOfDay
        ? (wall.url.isNotEmpty ? wall.url : wall.thumbnail)
        : banner.url;
    final path = _driftPaths[widget.seed % _driftPaths.length];

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: (_, __) => const ColoredBox(color: bgDark2Color),
      errorWidget: (_, __, ___) => const ColoredBox(color: bgDark2Color),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Parallax: the image drifts opposite to the swipe.
                  Transform.translate(
                    offset: Offset(widget.parallax * -60, 0),
                    child: Transform.scale(
                      scale: 1.18,
                      child: isWallOfDay
                          ? AnimatedBuilder(
                              animation: _drift,
                              builder: (context, child) {
                                final t =
                                    Curves.easeInOut.transform(_drift.value);
                                return Transform.scale(
                                  scale: 1 + 0.1 * t,
                                  alignment:
                                      Alignment.lerp(path[0], path[1], t)!,
                                  child: child,
                                );
                              },
                              child: image,
                            )
                          : image,
                    ),
                  ),
                  if (showText)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1],
                          colors: [Colors.transparent, Color(0xC7000000)],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _GlassPill(
                      style: _EyebrowStyle.resolve(
                        eyebrow,
                        isWallOfDay: isWallOfDay,
                        isLink: !isWallOfDay && banner.category.isEmpty,
                      ),
                      text: eyebrow,
                    ),
                  ),
                  if (showText)
                    Positioned(
                      left: 18,
                      right: 70,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: whiteColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: whiteColor.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.dim > 0.01)
                    IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black
                            .withValues(alpha: (widget.dim * 0.4).clamp(0, 1)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EyebrowStyle {
  final IconData icon;
  final List<Color> colors;
  const _EyebrowStyle(this.icon, this.colors);

  static const _byKeyword = <List<String>, _EyebrowStyle>{
    ['trend', 'hot', 'popular', 'viral']: _EyebrowStyle(
        Icons.local_fire_department_rounded,
        [Color(0xFFFFB347), Color(0xFFFF3D3D)]),
    ['wallpaper of the day', 'of the day', 'today', 'daily']: _EyebrowStyle(
        Icons.wb_sunny_rounded, [Color(0xFFFFE066), Color(0xFFFF8A00)]),
    ['new', 'fresh', 'latest', 'just']: _EyebrowStyle(
        Icons.new_releases_rounded, [Color(0xFF5EEAD4), Color(0xFF059669)]),
    ['live', 'motion', 'dynamic', 'animated']: _EyebrowStyle(
        Icons.play_circle_fill_rounded, [Color(0xFFF472B6), Color(0xFF9333EA)]),
    ['collection', 'pack', 'set']: _EyebrowStyle(
        Icons.collections_bookmark_rounded,
        [Color(0xFF7DD3FC), Color(0xFF4F46E5)]),
    ['pro', 'premium', 'exclusive', 'vip']: _EyebrowStyle(
        Icons.diamond_rounded, [Color(0xFFFDE68A), Color(0xFFD97706)]),
    ['pick', 'editor', 'featured', 'top', 'best']: _EyebrowStyle(
        Icons.star_rounded, [Color(0xFFFFF176), Color(0xFFF97316)]),
    ['week', 'weekly', 'month']: _EyebrowStyle(
        Icons.calendar_month_rounded, [Color(0xFF67E8F9), Color(0xFF0284C7)]),
    ['dark', 'amoled', 'night', 'black']: _EyebrowStyle(
        Icons.dark_mode_rounded, [Color(0xFFA5B4FC), Color(0xFF312E81)]),
    [
      'nature',
      'forest',
      'green',
      'earth'
    ]: _EyebrowStyle(Icons.eco_rounded, [Color(0xFFBBF7D0), Color(0xFF16A34A)]),
    ['space', 'galaxy', 'planet', 'cosmic']: _EyebrowStyle(
        Icons.rocket_launch_rounded, [Color(0xFFC4B5FD), Color(0xFF5B21B6)]),
    ['anime', 'manga']: _EyebrowStyle(
        Icons.auto_awesome_rounded, [Color(0xFFFBCFE8), Color(0xFFEC4899)]),
    ['abstract', 'art', 'gradient']: _EyebrowStyle(
        Icons.palette_rounded, [Color(0xFFF5D0FE), Color(0xFFC026D3)]),
    ['minimal', 'clean', 'simple']: _EyebrowStyle(
        Icons.crop_square_rounded, [Color(0xFFE5E7EB), Color(0xFF6B7280)]),
    ['car', 'cars', 'bike', 'speed', 'racer', 'racing']: _EyebrowStyle(
        Icons.directions_car_filled_rounded,
        [Color(0xFFCBD5E1), Color(0xFF334155)]),
    ['sale', 'offer', 'deal', 'discount']: _EyebrowStyle(
        Icons.local_offer_rounded, [Color(0xFFFDA4AF), Color(0xFFE11D48)]),
    ['gift', 'reward', 'free']: _EyebrowStyle(
        Icons.card_giftcard_rounded, [Color(0xFFFCA5A5), Color(0xFFDC2626)]),
    ['update', 'app', 'feature']: _EyebrowStyle(
        Icons.bolt_rounded, [Color(0xFFFDE047), Color(0xFFEAB308)]),
  };

  static const _fallbacks = <_EyebrowStyle>[
    _EyebrowStyle(
        Icons.auto_awesome_rounded, [Color(0xFF93C5FD), Color(0xFF7C3AED)]),
    _EyebrowStyle(
        Icons.whatshot_rounded, [Color(0xFFFDBA74), Color(0xFFEA580C)]),
    _EyebrowStyle(
        Icons.interests_rounded, [Color(0xFF6EE7B7), Color(0xFF0D9488)]),
    _EyebrowStyle(
        Icons.blur_on_rounded, [Color(0xFFF9A8D4), Color(0xFFDB2777)]),
  ];

  static _EyebrowStyle resolve(String text,
      {required bool isWallOfDay, required bool isLink}) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[^a-z]+')).toSet();
    for (final entry in _byKeyword.entries) {
      for (final key in entry.key) {
        final hit = key.contains(' ')
            ? lower.contains(key)
            : words
                .any((w) => w == key || (key.length >= 4 && w.startsWith(key)));
        if (hit) return entry.value;
      }
    }
    if (isWallOfDay) return _byKeyword.values.elementAt(1);
    if (isLink) {
      return const _EyebrowStyle(
          Icons.campaign_rounded, [Color(0xFF67E8F9), Color(0xFF0369A1)]);
    }
    return _fallbacks[lower.hashCode.abs() % _fallbacks.length];
  }
}

class _GlassPill extends StatelessWidget {
  final _EyebrowStyle style;
  final String text;
  const _GlassPill({required this.style, required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.fromLTRB(4, 4, 11, 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: style.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: style.colors.last.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(style.icon, size: 12, color: whiteColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Story-style segmented indicator; the active segment fills with autoplay.
class _StoryProgressBar extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Animation<double> progress;
  final ValueChanged<int> onTap;

  const _StoryProgressBar({
    required this.count,
    required this.activeIndex,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.appColors.accent;
    final track = Theme.of(context).primaryColorLight.withValues(alpha: 0.12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: i == activeIndex ? 34 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: i == activeIndex
                    ? AnimatedBuilder(
                        animation: progress,
                        builder: (context, _) => Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress.value.clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
