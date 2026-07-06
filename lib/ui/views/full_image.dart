import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
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
  bool _showPalette = false;

  // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

  @override
  void initState() {
    _secureScreen();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      Provider.of<WallDetails>(context, listen: false)
        ..getColorPalette(widget.wallModel.thumbnail)
        ..getWallDetails(widget.wallModel.url);
    });
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
    // await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void _downloadHandler(BuildContext context) {
    Provider.of<WallActionProvider>(context, listen: false).downloadImg(
        context,
        widget.wallModel.url,
        "${widget.wallModel.name}_${widget.wallModel.id}");
  }

  void _applyImgHandler(BuildContext context) {
    Provider.of<WallActionProvider>(context, listen: false)
        .setWall(widget.wallModel.url, context);
  }

  void _showExplorePlusDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            AdsWidget.getPlusDialog(context, isExplorePlus: true));
  }

  void _showPlusDialog(BuildContext context, bool isForDownload) {
    if (UserProfile.plusMember) {
       isForDownload ? _downloadHandler(context) : _applyImgHandler(context);
       return;
    }

    final progression = Provider.of<ProgressionProvider>(context, listen: false);
    final isUnlocked = progression.isWallpaperUnlocked(widget.wallModel.id.toString());
    
    if (isUnlocked) {
      isForDownload ? _downloadHandler(context) : _applyImgHandler(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _UnlockWallpaperSheet(
        wall: widget.wallModel,
        cost: 25, // Fixed cost for individual walls
        progression: progression,
        onUnlocked: () {
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
      body: Hero(
        tag: widget.wallModel.url,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              _buildImageUI(),
              _buildBackBtn(),
              _buildBackLayer(),
              _buildBottomUI()
            ],
          ),
        ),
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
        )),
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

  SizedBox _buildImageUI() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: CNImage(
          imageUrl: widget.wallModel.url,
          isOriginalImg: true,
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
                      SizedBox(height: 10),
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
      padding: const EdgeInsets.only(left: 20.0),
      child: Wrap(
        spacing: 10,
        children: widget.wallModel.tags
            .map((tag) => ActionChip(
                  label: Text(
                    tag,
                    style: TextStyle(color: whiteColor),
                  ),
                  backgroundColor: whiteColor.withValues(alpha: 0.3),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GridPage(
                                categoryName: tag,
                                walls: Provider.of<WallRio>(context)
                                    .originalWallList,
                                isSearchMode: true,
                              ))),
                  padding: EdgeInsets.symmetric(horizontal: 2),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildUtilsUI() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildColorPaletteContainer(),
          _buildColorPalette(),
          _buildFavUI(),
          _buildShareBtn(),
        ],
      ),
    );
  }

  Widget _buildColorPaletteContainer() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: _showPalette ? 250 : 0,
      width: 35,
      margin: EdgeInsets.only(bottom: 10, right: 7),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: _showPalette
          ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: ListView(
                children: Provider.of<WallDetails>(context, listen: true)
                    .colorSwatch
                    .map((color) {
                  return GestureDetector(
                    onTap: () => _copyColor(color),
                    child: Container(
                      height: 25,
                      width: 35,
                      decoration: BoxDecoration(
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          : null,
    );
  }

  Widget _buildColorPalette() {
    return _buildBtn(
        color: whiteColor,
        iconData: _showPalette ? Icons.close : Icons.color_lens_outlined,
        onTap: () => setState(() => _showPalette = !_showPalette));
  }

  Widget _buildShareBtn() {
    return _buildBtn(
        color: whiteColor, iconData: Icons.share, onTap: _launchPlayStore);
  }

  Future<void> _launchPlayStore() async {
    final String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.shadowteam.wallrio';

    await SharePlus.instance.share(ShareParams(text: playStoreUrl));
  }

  Consumer<FavouriteProvider> _buildFavUI() {
    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      final bool isFav = provider.isSelectedAsFav(widget.wallModel.url);
      if (provider.isLoading) {
        return _buildBtn(
            color: whiteColor,
            iconData: Icons.favorite_border_rounded,
            onTap: () {});
      }
      return _buildBtn(
          color: isFav ? Colors.redAccent : whiteColor,
          iconData:
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onTap: () => UserProfile.plusMember
              ? isFav
                  ? provider.removeFromFav(id: widget.wallModel.id)
                  : provider.addToFav(context, wall: widget.wallModel)
              : _showExplorePlusDialog(context));
    });
  }

  IconButton _buildBtn(
      {required Function() onTap,
      required IconData iconData,
      required Color color}) {
    return IconButton(onPressed: onTap, icon: Icon(iconData, color: color));
  }

  Widget _buildDetailsUI() {
    return Consumer<WallDetails>(builder: (context, provider, _) {
      return Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.wallModel.name,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge!
                    .copyWith(color: whiteColor)),
            Text(widget.wallModel.author,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: whiteColor)),
            Text(provider.size,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: whiteColor)),
            Text("${provider.width} x ${provider.height}",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: whiteColor)),
          ],
        ),
      );
    });
  }

  Widget _buildActionBtnUI() {
    return Container(
      margin: EdgeInsets.all(20),
      height: 40,
      child: Row(children: [
        Expanded(
            child: PrimaryBtnWidget(
                btnText: "Download",
                textColor: whiteColor,
                isLoading:
                    Provider.of<WallActionProvider>(context, listen: true)
                        .isDownloading,
                progress: Provider.of<WallActionProvider>(context, listen: true)
                    .progress,
                onTap: () =>
                    UserProfile.plusMember || !widget.wallModel.isPremium
                        ? _downloadHandler(context)
                        : _showPlusDialog(context, true))),
        const SizedBox(width: 10),
        Expanded(
            child: PrimaryBtnWidget(
                btnText: "Apply",
                textColor: whiteColor,
                onTap: () =>
                    UserProfile.plusMember || !widget.wallModel.isPremium
                        ? _applyImgHandler(context)
                        : _showPlusDialog(context, false)))
      ]),
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Unlock Premium Wallpaper', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$balance / ${widget.cost} Diamonds', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(canAfford ? 'You have enough diamonds!' : 'Watch ads to earn more diamonds', 
                          style: TextStyle(fontSize: 12, color: canAfford ? const Color(0xFF37C3A3) : Colors.orangeAccent)),
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
                  onPressed: _isRedeeming ? null : () async {
                    setState(() => _isRedeeming = true);
                    final success = await widget.progression.redeemWallpaper(widget.wall.id.toString(), widget.cost);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRedeeming 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('REDEEM 25 DIAMONDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsHubPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                    foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('GET DIAMONDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  AdsWidget.getPlusDialog(context, isExplorePlus: true);
                },
                child: const Text('Unlock ALL with Pro', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
