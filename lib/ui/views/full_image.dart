import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  _secureScreen() => {};
  bool _showPalette = false;

  // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

  @override
  void initState() {
    _secureScreen();
    Future.delayed(Duration.zero, () {
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

  void _downloadHandler(context) {
    Provider.of<WallActionProvider>(context, listen: false).downloadImg(
        widget.wallModel.url,
        "${widget.wallModel.name}_${widget.wallModel.id}");
  }

  void _applyImgHandler(context) {
    Provider.of<WallActionProvider>(context, listen: false)
        .setWall(widget.wallModel.url, context);
  }

  void _showExplorePlusDialog(context) {
    showDialog(
        context: context,
        builder: (context) =>
            AdsWidget.getPlusDialog(context, isExplorePlus: true));
  }

  void _showPlusDialog(context, isForDownload) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AdsWidget.getPlusDialog(context, onWatchAdClick: () {
              Provider.of<AdsProvider>(context, listen: false).loadRewardedAd(
                  context,
                  onRewarded: () => isForDownload
                      ? _downloadHandler(context)
                      : _applyImgHandler(context));
            }));
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
            Colors.black.withOpacity(0.9),
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
          backgroundColor: blackColor.withOpacity(0.1),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTagsUI(),
                    SizedBox(height: 10),
                    _buildDetailsUI(),
                  ],
                ),
                _buildUtilsUI(),
              ],
            ),
            _buildActionBtnUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsUI() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.only(left: 20.0),
      child: Wrap(
        spacing: 10,
        children: widget.wallModel.tags
            .map((tag) => ActionChip(
                  label: Text(
                    tag,
                    style: TextStyle(color: whiteColor),
                  ),
                  backgroundColor: whiteColor.withOpacity(0.3),
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
    return _buildBtn(color: whiteColor, iconData: Icons.share, onTap: () {});
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
                  : provider.addToFav(wall: widget.wallModel)
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
                onTap: () =>
                    UserProfile.plusMember || !widget.wallModel.isPremium
                        ? _applyImgHandler(context)
                        : _showPlusDialog(context, false)))
      ]),
    );
  }
}
