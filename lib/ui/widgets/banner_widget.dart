import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class BannerWidget extends StatelessWidget {
  final CarouselSliderController carouselController =
      CarouselSliderController();
  BannerWidget({super.key});

  void _onTapHandler(BuildContext context, Banners banner) {
    if (banner.category.isEmpty) {
      LaunchUrlWidget.launch(banner.link);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      final provider = Provider.of<WallRio>(context, listen: false);
      final categoryWalls = provider.categories![banner.category];
      if (categoryWalls != null) {
        return GridPage(
          categoryName: banner.category,
          walls: categoryWalls,
        );
      }

      final collection = provider.collections.firstWhere(
        (c) => c.name.toLowerCase() == banner.category.toLowerCase(),
        orElse: () => Collections(id: 0, name: "", productId: "", walls: []),
      );
      if (collection.name.isNotEmpty) {
        return GridPage(
          categoryName: collection.name,
          walls: collection.walls ?? [],
          collection: collection,
        );
      }

      return GridPage(
        categoryName: banner.category,
        walls: const [],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading || provider.bannerList.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerWidget(
              height: 220,
              width: double.infinity,
              radius: 25,
            ),
          ),
        );
      }
      return SizedBox(
        height: 250,
        child: Column(
          children: [
            Expanded(
              child: CarouselSlider(
                carouselController: carouselController,
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) =>
                      provider.setBannerIndex = index,
                ),
                items: provider.bannerList.map((banner) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(fit: StackFit.expand, children: [
                      CNImage(imageUrl: banner.url),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onTapHandler(context, banner),
                          splashColor: blackColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: EdgeInsets.all(3),
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1)),
              child: AnimatedSmoothIndicator(
                  activeIndex: provider.bannerIndex,
                  count: provider.bannerList.length,
                  effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 2,
                      activeDotColor: Theme.of(context).primaryColorLight),
                  onDotClicked: (index) =>
                      carouselController.animateToPage(index)),
            )
          ],
        ),
      );
    });
  }
}
