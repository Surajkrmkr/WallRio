import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  void _onLongPressHandler(BuildContext context, dynamic model) {
    showModalBottomSheet(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(BuildContext context, dynamic model) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicatorWidget(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              primary: false,
              slivers: [
                const SliverAppBarWidget(
                    showLogo: false,
                    showSearchBtn: true,
                    text: "Categories",
                    secondaryText: "",
                    userProfileIconRight: false,
                    showUserProfileIcon: true),
                _buildCategoryUI(),
              ],
            ),
          ),
          const AdsWidget(),
        ],
      ),
    );
  }

  Widget _buildCategoryUI() {
    return Consumer<WallRio>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildShimmerUI(),
        );
      }
      if (provider.error.isNotEmpty) {
        return SliverFillRemaining(child: Center(child: Text(provider.error)));
      }
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: 80),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: provider.categories!.length,
            (context, index) {
              final categoryName =
                  provider.categories!.keys.elementAt(index);
              final categoryWalls =
                  provider.categories!.values.elementAt(index);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 350 + index * 60),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _buildCategorySection(
                    categoryName, categoryWalls, context),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildCategorySection(
      String name, List<Walls?> walls, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(name, walls, context),
          const SizedBox(height: 14),
          _buildHorizontalScroll(walls, context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String name, List<Walls?> walls, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: bgDarkAccentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bgDarkAccentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${walls.length}',
              style: const TextStyle(
                color: bgDarkAccentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GridPage(categoryName: name, walls: walls),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: bgDarkAccentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bgDarkAccentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'View all',
                    style: TextStyle(
                      color: bgDarkAccentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: bgDarkAccentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScroll(List<Walls?> walls, BuildContext context) {
    final count = walls.length < 8 ? walls.length : 8;
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) =>
            _buildCard(walls[i]!, context, i),
      ),
    );
  }

  Widget _buildCard(Walls wall, BuildContext context, int cardIndex) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + cardIndex * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(24 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Hero(
        tag: wall.url,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 120,
            child: Stack(fit: StackFit.expand, children: [
              CNImage(imageUrl: wall.thumbnail),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 70,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onTapHandler(context, wall),
                  onLongPress: () => _onLongPressHandler(context, wall),
                  splashColor: blackColor.withValues(alpha: 0.3),
                ),
              ),
              VerifyIconWidget(visibility: !wall.isPremium),
            ]),
          ),
        ),
      ),
    );
  }

  SliverList _buildShimmerUI() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: 4,
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  ShimmerWidget(height: 22, width: 4, radius: 4),
                  SizedBox(width: 10),
                  ShimmerWidget(height: 18, width: 110, radius: 8),
                  SizedBox(width: 8),
                  ShimmerWidget(height: 24, width: 34, radius: 20),
                  Spacer(),
                  ShimmerWidget(height: 28, width: 85, radius: 20),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => const ShimmerWidget(
                      height: 210, width: 120, radius: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
