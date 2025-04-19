import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  void _onLongPressHandler(context, model) {
    showModalBottomSheet(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(context, model) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ImageViewPage(wallModel: model)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: Provider.of<Navigation>(context).controller,
          slivers: [
            const SliverAppBarWidget(
                showLogo: false,
                showSearchBtn: true,
                text: "Wall",
                secondaryText: "Rio",
                userProfileIconRight: false,
                showUserProfileIcon: true),
            _buildListUI(context)
          ],
        ),
        const AdsWidget()
      ],
    );
  }

  Widget _buildListUI(context) {
    return Consumer<FavouriteProvider>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
            sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.6,
                children: List.generate(
                    8,
                    (index) => const ShimmerWidget(
                          height: 100,
                          width: double.infinity,
                          radius: 25,
                        ))));
      }
      List<Walls> walls = provider.wallList;
      if (walls.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Lottie.asset('assets/lottie/empty.json',
                width: MediaQuery.of(context).size.width * 0.7),
          ),
        );
      }
      walls = walls.reversed.toList();
      return SliverPadding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
          sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.6),
              delegate: SliverChildBuilderDelegate(
                  childCount: walls.length,
                  (context, index) => Hero(
                        tag: walls[index].url,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Stack(fit: StackFit.expand, children: [
                            CNImage(imageUrl: walls[index].thumbnail),
                            Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    onTap: () =>
                                        _onTapHandler(context, walls[index]),
                                    onLongPress: () => _onLongPressHandler(
                                        context, walls[index]),
                                    splashColor: blackColor.withOpacity(0.3))),
                            _buildImgDetailsUI(context, walls[index]),
                          ]),
                        ),
                      ))));
    });
  }

  Align _buildImgDetailsUI(BuildContext context, Walls wall) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          padding: const EdgeInsets.only(left: 15, right: 5),
          height: 65,
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wall.name,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 12),
                    ),
                    Text(
                      "Designed by ${wall.author}",
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 10),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
