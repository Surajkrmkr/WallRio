import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class OnboardingScreen2 extends StatefulWidget {
  final VoidCallback onNext;
  const OnboardingScreen2({super.key, required this.onNext});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _scrollAnimController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Slow ping-pong scroll — slowed down by 25% (11.25s down, 11.25s back up)
    _scrollAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11250),
    );

    _scrollAnimController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          _scrollController.jumpTo(_scrollAnimController.value * max);
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _staggerController.forward().then((_) {
          if (mounted) _scrollAnimController.repeat(reverse: true);
        });
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Consumer<WallRio>(builder: (context, wallRio, _) {
      final hasWalls = wallRio.originalWallList.isNotEmpty;
      final walls =
          hasWalls ? wallRio.originalWallList.take(24).toList() : <Walls>[];

      return Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              flex: isTablet ? 70 : 62,
              child: _buildGridSection(walls, hasWalls, context),
            ),
            Expanded(
              flex: isTablet ? 30 : 38,
              child: _buildBottomSection(context),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGridSection(List<Walls> walls, bool hasWalls, BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final int crossAxisCount = isTablet ? (isLandscape ? 6 : 5) : 3;
    final itemCount = hasWalls ? walls.length : 24;

    final double gridScaleY = isTablet ? (isLandscape ? 1.30 : 1.24) : 1.0;
    final double perspectiveEntry = isTablet ? 0.0016 : 0.0025;
    final double tiltAngle = isTablet ? -0.24 : -0.32;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Clip → Transform (tilt + scale to fill status bar and top-left/right corners) → scroll → grid
        ClipRect(
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspectiveEntry) // perspective depth
              ..rotateX(tiltAngle),               // backward tilt
            alignment: Alignment.center,
            child: Transform.scale(
              scaleX: isTablet ? (isLandscape ? 1.25 : 1.18) : 1.0,
              scaleY: gridScaleY,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  padding: EdgeInsets.zero,
                  itemCount: itemCount,
                  itemBuilder: (context, index) => _buildAnimatedTile(
                    hasWalls ? walls[index] : null,
                    index,
                    itemCount,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Gradient fade into the dark bottom section - reduced height to let grid extend further down
        Positioned(
          bottom: -8,
          left: 0,
          right: 0,
          height: isTablet ? 110 : 150,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black],
                stops: [0.0, 0.70, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTile(Walls? wall, int index, int total) {
    final start = (index / total).clamp(0.0, 0.85);
    final end = ((index + 1) / total).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.82 + 0.18 * anim.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - anim.value)),
            child: child,
          ),
        ),
      ),
      child: _buildTile(wall, index),
    );
  }

  Widget _buildTile(Walls? wall, int index) {
    final isTablet = ResponsiveHelper.isTablet(context);
    // On iPad, use authentic iPad card aspect ratios (735/1024 = 0.72) instead of narrow phone ratios
    final aspectRatio = isTablet
        ? (index % 3 == 1 ? 0.82 : 0.73)
        : (index % 4 == 1 ? 0.72 : 0.60);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: wall == null
            ? ShimmerWidget(
                height: double.infinity, width: double.infinity, radius: 12)
            : CachedNetworkImage(
                imageUrl: wall.thumbnail,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: bgDark2Color),
                errorWidget: (_, __, ___) => Container(color: bgDark2Color),
              ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "10,000+",
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: whiteColor,
                    height: 1.0,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              "Curated in 4K. Depth. Live. AMOLED.",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: whiteColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Your screen deserves better.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: bgDarkAccentColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Start Exploring",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 17),
                    ),
                    SizedBox(width: 10),
                    Text("→", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "New wallpapers added daily",
              style: TextStyle(
                color: whiteColor.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
