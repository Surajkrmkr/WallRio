import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LivePage extends StatefulWidget {
  final bool isTab;
  const LivePage({super.key, this.isTab = false});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final provider =
          Provider.of<LiveWallpaperProvider>(context, listen: false);
      if (provider.wallList.isEmpty && !provider.isLoading) {
        provider.getListFromAPI();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicatorWidget(
        onRefresh: () =>
            Provider.of<LiveWallpaperProvider>(context, listen: false)
                .getListFromAPI(),
        child: SafeArea(
          top: false,
          bottom: !widget.isTab,
          child: CustomScrollView(
            controller: widget.isTab
                ? Provider.of<Navigation>(context, listen: false)
                    .tabController(1)
                : null,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBarWidget(
                showSaleChip: true,
                showLogo: false,
                showSearchBtn: true,
                text: 'Dynamic',
                secondaryText: '',
                showBackBtn: !widget.isTab,
                showUserProfileIcon: widget.isTab,
              ),
              const LiveWallsGridSliver(),
            ],
          ),
        ),
      ),
    );
  }
}
