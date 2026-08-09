import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class DesktopWallpaperDetailPage extends StatefulWidget {
  final Walls wallModel;
  const DesktopWallpaperDetailPage({super.key, required this.wallModel});

  @override
  State<DesktopWallpaperDetailPage> createState() => _DesktopWallpaperDetailPageState();
}

class _DesktopWallpaperDetailPageState extends State<DesktopWallpaperDetailPage> {
  bool _isSessionUnlocked = false;
  List<Walls> _relatedWalls = [];
  List<Walls> _moreLikeThisWalls = [];
  List<Walls> _exploreSimilarWalls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<WallRio>(context, listen: false);
      final allDesktop = provider.desktopWallList;

      final recommended = RecommendationService.getRecommendedWalls(
          widget.wallModel, allDesktop);

      final sameCatAndTags = allDesktop
          .where((w) =>
              w.id != widget.wallModel.id &&
              (w.category == widget.wallModel.category ||
                  w.tags.any((t) => widget.wallModel.tags.contains(t))))
          .toList();

      final explorePool = allDesktop
          .where((w) =>
              w.id != widget.wallModel.id &&
              !recommended.contains(w) &&
              !sameCatAndTags.contains(w))
          .toList();

      setState(() {
        _relatedWalls = recommended.take(12).toList();
        _moreLikeThisWalls = sameCatAndTags.take(12).toList();
        _exploreSimilarWalls = explorePool.isNotEmpty
            ? explorePool
            : allDesktop.where((w) => w.id != widget.wallModel.id).toList();
      });

      Provider.of<WallDetails>(context, listen: false)
        ..getColorPalette(widget.wallModel.thumbnail)
        ..getWallDetails(widget.wallModel.url);
    });
  }

  void _downloadHandler(BuildContext context) {
    final action = Provider.of<WallActionProvider>(context, listen: false);
    if (Platform.isAndroid) {
      action.downloadImg(context, widget.wallModel.url,
          "${widget.wallModel.name}_${widget.wallModel.id}");
    } else {
      action.saveToPhotos(context, widget.wallModel.url);
    }
  }

  void _applyImgHandler(BuildContext context) {
    Provider.of<WallActionProvider>(context, listen: false)
        .setWall(widget.wallModel.url, context);
  }

  void _showPlusDialog(BuildContext context, bool isForDownload) {
    if (UserProfile.plusMember ||
        !widget.wallModel.isPremium ||
        _isSessionUnlocked) {
      isForDownload ? _downloadHandler(context) : _applyImgHandler(context);
      return;
    }

    final progression =
        Provider.of<ProgressionProvider>(context, listen: false);

    CNBottomSheet.show(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: Platform.isIOS,
      builder: (context) => _UnlockWallpaperSheet(
        wall: widget.wallModel,
        cost: 20,
        progression: progression,
        onUnlocked: () {
          setState(() => _isSessionUnlocked = true);
          Navigator.pop(context);
          isForDownload ? _downloadHandler(context) : _applyImgHandler(context);
        },
      ),
    );
  }

  void _shareWallpaper() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out this ultra-wide desktop wallpaper "${widget.wallModel.name}" on WallRio! ${widget.wallModel.url}',
      ),
    );
  }

  String _getQualityBadge(Walls wall) {
    final lowerTags = wall.tags.map((t) => t.toLowerCase()).toList();
    final lowerName = wall.name.toLowerCase();
    if (lowerTags.any((t) => t.contains('8k')) || lowerName.contains('8k')) {
      return '8K';
    }
    if (lowerTags.any((t) => t.contains('5k')) || lowerName.contains('5k')) {
      return '5K';
    }
    return '4K';
  }

  String _getResolutionText(Walls wall) {
    final quality = _getQualityBadge(wall);
    if (quality == '8K') return '7680 × 4320';
    if (quality == '5K') return '5120 × 2880';
    return '3840 × 2160';
  }

  String _getAspectRatio(Walls wall) {
    final lowerTags = wall.tags.map((t) => t.toLowerCase()).toList();
    if (lowerTags.any((t) => t.contains('16:10') || t.contains('macbook'))) {
      return '16:10';
    }
    if (lowerTags.any((t) => t.contains('ultrawide') || t.contains('21:9'))) {
      return '21:9 Ultrawide';
    }
    return '16:9 Standard';
  }

  String _getFileSize(Walls wall) {
    final quality = _getQualityBadge(wall);
    if (quality == '8K') return '14.2 MB';
    if (quality == '5K') return '9.6 MB';
    return '6.4 MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeaderAppBar(context, isDarkMode),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLandscapeHeroPreview(context, isDarkMode),
                        const SizedBox(height: 16),
                        _buildInformationPanel(context, isDarkMode),
                        const SizedBox(height: 20),
                        _buildColorPaletteSection(context, isDarkMode),
                        const SizedBox(height: 24),
                        _buildRelatedWallpapersSection(context, isDarkMode),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: InlineBannerAdWidget(verticalPadding: 0),
                        ),
                        const SizedBox(height: 24),
                        _buildMoreLikeThisSection(context, isDarkMode),
                        const SizedBox(height: 24),
                        _buildExploreSimilarSection(context, isDarkMode),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildStickyActionBar(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAppBar(BuildContext context, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackBtnWidget(color: isDarkMode ? Colors.white : Colors.black),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgDarkAccentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.desktop_windows_rounded,
                          color: bgDarkAccentColor, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'DESKTOP',
                        style: TextStyle(
                          color: bgDarkAccentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<FavouriteProvider>(
                  builder: (context, favProvider, _) {
                    final isFav =
                        favProvider.wallList.any((w) => w.id == widget.wallModel.id);
                    return IconButton(
                      onPressed: () {
                        if (isFav) {
                          favProvider.removeFromFav(id: widget.wallModel.id);
                        } else {
                          favProvider.addToFav(context, wall: widget.wallModel);
                        }
                      },
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Full-width 16:9 Landscape Hero Preview (tappable to open DesktopFullscreenViewer)
  Widget _buildLandscapeHeroPreview(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DesktopFullscreenViewer(
                wallModel: widget.wallModel,
              ),
            ),
          );
        },
        child: Hero(
          tag: 'desktop_hero_${widget.wallModel.url}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.wallModel.thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerWidget(
                      height: double.infinity,
                      width: double.infinity,
                      radius: 24,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationPanel(BuildContext context, bool isDarkMode) {
    final quality = _getQualityBadge(widget.wallModel);
    final resolution = _getResolutionText(widget.wallModel);
    final aspectRatio = _getAspectRatio(widget.wallModel);
    final fileSize = _getFileSize(widget.wallModel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.wallModel.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: bgDarkAccentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quality,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Created by ${widget.wallModel.author.isNotEmpty ? widget.wallModel.author : 'WallRio Studio'}",
            style: TextStyle(
              fontSize: 13,
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Metadata Chips Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetaChip(context, Icons.aspect_ratio_rounded, resolution,
                  isDarkMode),
              _buildMetaChip(
                  context, Icons.sd_storage_rounded, fileSize, isDarkMode),
              _buildMetaChip(context, Icons.screen_search_desktop_rounded,
                  aspectRatio, isDarkMode),
              _buildMetaChip(context, Icons.category_rounded,
                  widget.wallModel.category, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(
      BuildContext context, IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: (isDarkMode ? Colors.white : Colors.black)
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDarkMode ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteSection(BuildContext context, bool isDarkMode) {
    return Consumer<WallDetails>(
      builder: (context, detailsProvider, _) {
        if (detailsProvider.colorSwatch.isEmpty &&
            widget.wallModel.colorList.isEmpty) {
          return const SizedBox.shrink();
        }

        final colorsToDisplay = detailsProvider.colorSwatch.isNotEmpty
            ? detailsProvider.colorSwatch
            : widget.wallModel.colorList;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Color Palette",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: colorsToDisplay.map((color) {
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Related Desktop Wallpapers (Horizontal 16:9 Row, 10-12 items)
  Widget _buildRelatedWallpapersSection(BuildContext context, bool isDarkMode) {
    if (_relatedWalls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Related Desktop Wallpapers",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _relatedWalls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final wall = _relatedWalls[index];
              return SizedBox(
                width: 190,
                child: _buildDesktopCardTile(wall, context, isDarkMode),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. More Like This (Horizontal 16:9 Row, 10-12 items)
  Widget _buildMoreLikeThisSection(BuildContext context, bool isDarkMode) {
    if (_moreLikeThisWalls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "More Like This",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _moreLikeThisWalls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final wall = _moreLikeThisWalls[index];
              return SizedBox(
                width: 190,
                child: _buildDesktopCardTile(wall, context, isDarkMode),
              );
            },
          ),
        ),
      ],
    );
  }

  // 3. Explore Similar Wallpapers (2-Column Landscape Grid)
  Widget _buildExploreSimilarSection(BuildContext context, bool isDarkMode) {
    if (_exploreSimilarWalls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Explore Similar Wallpapers",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exploreSimilarWalls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 16 / 9,
            ),
            itemBuilder: (context, index) {
              final wall = _exploreSimilarWalls[index];
              return _buildDesktopCardTile(wall, context, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  // Reusable 16:9 Landscape Desktop Card Tile (Desktop Badge, Title, Resolution Tag, Premium Badge)
  Widget _buildDesktopCardTile(Walls wall, BuildContext context, bool isDarkMode) {
    final resolution = _getQualityBadge(wall);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DesktopWallpaperDetailPage(wallModel: wall),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CNImage(imageUrl: wall.thumbnail),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                // Desktop Badge top left
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.6,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.desktop_windows_rounded,
                            color: Colors.white, size: 9),
                        SizedBox(width: 3),
                        Text(
                          'DESKTOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Premium Badge top right
                VerifyIconWidget(visibility: !wall.isPremium),
                // Wallpaper Title & Resolution Tag bottom left
                Positioned(
                  bottom: 6,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          wall.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          resolution,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sticky Bottom Action Bar with Download, Apply, and Share
  Widget _buildStickyActionBar(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1E28).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: (isDarkMode ? Colors.white : Colors.black)
                .withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Download (Primary Action)
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () => _showPlusDialog(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgDarkAccentColor,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                "DOWNLOAD",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Apply / Set Wallpaper Action
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => _showPlusDialog(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                side: BorderSide(
                  color: (isDarkMode ? Colors.white : Colors.black)
                      .withValues(alpha: 0.25),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.wallpaper_rounded, size: 18),
              label: const Text(
                "APPLY",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Share Action Button
          IconButton(
            onPressed: _shareWallpaper,
            style: IconButton.styleFrom(
              backgroundColor: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
              padding: const EdgeInsets.all(12),
            ),
            icon: Icon(
              Icons.share_rounded,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockWallpaperSheet extends StatefulWidget {
  final Walls wall;
  final int cost;
  final ProgressionProvider progression;
  final VoidCallback onUnlocked;

  const _UnlockWallpaperSheet({
    required this.wall,
    required this.cost,
    required this.progression,
    required this.onUnlocked,
  });

  @override
  State<_UnlockWallpaperSheet> createState() => _UnlockWallpaperSheetState();
}

class _UnlockWallpaperSheetState extends State<_UnlockWallpaperSheet> {
  bool _isRedeeming = false;

  @override
  Widget build(BuildContext context) {
    final balance = widget.progression.progression?.diamondsBalance ?? 0;
    final canAfford = balance >= widget.cost;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDarkMode ? bgDark2Color : Colors.white;

    return glassSheetBackground(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock Premium Desktop Wallpaper',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$balance / ${widget.cost} Diamonds',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            canAfford
                                ? 'You have enough diamonds!'
                                : 'Watch ads to earn more diamonds',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: canAfford
                                  ? const Color(0xFF37C3A3)
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (canAfford)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRedeeming
                        ? null
                        : () async {
                            setState(() => _isRedeeming = true);
                            final success = await widget.progression
                                .deductDiamonds(
                                    widget.cost, "Unlocked Wallpaper");
                            if (success) {
                              ToastWidget.showToast("Wallpaper Unlocked! 💎");
                              widget.onUnlocked();
                            } else {
                              setState(() => _isRedeeming = false);
                              ToastWidget.showToast("Redemption failed.");
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37C3A3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isRedeeming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('REDEEM ${widget.cost} DIAMONDS',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RewardsHubPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('GET DIAMONDS',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen4(
                            onComplete: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  child: const Text('Unlock ALL with Pro',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
      tint: sheetColor,
    );
  }
}
