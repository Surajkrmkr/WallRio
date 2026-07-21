import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class BannerWidget extends StatelessWidget {
  final CarouselSliderController carouselController =
      CarouselSliderController();
  BannerWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading || provider.bannerList.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerWidget(
              height: 220,
              width: double.infinity,
              radius: 25,
            ),
          ),
        );
      }
      return SizedBox(
        height: 250,
        child: Column(
          children: [
            Expanded(
              child: CarouselSlider(
                carouselController: carouselController,
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 8),
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) =>
                      provider.setBannerIndex = index,
                ),
                items: provider.bannerList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final banner = entry.value;

                  // Check if banner is configured for a single wallpaper
                  final isSingleWallBanner = banner.wallId != null ||
                      (banner.category.isEmpty && banner.link.isEmpty);

                  if (isSingleWallBanner && provider.originalWallList.isNotEmpty) {
                    Walls targetWall;
                    if (banner.wallId != null) {
                      targetWall = provider.originalWallList.firstWhere(
                        (w) => w.id == banner.wallId,
                        orElse: () => provider.originalWallList.first,
                      );
                    } else if (banner.url.contains('.jpg') ||
                        banner.url.contains('.png') ||
                        banner.url.contains('.jpeg')) {
                      targetWall = provider.originalWallList.firstWhere(
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
                    } else {
                      final freeWalls = provider.originalWallList
                          .where((w) => !w.isPremium)
                          .toList();
                      targetWall = freeWalls.isNotEmpty
                          ? freeWalls[index % freeWalls.length]
                          : provider.originalWallList.first;
                    }

                    return _WallOfTheDayBannerItem(
                      banner: banner,
                      wall: targetWall,
                      index: index,
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(fit: StackFit.expand, children: [
                      CNImage(imageUrl: banner.url, isOriginalImg: true),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onTapHandler(context, banner),
                          splashColor: blackColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1)),
              child: AnimatedSmoothIndicator(
                  activeIndex: provider.bannerIndex,
                  count: provider.bannerList.length,
                  effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 2,
                      activeDotColor: Theme.of(context).primaryColorLight),
                  onDotClicked: (index) =>
                      carouselController.animateToPage(index)),
            )
          ],
        ),
      );
    });
  }
}

class _WallOfTheDayBannerItem extends StatefulWidget {
  final Banners banner;
  final Walls wall;
  final int index;

  const _WallOfTheDayBannerItem({
    required this.banner,
    required this.wall,
    required this.index,
  });

  @override
  State<_WallOfTheDayBannerItem> createState() => _WallOfTheDayBannerItemState();
}

class _WallOfTheDayBannerItemState extends State<_WallOfTheDayBannerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<Alignment> _alignAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    final animModes = [
      // 0: Top-Left to Bottom-Right
      {
        'beginAlign': Alignment.topLeft,
        'endAlign': Alignment.bottomRight,
        'beginScale': 1.0,
        'endScale': 1.30,
      },
      // 1: Bottom-Right to Top-Left
      {
        'beginAlign': Alignment.bottomRight,
        'endAlign': Alignment.topLeft,
        'beginScale': 1.0,
        'endScale': 1.32,
      },
      // 2: Bottom-Left to Top-Right
      {
        'beginAlign': Alignment.bottomLeft,
        'endAlign': Alignment.topRight,
        'beginScale': 1.05,
        'endScale': 1.35,
      },
      // 3: Top-Right to Bottom-Left
      {
        'beginAlign': Alignment.topRight,
        'endAlign': Alignment.bottomLeft,
        'beginScale': 1.0,
        'endScale': 1.28,
      },
      // 4: Top-Center to Bottom-Center
      {
        'beginAlign': Alignment.topCenter,
        'endAlign': Alignment.bottomCenter,
        'beginScale': 1.0,
        'endScale': 1.36,
      },
      // 5: Center-Left to Center-Right
      {
        'beginAlign': Alignment.centerLeft,
        'endAlign': Alignment.centerRight,
        'beginScale': 1.0,
        'endScale': 1.34,
      },
    ];

    final modeIndex = (widget.index + widget.wall.id) % animModes.length;
    final mode = animModes[modeIndex];

    _scaleAnim = Tween<double>(
      begin: mode['beginScale'] as double,
      end: mode['endScale'] as double,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _alignAnim = AlignmentTween(
      begin: mode['beginAlign'] as Alignment,
      end: mode['endAlign'] as Alignment,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String rawTitle = widget.banner.title.trim().isNotEmpty
        ? widget.banner.title.trim()
        : "WALLPAPER OF\nTHE DAY";
    final String displayTitle = rawTitle.toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullImage(wallModel: widget.wall),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ken Burns zoom in & corner-to-corner pan using full high-res wallpaper URL
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  alignment: _alignAnim.value,
                  child: child,
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.wall.url.isNotEmpty
                    ? widget.wall.url
                    : widget.wall.thumbnail,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (_, __) => Container(color: bgDark2Color),
                errorWidget: (_, __, ___) => Container(color: bgDark2Color),
              ),
            ),

            // Gradient overlay for contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            // Centered All-Caps Solid White Text Overlay (No Shadows)
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    displayTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.25,
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
