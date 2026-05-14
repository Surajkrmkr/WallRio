import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class GridPage extends StatefulWidget {
  final String categoryName;
  final List<Walls?> walls;
  final bool isSearchMode;
  const GridPage(
      {super.key,
      required this.categoryName,
      required this.walls,
      this.isSearchMode = false});

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    textEditingController.text = widget.categoryName;
    if (widget.isSearchMode && widget.categoryName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<WallRio>(context, listen: false)
            .onSearchTap(widget.categoryName);
      });
    }
    super.initState();
  }

  void _onLongPressHandler(context, model) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => ImageBottomSheet(wallModel: model));
  }

  void _onTapHandler(context, model) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FullImage(wallModel: model)));
  }

  void _cancelSearchBar(BuildContext context) {
    textEditingController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                widget.isSearchMode
                    ? _buildSearchBarUI()
                    : SliverAppBarWidget(
                        showLogo: false,
                        showSearchBtn: false,
                        text: widget.categoryName,
                        showBackBtn: true),
                _buildListUI(context)
              ],
            ),
            const AdsWidget()
          ],
        ),
      ),
    );
  }

  List<dynamic> _buildItemList(List<Walls?> walls) {
    final items = <dynamic>[];
    int wallIndex = 0;
    int rowCount = 0;
    while (wallIndex < walls.length) {
      final end = (wallIndex + 3).clamp(0, walls.length);
      items.add(walls.sublist(wallIndex, end));
      wallIndex += 3;
      rowCount++;
      if (rowCount % 3 == 0 && wallIndex < walls.length) {
        items.add(true);
      }
    }
    return items;
  }

  Widget _buildListUI(context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      sliver: Consumer<WallRio>(builder: (context, provider, _) {
        final walls = widget.isSearchMode
            ? List<Walls?>.from(provider.queryWallList)
            : widget.walls;
        final items = _buildItemList(walls);
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: items.length,
            (context, index) {
              final item = items[index];
              if (item is bool) return _buildAdRow();
              return _buildWallRow(item as List<Walls?>, context);
            },
          ),
        );
      }),
    );
  }

  Widget _buildWallRow(List<Walls?> rowWalls, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: i < rowWalls.length && rowWalls[i] != null
                  ? AspectRatio(
                      aspectRatio: 0.5,
                      child: _buildCard(rowWalls[i]!, context),
                    )
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: AdsWidget(size: AdSize.mediumRectangle),
      ),
    );
  }

  Widget _buildCard(Walls wall, BuildContext context) {
    return Hero(
      tag: wall.url,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          CNImage(imageUrl: wall.thumbnail),
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
    );
  }



  Widget _buildSearchBarUI() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Consumer<WallRio>(builder: (context, provider, _) {
          return TextFormField(
            controller: textEditingController,
            cursorColor: Theme.of(context).primaryColorLight,
            cursorWidth: 3,
            cursorRadius: const Radius.circular(10),
            onTap: () {
              provider.clearSelectedTags();
              scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut);
            },
            onChanged: (query) => provider.onSearchTap(query),
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).primaryColorLight.withValues(alpha: 0.05),
              hintText: 'Search by wall name, tags, etc',
              hintStyle: const TextStyle(fontSize: 14),
              suffixIcon: IconButton(
                  onPressed: textEditingController.text.isNotEmpty
                      ? () {
                          provider.resetToDefault();
                          _cancelSearchBar(context);
                        }
                      : null,
                  icon: Icon(textEditingController.text.isNotEmpty
                      ? Icons.cancel
                      : Icons.search_rounded)),
              prefixIcon:
                  BackBtnWidget(color: Theme.of(context).primaryColorLight),
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
}
