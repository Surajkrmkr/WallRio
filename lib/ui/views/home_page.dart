import 'package:flutter/material.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Free', 'Pro', 'Live'];

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
                    text: "Wall",
                    secondaryText: "Rio",
                    userProfileIconRight: false,
                    showUserProfileIcon: true,
                    showSaleChip: true),
                SliverToBoxAdapter(child: BannerWidget()),
                SliverToBoxAdapter(child: _buildFilterRow()),
                if (_filterIndex == 3)
                  const LiveWallsGridSliver()
                else
                  TrendingWallGridWidget(filterIndex: _filterIndex),
              ],
            ),
          ),
          const AdsWidget()
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgDark2Color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: List.generate(
            _filters.length,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == _filterIndex
                        ? bgDarkAccentColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    _filters[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == _filterIndex
                          ? whiteColor
                          : whiteColor.withValues(alpha: 0.55),
                      fontWeight:
                          i == _filterIndex ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
