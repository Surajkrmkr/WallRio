import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class MacOSWallpaperPreviewDialog extends StatefulWidget {
  final List<Walls> wallList;
  final int initialIndex;

  const MacOSWallpaperPreviewDialog({
    super.key,
    required this.wallList,
    required this.initialIndex,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Walls> wallList,
    required int initialIndex,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => MacOSWallpaperPreviewDialog(
        wallList: wallList,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<MacOSWallpaperPreviewDialog> createState() =>
      _MacOSWallpaperPreviewDialogState();
}

class _MacOSWallpaperPreviewDialogState
    extends State<MacOSWallpaperPreviewDialog> {
  late int _currentIndex;
  bool _showDesktopMockup = false;
  final FocusNode _focusNode = FocusNode();

  Walls get _currentWall => widget.wallList[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.wallList.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadDetails();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadDetails() {
    if (!mounted) return;
    final wall = _currentWall;
    Provider.of<WallDetails>(context, listen: false)
      ..getColorPalette(wall.thumbnail.isNotEmpty ? wall.thumbnail : wall.url)
      ..getWallDetails(wall.url);
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadDetails();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.wallList.length - 1) {
      setState(() => _currentIndex++);
      _loadDetails();
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goToNext();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        setState(() => _showDesktopMockup = !_showDesktopMockup);
      }
    }
  }

  String _getQualityBadge(Walls wall) {
    final lowerTags = wall.tags.map((t) => t.toLowerCase()).toList();
    final lowerName = wall.name.toLowerCase();

    if (lowerTags.any((t) => t.contains('8k') || t.contains('7680')) ||
        lowerName.contains('8k') ||
        lowerName.contains('7680')) {
      return '8K UHD';
    }
    if (lowerTags.any((t) => t.contains('5k') || t.contains('5120')) ||
        lowerName.contains('5k') ||
        lowerName.contains('5120')) {
      return '5K Retina';
    }
    if (lowerTags.any((t) => t.contains('4k') || t.contains('3840')) ||
        lowerName.contains('4k') ||
        lowerName.contains('3840')) {
      return '4K UHD';
    }
    return 'Ultra HD';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final wall = _currentWall;
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.88).clamp(860.0, 1160.0);
    final dialogHeight = (size.height * 0.86).clamp(580.0, 780.0);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Center(
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF181822) : const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left 68%: Wallpaper Preview Area
                  Expanded(
                    flex: 68,
                    child: _buildPreviewCanvas(context, wall, isDarkMode),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),

                  // Right 32%: Details & Actions Panel
                  Expanded(
                    flex: 32,
                    child: _buildDetailsSidebar(context, wall, isDarkMode),
                  ),
                ],
              ),

              // Close button (top right)
              Positioned(
                top: 14,
                right: 14,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Left Preview Area with desktop frame & controls
  Widget _buildPreviewCanvas(
      BuildContext context, Walls wall, bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF0F0F14) : const Color(0xFFEAEBED),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Centered wallpaper container with desktop mockup
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full image
                      CachedNetworkImage(
                        imageUrl:
                            wall.url.isNotEmpty ? wall.url : wall.thumbnail,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CachedNetworkImage(
                          imageUrl: wall.thumbnail,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // macOS Mockup Overlay: Menu Bar and Dock
                      if (_showDesktopMockup) ...[
                        // macOS Top Menu Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 22,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Row(
                              children: [
                                Icon(Icons.apple,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 10),
                                Text(
                                  "Finder  File  Edit  View  Go  Window  Help",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.wifi, color: Colors.white, size: 11),
                                SizedBox(width: 8),
                                Icon(Icons.battery_full_rounded,
                                    color: Colors.white, size: 11),
                                SizedBox(width: 8),
                                Text(
                                  "Wed 9:41 AM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // macOS Bottom Dock Mockup
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _dockIcon(Icons.face_rounded, Colors.blue),
                                  _dockIcon(Icons.public_rounded, Colors.cyan),
                                  _dockIcon(
                                      Icons.chat_bubble_rounded, Colors.green),
                                  _dockIcon(
                                      Icons.mail_rounded, Colors.blueAccent),
                                  _dockIcon(Icons.photo_library_rounded,
                                      Colors.orange),
                                  _dockIcon(Icons.music_note_rounded,
                                      Colors.redAccent),
                                  _dockIcon(
                                      Icons.settings_rounded, Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top left overlay controls (Mockup toggle)
          Positioned(
            top: 18,
            left: 20,
            child: Row(
              children: [
                _pillButton(
                  icon: _showDesktopMockup
                      ? Icons.desktop_windows_rounded
                      : Icons.crop_original_rounded,
                  label: _showDesktopMockup ? "Mockup On" : "Preview Mockup",
                  isActive: _showDesktopMockup,
                  onTap: () =>
                      setState(() => _showDesktopMockup = !_showDesktopMockup),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                Text(
                  "${_currentIndex + 1} of ${widget.wallList.length}",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Previous Wallpaper Arrow (Left)
          if (_currentIndex > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _navArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _goToPrevious,
                  isDarkMode: isDarkMode,
                ),
              ),
            ),

          // Next Wallpaper Arrow (Right)
          if (_currentIndex < widget.wallList.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _navArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _goToNext,
                  isDarkMode: isDarkMode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dockIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 13),
      ),
    );
  }

  Widget _navArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (isDarkMode ? const Color(0xFF20202A) : Colors.white)
                .withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? context.appColors.accent
                : (isDarkMode ? Colors.black45 : Colors.white)
                    .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? context.appColors.accent
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : (isDarkMode ? Colors.white70 : Colors.black87),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Right Sidebar with metadata, colors & primary desktop actions
  Widget _buildDetailsSidebar(
      BuildContext context, Walls wall, bool isDarkMode) {
    final qualityBadge = _getQualityBadge(wall);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality & Premium Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  qualityBadge,
                  style: TextStyle(
                    color: context.appColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (wall.isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PRO EXCLUSIVE",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Wallpaper Title
          Text(
            wall.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),

          // Category & Author
          Text(
            "Category: ${wall.category.isNotEmpty ? wall.category : 'General'}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 22),

          // PRIMARY ACTION: Set as Mac Desktop Wallpaper
          Consumer<WallActionProvider>(
            builder: (context, action, _) {
              return SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: action.isApplying
                      ? null
                      : () => action.applyMacOsWallpaper(context, wall.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: action.isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.desktop_windows_rounded, size: 18),
                  label: Text(
                    action.isApplying
                        ? "Setting Wallpaper…"
                        : "Set as Desktop Wallpaper",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // SECONDARY ACTION: Download to Downloads Folder
          Consumer<WallActionProvider>(
            builder: (context, action, _) {
              return SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: action.isDownloading
                      ? null
                      : () => action.saveMacOsWallpaper(
                          context, wall.url, "${wall.name}_${wall.id}"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: action.isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    action.isDownloading ? "Saving…" : "Save to Downloads",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Action Row (Favorite + Share)
          Row(
            children: [
              Consumer<FavouriteProvider>(
                builder: (context, favProvider, _) {
                  final isFav =
                      favProvider.isSelectedAsFav(wall.url, id: wall.id);
                  return Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (UserProfile.plusMember) {
                          if (isFav) {
                            favProvider.removeFromFav(id: wall.id);
                          } else {
                            favProvider.addToFav(context, wall: wall);
                          }
                        } else {
                          ToastWidget.showToast("Plus feature");
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFav
                            ? Colors.redAccent
                            : (isDarkMode ? Colors.white70 : Colors.black87),
                        side: BorderSide(
                          color: isFav
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : (isDarkMode
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isFav ? "Favorited" : "Favorite",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: wall.url));
                    ToastWidget.showToast("Wallpaper URL copied!");
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white70 : Colors.black87,
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label:
                      const Text("Copy Link", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Color Palette Swatches
          Text(
            "Color Palette",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Consumer<WallDetails>(
            builder: (context, details, _) {
              if (details.colorSwatch.isEmpty) {
                return Text(
                  "Extracting palette…",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.colorSwatch.map((c) {
                  return Tooltip(
                    message: "Copy hex",
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          final hex =
                              '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                          Clipboard.setData(ClipboardData(text: hex));
                          ToastWidget.showToast("Copied color $hex");
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDarkMode ? Colors.white24 : Colors.black12,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Tags
          if (wall.tags.isNotEmpty) ...[
            Text(
              "Tags",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: wall.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#$tag",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
