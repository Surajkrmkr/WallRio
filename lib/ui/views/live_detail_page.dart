import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';
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

  @override
  void initState() {
    super.initState();
    _initVideo();
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
    Provider.of<WallActionProvider>(context, listen: false).downloadImg(
      context,
      widget.wall.videoUrl,
      '${widget.wall.name}_${widget.wall.id}',
    );
  }

  void _applyHandler() {
    Provider.of<WallActionProvider>(context, listen: false)
        .applyLiveWall(context, widget.wall.videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Hero(
        tag: 'live_${widget.wall.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              _buildVideoBackground(),
              _buildBackLayer(),
              _buildBackBtn(),
              _buildBottomUI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
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
    );
  }

  Widget _buildBackLayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.9),
            ],
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

  Widget _buildBottomUI() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTagsUI(),
                        const SizedBox(height: 10),
                        _buildDetailsUI(),
                      ],
                    ),
                  ),
                  _buildUtilsUI(),
                ],
              ),
              _buildActionBtnUI(),
              const AdsWidget(clearNavBar: false, bottomPadding: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsUI() {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      child: Wrap(
        spacing: 10,
        children: widget.wall.tags
            .map((tag) => ActionChip(
                  label: Text(tag, style: const TextStyle(color: whiteColor)),
                  backgroundColor: whiteColor.withValues(alpha: 0.3),
                  onPressed: () {},
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDetailsUI() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.wall.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .displayLarge!
                .copyWith(color: whiteColor),
          ),
          Text(
            widget.wall.author,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: whiteColor),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadge('LIVE', bgDarkAccentColor),
              if (widget.wall.isPremium) ...[
                const SizedBox(width: 6),
                _buildBadge(
                  'PRO',
                  const Color(0xFFE8401A),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE8401A)],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {LinearGradient? gradient}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: whiteColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUtilsUI() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
              color: whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtnUI() {
    final progression = Provider.of<ProgressionProvider>(context);
    final isPremium = widget.wall.isPremium;
    final isFreeUser = !UserProfile.plusMember;

    if (isFreeUser && isPremium && !_isSessionUnlocked) {
      return Container(
        margin: const EdgeInsets.all(20),
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: PrimaryBtnWidget(
                btnText: 'Unlock with Pro',
                textColor: whiteColor,
                forceDarkStyle: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen4(
                        onComplete: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryBtnWidget(
                btnText: 'Unlock for 30 💎',
                textColor: whiteColor,
                forceDarkStyle: true,
                onTap: () => _handleUnlockLiveWallpaper(progression),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: PrimaryBtnWidget(
              btnText: 'Download',
              textColor: whiteColor,
              forceDarkStyle: true,
              isLoading: Provider.of<WallActionProvider>(context, listen: true)
                  .isDownloading,
              progress: Provider.of<WallActionProvider>(context, listen: true)
                  .progress,
              onTap: () => _downloadHandler(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryBtnWidget(
              btnText: 'Apply',
              textColor: whiteColor,
              forceDarkStyle: true,
              isLoading: Provider.of<WallActionProvider>(context, listen: true)
                  .isApplying,
              onTap: () => _applyHandler(),
            ),
          ),
        ],
      ),
    );
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
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _UnlockLiveWallpaperInsufficientSheet(
          cost: cost,
          balance: balance,
        ),
      );
    }
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
    );
  }
}
