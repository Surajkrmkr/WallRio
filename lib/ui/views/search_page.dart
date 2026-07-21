import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/grid_page.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final ScrollController scrollController = ScrollController();

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
    return Scaffold(
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          Provider.of<WallRio>(context, listen: false).resetToDefault();
        },
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(controller: scrollController, slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: false,
                    centeredTitle: true,
                    showBackBtn: true,
                    clearSearchedData: true,
                    secondaryText: "it..",
                    text: "Search "),
                _buildSearchBarUI(),
                _buildBannerUI(context),
                _buildHeaderUI("Search by colors", context),
                _buildChipsUI(isColorType: true),
                _buildHeaderUI("Hot Searches", context),
                _buildChipsUI(),
                _buildHeaderUI("Top Picks", context),
                SliverToBoxAdapter(child: SizedBox(height: 10)),
                const TrendingWallGridWidget(
                    isShuffled: false, isActionGrid: true)
              ]),
              const AdsWidget(clearNavBar: false)
            ],
          ),
        ),
      ),
    );
  }

  Consumer<WallRio> _buildChipsUI({bool isColorType = false}) {
    final ScrollController scrollController = ScrollController();
    return Consumer<WallRio>(builder: (context, provider, _) {
      return SliverToBoxAdapter(
          child: Container(
              padding: EdgeInsets.symmetric(vertical: isColorType ? 15 : 0),
              height: 70,
              child: ListView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    const SizedBox(width: 20),
                    if (isColorType)
                      ...provider.colors.map((color) => Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: FilterChip(
                              backgroundColor: color,
                              labelPadding:
                                  EdgeInsets.symmetric(horizontal: 25),
                              label: Container(),
                              labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColorLight),
                              selected: false,
                              onSelected: (value) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => GridPage(
                                              categoryName: 'Colors',
                                              walls: provider
                                                  .getWallsByColor(color),
                                            )));
                              }))),
                    if (!isColorType)
                      ...provider.search.hotTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: FilterChip(
                              label: Text(tag),
                              labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColorLight),
                              selected: false,
                              onSelected: (value) {
                                provider.onSearchTap(tag);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => GridPage(
                                              categoryName: tag,
                                              walls: provider.originalWallList,
                                              isSearchMode: true,
                                            )));
                              }))),
                  ])));
    });
  }

  Widget _buildSearchBarUI() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Consumer<WallRio>(builder: (context, provider, _) {
          void navigateToSearch() => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GridPage(
                        categoryName: '',
                        walls: provider.originalWallList,
                        isSearchMode: true,
                      )));

          // This field is tap-to-navigate only — actual typing happens on
          // the destination GridPage in search mode — so it's wrapped in an
          // AbsorbPointer to keep it purely visual on iOS.
          if (Platform.isIOS) {
            return GestureDetector(
              onTap: navigateToSearch,
              child: AbsorbPointer(
                child: CupertinoSearchTextField(
                  placeholder: 'Search by wall name, tags, etc',
                ),
              ),
            );
          }

          return TextFormField(
            readOnly: true,
            onTap: navigateToSearch,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.05),
              hintText: 'Search by wall name, tags, etc',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon:
                  IconButton(onPressed: null, icon: Icon(Icons.search_rounded)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              hoverColor: blackColor.withValues(alpha: 0.05),
              border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(100))),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBannerUI(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        height: 140,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Consumer<WallRio>(builder: (context, provider, _) {
            final banner = provider.search.banner;
            return Stack(fit: StackFit.expand, children: [
              CNImage(imageUrl: banner.url),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTapHandler(context, banner),
                  splashColor: blackColor.withValues(alpha: 0.3),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildHeaderUI(String name, BuildContext context) {
    return SliverToBoxAdapter(
        child: Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
    ));
  }
}
