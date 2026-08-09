import 'dart:io';
import 'dart:ui';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';
import 'package:wallrio/ui/views/full_image.dart';
import 'package:wallrio/ui/onboarding/export.dart';

class LiveDetailPage extends StatefulWidget {
  final LiveWallpaper wall;
  const LiveDetailPage({super.key, required this.wall});

  @override
  State<LiveDetailPage> createState() => _LiveDetailPageState();
}

class _LiveDetailPageState extends State<LiveDetailPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _isSessionUnlocked = false;
  List<LiveWallpaper> _recommendedLive = [];
  List<Walls> _recommendedStatic = [];

  @override
  void initState() {
    super.initState();
    _initVideo();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final liveProvider = Provider.of<LiveWallpaperProvider>(context, listen: false);
      final wallRio = Provider.of<WallRio>(context, listen: false);
      setState(() {
        _recommendedLive = RecommendationService.getRecommendedLiveWalls(widget.wall, liveProvider.wallList);
        _recommendedStatic = RecommendationService.getRecommendedStaticForLive(widget.wall, wallRio.originalWallList);
      });
      Provider.of<WallDetails>(context, listen: false)
        ..getColorPalette(widget.wall.thumbnail)
        ..getWallDetails(widget.wall.videoUrl);
    });
  }

  Future<void> _initVideo() async {
    final url = widget.wall.previewVideo.isNotEmpty
        ? widget.wall.previewVideo
        : widget.wall.videoUrl;

    if (url.isEmpty) {
      if (mounted) setState(() => _hasVideoError = true);
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (mounted) {
        _videoController!.addListener(_onVideoUpdate);
        setState(() => _isVideoInitialized = true);
        _videoController!
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      }
    } catch (_) {
      if (mounted) setState(() => _hasVideoError = true);
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  void _downloadHandler() {
    final action = Provider.of<WallActionProvider>(context, listen: false);
    if (Platform.isAndroid) {
      action.downloadImg(
        context,
        widget.wall.videoUrl,
        '${widget.wall.name}_${widget.wall.id}',
      );
    } else {
      action.saveToPhotos(context, widget.wall.videoUrl, isVideo: true);
    }
  }

  void _applyHandler() {
    final action = Provider.of<WallActionProvider>(context, listen: false);
    if (Platform.isAndroid) {
      action.applyLiveWall(context, widget.wall.videoUrl);
    } else {
      action.shareFile(context, widget.wall.videoUrl,
          text: 'Live wallpaper from WallRio');
    }
  }

  void _handleUnlockLiveWallpaper(ProgressionProvider progression) async {
    final balance = progression.progression?.diamondsBalance ?? 0;
    const cost = 30;

    if (balance >= cost) {
      final success =
          await progression.deductDiamonds(cost, "Unlocked Video Wallpaper");
      if (success) {
        ToastWidget.showToast("Video Wallpaper Unlocked! 💎");
        setState(() => _isSessionUnlocked = true);
      } else {
        ToastWidget.showToast("Redemption failed.");
      }
    } else {
      CNBottomSheet.show(
        context: context,
        backgroundColor: Colors.transparent,
        showDragHandle: Platform.isIOS,
        builder: (context) => _UnlockLiveWallpaperInsufficientSheet(
          cost: cost,
          balance: balance,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Hero(
        tag: 'live_${widget.wall.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              _buildVideoBackground(),
              _buildBackBtn(),
              _buildDraggableBottomSheet(),
              _buildFixedActionBtnBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned.fill(
      child: SizedBox.expand(
        child: _isVideoInitialized && _videoController != null && !_hasVideoError
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  CNImage(imageUrl: widget.wall.thumbnail, isOriginalImg: true),
                  if (!_hasVideoError)
                    const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: bgDarkAccentColor,
                        ),
                      ),
                    ),
                ],
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

                  // Hero Header Section
                  _buildHeroHeaderUI(),
                  const SizedBox(height: 16),

                  // Floating Metadata Chips
                  _buildMetadataChipsUI(),
                  const SizedBox(height: 20),

                  // Color Palette Section
                  _buildColorPaletteSection(),
                  const SizedBox(height: 24),

                  // Recommended Live Wallpapers Row
                  if (_recommendedLive.isNotEmpty) ...[
                    _buildSectionHeader('Recommended Live Wallpapers'),
                    const SizedBox(height: 10),
                    _buildLiveRecRow(_recommendedLive),
                    const SizedBox(height: 24),
                  ],

                  // Real AdMob Banner Sponsored Section
                  _buildSponsoredBannerSection(),

                  // Matching Static Wallpapers Row
                  if (_recommendedStatic.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Matching Static Wallpapers'),
                    const SizedBox(height: 10),
                    _buildStaticRecRow(_recommendedStatic),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.wall.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    widget.wall.author.isNotEmpty
                        ? widget.wall.author
                        : 'WallRio Live Original',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bgDarkAccentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (widget.wall.isPremium)
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Play/Pause Video Toggle Utility
        IconButton(
          onPressed: () {
            final ctrl = _videoController;
            if (ctrl == null) return;
            ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
          },
          icon: Icon(
            _videoController?.value.isPlaying == true
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 28,
          ),
        ),
      ],
    );
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(Icons.videocam_rounded, 'Live Wallpaper'),
          const SizedBox(width: 8),
          chip(Icons.aspect_ratio_rounded, '1080x1920'),
          const SizedBox(width: 8),
          chip(Icons.auto_awesome_rounded, '60 FPS Ultra'),
        ],
      ),
    );
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
            child: Row(
              children: colors.take(8).map((color) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
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
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
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
      ],
    );
  }

  Widget _buildLiveRecRow(List<LiveWallpaper> walls) {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: walls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final wall = walls[i];
          return GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LiveDetailPage(wall: wall)),
            ),
            child: Container(
              width: 100,
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
    return const AdsWidget(clearNavBar: false, bottomPadding: 0);
  }

  Widget _buildStaticRecRow(List<Walls> walls) {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: walls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final wall = walls[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FullImage(wallModel: wall)),
            ),
            child: Container(
              width: 100,
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

  Widget _buildActionBtnUI() {
    final progression = Provider.of<ProgressionProvider>(context);
    final isPremium = widget.wall.isPremium;
    final isFreeUser = !UserProfile.plusMember;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isFreeUser && isPremium && !_isSessionUnlocked) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: bgDarkAccentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen4(
                      onComplete: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              child: const Text(
                'Unlock Pro',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : bgDarkAccentColor.withValues(alpha: 0.15),
                foregroundColor: isDarkMode ? Colors.white : bgDarkAccentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _handleUnlockLiveWallpaper(progression),
              child: Text(
                'Unlock 30 💎',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : bgDarkAccentColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
        onPressed: _downloadHandler,
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
                children: [
                  const Icon(Icons.download_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    Platform.isAndroid ? "Download" : "Save",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
      ),
    );

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
        onPressed: _applyHandler,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallpaper_rounded, size: 18, color: isDarkMode ? Colors.white : bgDarkAccentColor),
            const SizedBox(width: 6),
            Text(
              Platform.isAndroid ? "Apply" : "Share",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isDarkMode ? Colors.white : bgDarkAccentColor,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        downloadButton,
        const SizedBox(width: 8),
        applyButton,
      ],
    );
  }
}

class _UnlockLiveWallpaperInsufficientSheet extends StatelessWidget {
  final int cost;
  final int balance;

  const _UnlockLiveWallpaperInsufficientSheet({
    required this.cost,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock Premium Video Wallpaper',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
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
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$balance / $cost Diamonds',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Watch ads to earn more diamonds',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'GET DIAMONDS',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
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
                  child: const Text(
                    'Unlock ALL with Pro',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w700),
                  ),
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
