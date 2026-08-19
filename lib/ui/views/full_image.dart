import 'dart:io';
import 'dart:ui';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/screens/onboarding_screen4.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

import '../../provider/export.dart';

class FullImage extends StatefulWidget {
  final Walls wallModel;
  const FullImage({super.key, required this.wallModel});

  @override
  State<FullImage> createState() => _FullImageState();
}

class _FullImageState extends State<FullImage> {
  Map<dynamic, dynamic> _secureScreen() => {};
  bool _isSessionUnlocked = false;
  List<Walls> _recommendedWalls = [];
  List<Walls> _sameCategoryWalls = [];

  @override
  void initState() {
    _secureScreen();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final provider = Provider.of<WallRio>(context, listen: false);
      setState(() {
        _recommendedWalls = RecommendationService.getRecommendedWalls(widget.wallModel, provider.originalWallList);
        _sameCategoryWalls = provider.originalWallList
            .where((w) => w.category == widget.wallModel.category && w.id != widget.wallModel.id)
            .take(12)
            .toList();
      });
      Provider.of<WallDetails>(context, listen: false)
        ..getColorPalette(widget.wallModel.thumbnail)
        ..getWallDetails(widget.wallModel.url);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

  void _showExploreProDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            AdsWidget.getPlusDialog(context, isExplorePlus: true));
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
        cost: 20, // Fixed cost for individual walls is 20
        progression: progression,
        onUnlocked: () {
          setState(() => _isSessionUnlocked = true);
          Navigator.pop(context);
          isForDownload ? _downloadHandler(context) : _applyImgHandler(context);
        },
      ),
    );
  }

  void _copyColor(Color color) async {
    String code = "#ff${color.toString().substring(10, 16)}";
    await Clipboard.setData(ClipboardData(text: code));
    ToastWidget.showToast("Color copied");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Hero(
        tag: widget.wallModel.url,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              _buildImageUI(),
              _buildBackBtn(),
              _buildDraggableBottomSheet(),
              _buildFixedActionBtnBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.28,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                          const Color(0xEE161822),
                          const Color(0xEE0F111A),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.92),
                          const Color(0xFFF8F9FA).withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white38 : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Section
                  _buildHeroHeaderUI(),
                  const SizedBox(height: 16),

                  // Floating Metadata Chips
                  _buildMetadataChipsUI(),
                  const SizedBox(height: 20),

                  // Color Palette Section
                  _buildColorPaletteSection(),
                  const SizedBox(height: 24),

                  // Related Wallpapers Carousel
                  if (_recommendedWalls.isNotEmpty) ...[
                    _buildSectionHeader('Related Wallpapers'),
                    const SizedBox(height: 10),
                    _buildRelatedCarousel(_recommendedWalls),
                    const SizedBox(height: 24),
                  ],

                  // Real AdMob Banner Sponsored Section
                  _buildSponsoredBannerSection(),

                  // More Like This Carousel (Same styling as Related Wallpapers)
                  if (_sameCategoryWalls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('More Like This', showViewAll: true),
                    const SizedBox(height: 10),
                    _buildMoreLikeThisCarousel(_sameCategoryWalls),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeaderUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Consumer<WallDetails>(builder: (context, provider, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.wallModel.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.wallModel.author.isNotEmpty
                              ? widget.wallModel.author
                              : 'WallRio Original',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtextColor,
                          ),
                        ),
                        if (widget.wallModel.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Utilities (Fav, Share)
              Row(
                children: [
                  _buildFavUI(),
                  _buildShareBtn(),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildShareBtn() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;
    return IconButton(
      onPressed: _launchAppStore,
      icon: Icon(Icons.share_rounded, color: iconColor),
    );
  }

  Future<void> _launchAppStore() async {
    final String storeUrl = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=com.shadowteam.wallrio'
        : 'https://apps.apple.com/app/idXXXXXXXXXX';

    await SharePlus.instance.share(ShareParams(text: storeUrl));
  }

  Consumer<FavouriteProvider> _buildFavUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDarkMode ? Colors.white : Colors.black87;

    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      final bool isFav = provider.isSelectedAsFav(widget.wallModel.url);
      if (provider.isLoading) {
        return IconButton(
          onPressed: () {},
          icon: Icon(Icons.favorite_border_rounded, color: defaultColor),
        );
      }
      return IconButton(
        onPressed: () => UserProfile.plusMember
            ? isFav
                ? provider.removeFromFav(id: widget.wallModel.id)
                : provider.addToFav(context, wall: widget.wallModel)
            : _showExploreProDialog(context),
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? Colors.redAccent : defaultColor,
        ),
      );
    });
  }

  Widget _buildMetadataChipsUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget chip(IconData icon, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: bgDarkAccentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<WallDetails>(builder: (context, provider, _) {
      final resText = (provider.width != 0 && provider.height != 0)
          ? '${provider.width}x${provider.height}'
          : '4K Ultra HD';
      final sizeText = provider.size.isNotEmpty ? provider.size : '2.4 MB';

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(Icons.aspect_ratio_rounded, resText),
            const SizedBox(width: 8),
            chip(Icons.sd_storage_rounded, sizeText),
            const SizedBox(width: 8),
            if (widget.wallModel.category.isNotEmpty)
              chip(Icons.category_rounded, widget.wallModel.category),
            if (widget.wallModel.category.isNotEmpty) const SizedBox(width: 8),
            chip(Icons.auto_awesome_rounded, 'AMOLED'),
          ],
        ),
      );
    });
  }

  Widget _buildColorPaletteSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<WallDetails>(builder: (context, provider, _) {
      final colors = provider.colorSwatch;
      if (colors.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 14, color: bgDarkAccentColor),
              const SizedBox(width: 6),
              Text(
                'Color palette',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: colors.take(8).map((color) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _copyColor(color),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionHeader(String title, {bool showViewAll = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: bgDarkAccentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        if (showViewAll)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GridPage(
                  categoryName: widget.wallModel.category,
                  walls: Provider.of<WallRio>(context, listen: false).originalWallList,
                ),
              ),
            ),
            child: const Text(
              'View all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: bgDarkAccentColor,
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildRelatedCarousel(List<Walls> walls) {
    return _buildRecommendationGridCarousel(walls);
  }

  Widget _buildMoreLikeThisCarousel(List<Walls> walls) {
    return _buildRecommendationGridCarousel(walls);
  }

  Widget _buildRecommendationGridCarousel(List<Walls> walls) {
    final int adFrequency = 6;
    final int adCount = walls.isNotEmpty ? walls.length ~/ adFrequency : 0;
    final int totalCount = walls.length + adCount;

    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          // Calculate if this position is a native ad (after every 6 wallpaper cards)
          final bool isAdPosition = (i + 1) % (adFrequency + 1) == 0;
          if (isAdPosition && !UserProfile.plusMember) {
            return const SizedBox(
              width: 100,
              height: 145,
              child: SponsoredAdCard(),
            );
          }

          // Calculate actual wallpaper index
          final int wallIndex = i - (i ~/ (adFrequency + 1));
          if (wallIndex >= walls.length) return const SizedBox.shrink();

          final wall = walls[wallIndex];
          return GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => FullImage(wallModel: wall)),
            ),
            child: Container(
              width: 100,
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CNImage(imageUrl: wall.thumbnail),
                    VerifyIconWidget(visibility: !wall.isPremium),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSponsoredBannerSection() {
    if (UserProfile.plusMember) return const SizedBox.shrink();
    return const AdsWidget(
      clearNavBar: false,
      bottomPadding: 0,
      screenName: 'FullImage',
      placementName: 'BottomSponsoredBanner',
    );
  }

  Widget _buildFixedActionBtnBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildActionBtnUI(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SafeArea _buildBackBtn() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: CircleAvatar(
          backgroundColor: blackColor.withValues(alpha: 0.1),
          maxRadius: 30,
          child: const BackBtnWidget(color: whiteColor),
        ),
      ),
    );
  }

  Widget _buildImageUI() {
    return Positioned.fill(
      child: SizedBox.expand(
        child: CNImage(
          imageUrl: widget.wallModel.url,
          isOriginalImg: true,
        ),
      ),
    );
  }

  Widget _buildActionBtnUI() {
    final actionProvider = Provider.of<WallActionProvider>(context, listen: true);
    final isDownloading = actionProvider.isDownloading;
    final progress = actionProvider.progress;

    final downloadButton = Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bgDarkAccentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => UserProfile.plusMember ||
                !widget.wallModel.isPremium ||
                _isSessionUnlocked
            ? _downloadHandler(context)
            : _showPlusDialog(context, true),
        child: isDownloading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_rounded, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      Platform.isAndroid ? "Download" : "Save",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final applyButton = Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : bgDarkAccentColor.withValues(alpha: 0.15),
          foregroundColor: isDarkMode ? Colors.white : bgDarkAccentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => UserProfile.plusMember ||
                !widget.wallModel.isPremium ||
                _isSessionUnlocked
            ? _applyImgHandler(context)
            : _showPlusDialog(context, false),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wallpaper_rounded, size: 18, color: isDarkMode ? Colors.white : bgDarkAccentColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "Apply",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : bgDarkAccentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        downloadButton,
        if (Platform.isAndroid) ...[
          const SizedBox(width: 8),
          applyButton,
        ],
      ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balance = widget.progression.progression?.diamondsBalance ?? 0;
    final canAfford = balance >= widget.cost;

    final sheetColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return glassSheetBackground(
      Container(
      padding: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Unlock Premium Wallpaper',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$balance / ${widget.cost} Diamonds',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            canAfford
                                ? 'You have enough diamonds!'
                                : 'Watch ads to earn more diamonds',
                            style: TextStyle(
                                fontSize: 12,
                                color: canAfford
                                    ? const Color(0xFF37C3A3)
                                    : Colors.orangeAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRedeeming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('REDEEM ${widget.cost} DIAMONDS',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                            builder: (context) => const RewardsHubPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('GET DIAMONDS',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            const SizedBox(height: 16),
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
                      ));
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
