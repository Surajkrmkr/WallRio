import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

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
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller:
                Provider.of<Navigation>(context, listen: false).controller,
            primary: false,
            slivers: [
              const SliverAppBarWidget(
                showLogo: false,
                showSearchBtn: true,
                text: 'Dynamic',
                secondaryText: '',
                userProfileIconRight: false,
                showUserProfileIcon: true,
              ),
              const LiveWallsGridSliver(),
            ],
          ),
        ),
        const AdsWidget(),
      ],
    );
  }
}
