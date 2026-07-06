import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

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

  void _showPlusDialog(bool isForDownload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdsWidget.getPlusDialog(
        context,
        showAdButton: false,
      ),
    );
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
    return Container(
      margin: const EdgeInsets.all(20),
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: PrimaryBtnWidget(
              btnText: 'Download',
              textColor: whiteColor,
              isLoading:
                  Provider.of<WallActionProvider>(context, listen: true)
                      .isDownloading,
              progress:
                  Provider.of<WallActionProvider>(context, listen: true)
                      .progress,
              onTap: () =>
                  UserProfile.plusMember || !widget.wall.isPremium
                      ? _downloadHandler()
                      : _showPlusDialog(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryBtnWidget(
              btnText: 'Apply',
              textColor: whiteColor,
              isLoading:
                  Provider.of<WallActionProvider>(context, listen: true)
                      .isApplying,
              onTap: () =>
                  UserProfile.plusMember || !widget.wall.isPremium
                      ? _applyHandler()
                      : _showPlusDialog(false),
            ),
          ),
        ],
      ),
    );
  }
}
