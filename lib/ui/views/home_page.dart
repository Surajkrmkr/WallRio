import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicatorWidget(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: Provider.of<Navigation>(context).controller,
              primary: false,
              slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: true,
                    text: "Wall",
                    secondaryText: "Rio",
                    userProfileIconRight: false,
                    showUserProfileIcon: true),
                SliverToBoxAdapter(child: BannerWidget()),
                const TrendingWallGridWidget()
              ],
            ),
          ),
          // const SizedBox(height: 10),
          const AdsWidget()
        ],
      ),
    );
  }
}
