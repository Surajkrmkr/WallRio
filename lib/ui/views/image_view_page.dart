// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:wallrio/model/export.dart';
// import 'package:wallrio/provider/export.dart';
// import 'package:wallrio/services/export.dart';
// import 'package:wallrio/ui/views/export.dart';
// import 'package:wallrio/ui/widgets/export.dart';

// // ignore: must_be_immutable
// class ImageViewPage extends StatelessWidget {
//   final Walls wallModel;
//   ImageViewPage({super.key, required this.wallModel});

//   bool _isInitialized = false;

//   void copyColor(Color color) async {
//     String code = "#ff${color.toString().substring(10, 16)}";
//     await Clipboard.setData(ClipboardData(text: code));
//     ToastWidget.showToast("$code Color copied");
//   }

//   void _onTapHandler(context, model) {
//     Navigator.push(context,
//         MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
//   }

//   void _downloadHandler(context) {
//     Provider.of<WallActionProvider>(context, listen: false)
//         .downloadImg(wallModel.url, "${wallModel.name}_${wallModel.id}");
//   }

//   void _applyImgHandler(context) {
//     Provider.of<WallActionProvider>(context, listen: false)
//         .setWall(wallModel.url, context);
//   }

//   void _showPlusDialog(context, isForDownload) {
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) =>
//             AdsWidget.getPlusDialog(context, onWatchAdClick: () {
//               Provider.of<AdsProvider>(context, listen: false).loadRewardedAd(
//                   context,
//                   onRewarded: () => isForDownload
//                       ? _downloadHandler(context)
//                       : _applyImgHandler(context));
//             }));
//   }

//   void _showExplorePlusDialog(context) {
//     showDialog(
//         context: context,
//         builder: (context) =>
//             AdsWidget.getPlusDialog(context, isExplorePlus: true));
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       Future.delayed(Duration.zero, () {
//         Provider.of<WallDetails>(context, listen: false)
//           ..getColorPalette(wallModel.thumbnail)
//           ..getWallDetails(wallModel.url);
//       });
//       _isInitialized = false;
//     }
//     return Scaffold(
//         body: SafeArea(
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             BackBtnWidget(color: Theme.of(context).primaryColorLight),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Hero(
//                 tag: wallModel.url,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(25),
//                   child: SizedBox(
//                       height: MediaQuery.of(context).size.height * 0.40,
//                       width: MediaQuery.of(context).size.width,
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           CNImage(
//                             imageUrl: wallModel.url,
//                             isOriginalImg: true,
//                           ),
//                           const Align(
//                               alignment: Alignment.topRight,
//                               child: Padding(
//                                 padding: EdgeInsets.all(20.0),
//                                 child: Icon(
//                                   Icons.fullscreen,
//                                   color: whiteColor,
//                                 ),
//                               )),
//                           Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               onTap: () => _onTapHandler(context, wallModel),
//                               splashColor: blackColor.withOpacity(0.3),
//                             ),
//                           ),
//                         ],
//                       )),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const AdsWidget(bottomPadding: 20),
//                     _buildHeaderUI(context),
//                     const SizedBox(height: 20),
//                     _buildActionBtnUI(context),
//                     const SizedBox(height: 20),
//                     _buildDetailsUI(context),
//                     const SizedBox(height: 20),
//                     _buildColorsUI(context)
//                   ]),
//             )
//           ],
//         ),
//       ),
//     ));
//   }

//   Column _buildColorsUI(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Colors", style: Theme.of(context).textTheme.displayMedium),
//         const SizedBox(height: 10),
//         Text("Tap swatches to copy",
//             style: Theme.of(context).textTheme.titleSmall),
//         const SizedBox(height: 10),
//         Consumer<WallDetails>(
//             builder: (context, provider, _) => provider.isColorPaletteLoading
//                 ? const ShimmerWidget(
//                     height: 60,
//                     width: double.infinity,
//                     radius: 15,
//                   )
//                 : SizedBox(
//                     height: 60,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       children: provider.colorSwatch
//                           .map((color) => Padding(
//                                 padding: const EdgeInsets.only(right: 10.0),
//                                 child: InkWell(
//                                     onTap: () => copyColor(color),
//                                     borderRadius: BorderRadius.circular(15),
//                                     child: Ink(
//                                       height: 60,
//                                       width: 60,
//                                       decoration: BoxDecoration(
//                                           color: color,
//                                           borderRadius:
//                                               BorderRadius.circular(15)),
//                                     )),
//                               ))
//                           .toList(),
//                     ),
//                   ))
//       ],
//     );
//   }

//   Widget _buildDetailsUI(BuildContext context) {
//     return Consumer<WallDetails>(builder: (context, provider, _) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Details", style: Theme.of(context).textTheme.displayMedium),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               Text("Category : ",
//                   style: Theme.of(context).textTheme.titleSmall),
//               Text(wallModel.category,
//                   style: Theme.of(context).textTheme.bodyLarge),
//             ],
//           ),
//           Row(
//             children: [
//               Text("Size : ", style: Theme.of(context).textTheme.titleSmall),
//               provider.isImageDetailsLoading
//                   ? const ShimmerWidget(height: 13, width: 70)
//                   : Text(provider.size,
//                       style: Theme.of(context).textTheme.bodyLarge),
//             ],
//           ),
//           Row(
//             children: [
//               Text("Dimension : ",
//                   style: Theme.of(context).textTheme.titleSmall),
//               provider.isImageDetailsLoading
//                   ? const ShimmerWidget(height: 13, width: 70)
//                   : Text("${provider.width} * ${provider.height}",
//                       style: Theme.of(context).textTheme.bodyLarge),
//             ],
//           ),
//         ],
//       );
//     });
//   }

//   Row _buildActionBtnUI(context) {
//     return Row(children: [
//       Expanded(
//           child: PrimaryBtnWidget(
//               btnText: "Download",
//               onTap: () => UserProfile.plusMember || !wallModel.isPremium
//                   ? _downloadHandler(context)
//                   : _showPlusDialog(context, true))),
//       const SizedBox(width: 10),
//       Expanded(
//           child: PrimaryBtnWidget(
//               btnText: "Apply",
//               onTap: () => UserProfile.plusMember || !wallModel.isPremium
//                   ? _applyImgHandler(context)
//                   : _showPlusDialog(context, false)))
//     ]);
//   }

//   Row _buildHeaderUI(BuildContext context) {
//     return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(wallModel.name, style: Theme.of(context).textTheme.displayMedium),
//         const SizedBox(height: 5),
//         Text("Designed By ${wallModel.author}",
//             style: Theme.of(context).textTheme.titleSmall)
//       ]),
//       Consumer<FavouriteProvider>(builder: (context, provider, _) {
//         final bool isFav = provider.isSelectedAsFav(wallModel.url);
//         if (provider.isLoading) {
//           return _buildFavBtn(
//               color: Theme.of(context).primaryColorLight,
//               iconData: Icons.favorite_border_rounded,
//               onTap: () {});
//         }
//         return _buildFavBtn(
//             color:
//                 isFav ? Colors.redAccent : Theme.of(context).primaryColorLight,
//             iconData:
//                 isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
//             onTap: () => UserProfile.plusMember
//                 ? isFav
//                     ? provider.removeFromFav(id: wallModel.id)
//                     : provider.addToFav(wall: wallModel)
//                 : _showExplorePlusDialog(context));
//       })
//     ]);
//   }

//   IconButton _buildFavBtn(
//       {required Function() onTap,
//       required IconData iconData,
//       required Color color}) {
//     return IconButton(onPressed: onTap, icon: Icon(iconData, color: color));
//   }
// }
