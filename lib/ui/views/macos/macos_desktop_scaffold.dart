import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

enum MacOSNavTab {
  desktop4k,
  categories,
  favorites,
  settings,
}

class MacOSDesktopScaffold extends StatefulWidget {
  const MacOSDesktopScaffold({super.key});

  @override
  State<MacOSDesktopScaffold> createState() => _MacOSDesktopScaffoldState();
}

class _MacOSDesktopScaffoldState extends State<MacOSDesktopScaffold>
    with TickerProviderStateMixin {
  MacOSNavTab _currentTab = MacOSNavTab.desktop4k;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _selectedCategory;

  bool _isRotating = false;

  late AnimationController _liquidBlobController;
  late AnimationController _sidebarGlowController;

  @override
  void initState() {
    super.initState();

    _liquidBlobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _sidebarGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wallRio = Provider.of<WallRio>(context, listen: false);
      if (wallRio.desktopWallList.isEmpty) {
        wallRio.fetchDesktopWallpapers();
      }
      if (UserProfile.plusMember) {
        Provider.of<FavouriteProvider>(context, listen: false)
            .getFavouritesFromFirebase();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 400) {
        Provider.of<WallRio>(context, listen: false).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _liquidBlobController.dispose();
    _sidebarGlowController.dispose();
    super.dispose();
  }

  Future<void> _rotateDesktopWallpaper() async {
    final wallRio = Provider.of<WallRio>(context, listen: false);
    final pool = wallRio.desktopWallList;

    if (pool.isEmpty) {
      ToastWidget.showToast("Loading wallpapers…");
      return;
    }

    setState(() => _isRotating = true);
    final randomWall = pool[Random().nextInt(pool.length)];

    final action = Provider.of<WallActionProvider>(context, listen: false);
    await action.applyMacOsWallpaper(context, randomWall.url);

    if (mounted) setState(() => _isRotating = false);
  }

  void _handleGlobalShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isMetaPressed &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
    }
  }

  List<Walls> _getFilteredWalls(List<Walls> input) {
    List<Walls> list = input;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((w) {
        return w.name.toLowerCase().contains(q) ||
            w.category.toLowerCase().contains(q) ||
            w.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (_selectedFilter) {
      case '4K UHD':
        list = list
            .where((w) =>
                w.tags.any((t) => t.toLowerCase().contains('4k')) ||
                w.name.toLowerCase().contains('4k'))
            .toList();
        break;
      case '5K/8K':
        list = list
            .where((w) =>
                w.tags.any((t) =>
                    t.toLowerCase().contains('5k') ||
                    t.toLowerCase().contains('8k')) ||
                w.name.toLowerCase().contains('5k') ||
                w.name.toLowerCase().contains('8k'))
            .toList();
        break;
      case 'Free':
        list = list.where((w) => !w.isPremium).toList();
        break;
      case 'Pro':
        list = list.where((w) => w.isPremium).toList();
        break;
      case 'AMOLED':
        list = list
            .where((w) =>
                w.category.toLowerCase().contains('dark') ||
                w.category.toLowerCase().contains('amoled') ||
                w.tags.any((t) => t.toLowerCase().contains('dark')))
            .toList();
        break;
      case 'Minimal':
        list = list
            .where((w) =>
                w.category.toLowerCase().contains('minimal') ||
                w.tags.any((t) => t.toLowerCase().contains('minimal')))
            .toList();
        break;
      default:
        break;
    }

    return list;
  }

  // ─────────────────────────── BUILD ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.appColors.accent;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleGlobalShortcuts,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF08080F) : const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            // Ambient liquid blobs in background
            _buildAmbientBlobs(isDark, accent),

            // Main layout
            Row(
              children: [
                _buildLiquidSidebar(context, isDark, accent),

                // Main Canvas
                Expanded(
                  child: Column(
                    children: [
                      _buildGlassToolbar(context, isDark, accent),
                      Expanded(
                        child: _buildMainContent(context, isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── AMBIENT LIQUID BLOBS ───────────────────

  Widget _buildAmbientBlobs(bool isDark, Color accent) {
    return AnimatedBuilder(
      animation: _liquidBlobController,
      builder: (context, _) {
        final t = _liquidBlobController.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + sin(t * 2 * pi) * 30,
              right: -60 + cos(t * 2 * pi) * 40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.08 : 0.06),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 + cos(t * 2 * pi + 1) * 25,
              left: 200 + sin(t * 2 * pi + 2) * 50,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.06 : 0.04),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────── LIQUID GLASS SIDEBAR ──────────────────

  Widget _buildLiquidSidebar(BuildContext context, bool isDark, Color accent) {
    return AnimatedBuilder(
      animation: _sidebarGlowController,
      builder: (context, _) {
        final glowVal = _sidebarGlowController.value;
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D0D18).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.78),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.03 + glowVal * 0.04),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for macOS traffic lights
                  const SizedBox(height: 52),

                  // ── App Brand with WallRio Icon ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Actual WallRio icon with liquid glass effect
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(
                                    alpha: 0.3 + glowVal * 0.2),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/app_icon/icon_liquid_glass.webp',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                colors: [
                                  isDark ? Colors.white : Colors.black87,
                                  accent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(rect),
                              child: const Text(
                                "WallRio",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.2),
                                    accent.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "DESKTOP",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Sidebar Navigation ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        _liquidSectionLabel("BROWSE", isDark),
                        _liquidNavItem(
                          icon: Icons.auto_awesome_mosaic_rounded,
                          label: "Desktop Walls",
                          tab: MacOSNavTab.desktop4k,
                          isDark: isDark,
                          accent: accent,
                          badge: "4K",
                        ),
                        const SizedBox(height: 20),
                        _liquidSectionLabel("LIBRARY", isDark),
                        _liquidNavItem(
                          icon: Icons.grid_view_rounded,
                          label: "Categories",
                          tab: MacOSNavTab.categories,
                          isDark: isDark,
                          accent: accent,
                        ),
                        _liquidNavItem(
                          icon: Icons.favorite_rounded,
                          label: "Favorites",
                          tab: MacOSNavTab.favorites,
                          isDark: isDark,
                          accent: accent,
                        ),
                        const SizedBox(height: 20),
                        _liquidSectionLabel("SYSTEM", isDark),
                        _liquidNavItem(
                          icon: Icons.tune_rounded,
                          label: "Settings",
                          tab: MacOSNavTab.settings,
                          isDark: isDark,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),

                  // ── Sidebar Footer ──
                  _buildSidebarFooter(isDark, accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _liquidSectionLabel(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _liquidNavItem({
    required IconData icon,
    required String label,
    required MacOSNavTab tab,
    required bool isDark,
    required Color accent,
    String? badge,
  }) {
    final isSelected = _currentTab == tab;

    return _LiquidNavButton(
      icon: icon,
      label: label,
      isSelected: isSelected,
      isDark: isDark,
      accent: accent,
      badge: badge,
      onTap: () {
        setState(() {
          _currentTab = tab;
          _selectedCategory = null;
        });
      },
    );
  }

  Widget _buildSidebarFooter(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: Column(
        children: [
          // Liquid divider
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Shuffle button with liquid glass
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isRotating ? null : _rotateDesktopWallpaper,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.15),
                          accent.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _isRotating
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              )
                            : Icon(Icons.shuffle_rounded,
                                size: 18, color: accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isRotating
                                ? "Setting wallpaper…"
                                : "Shuffle Desktop",
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: accent.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pro status
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: UserProfile.plusMember
                      ? const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                        )
                      : null,
                  color: UserProfile.plusMember
                      ? null
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Icon(
                  UserProfile.plusMember
                      ? Icons.diamond_rounded
                      : Icons.person_rounded,
                  size: 14,
                  color: UserProfile.plusMember
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserProfile.plusMember ? "WallRio Pro" : "Free Edition",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      UserProfile.plusMember
                          ? "All walls unlocked"
                          : "Upgrade for premium",
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────── GLASS TOOLBAR ──────────────────────────

  Widget _buildGlassToolbar(BuildContext context, bool isDark, Color accent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0D0D18).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.65),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Back button if inside Collection/Category
                    if (_selectedCategory != null) ...[
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 18, color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSubtitle(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar – liquid glass style
                  Container(
                    width: 280,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search wallpapers…  ⌘F",
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(Icons.close_rounded,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Theme Toggle
                  Consumer<AppThemeManager>(
                    builder: (context, themeMgr, _) {
                      return _glassIconButton(
                        isDark: isDark,
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        tooltip: "Toggle Theme",
                        onTap: () {
                          themeMgr.setMode(
                            isDark ? AppThemeMode.light : AppThemeMode.dark,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Refresh
                  _glassIconButton(
                    isDark: isDark,
                    icon: Icons.refresh_rounded,
                    tooltip: "Refresh",
                    onTap: () {
                      Provider.of<WallRio>(context, listen: false)
                          .fetchDesktopWallpapers();
                    },
                  ),
                ],
              ),

              // Filter pills (only for Desktop 4K tab)
              if (_currentTab == MacOSNavTab.desktop4k) ...[
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      '4K UHD',
                      '5K/8K',
                      'Free',
                      'Pro',
                      'AMOLED',
                      'Minimal',
                    ].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _LiquidFilterChip(
                          label: filter,
                          isSelected: isSelected,
                          isDark: isDark,
                          accent: accent,
                          onTap: () => setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(icon,
                size: 18, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  // ──────────────── TITLES & SUBTITLES ────────────────────────

  String _getTitle() {
    if (_selectedCategory != null) return _selectedCategory!;

    switch (_currentTab) {
      case MacOSNavTab.desktop4k:
        return "Desktop Wallpapers";
      case MacOSNavTab.categories:
        return "Categories";
      case MacOSNavTab.favorites:
        return "Favorites";
      case MacOSNavTab.settings:
        return "Settings";
    }
  }

  String _getSubtitle() {
    final wallRio = Provider.of<WallRio>(context);
    if (_selectedCategory != null) {
      final walls = wallRio.categories?[_selectedCategory] ?? [];
      return "${walls.length} wallpapers in $_selectedCategory";
    }

    switch (_currentTab) {
      case MacOSNavTab.desktop4k:
        return "${wallRio.desktopWallList.length} ultra-high resolution wallpapers";
      case MacOSNavTab.categories:
        return "${wallRio.categories?.length ?? 0} desktop categories";
      case MacOSNavTab.favorites:
        return "Your saved wallpapers";
      case MacOSNavTab.settings:
        return "Application preferences";
    }
  }

  // ──────────────── CONTENT SWITCHER ──────────────────────────

  Widget _buildMainContent(BuildContext context, bool isDark) {
    if (_selectedCategory != null) {
      final wallRio = Provider.of<WallRio>(context);
      final raw = wallRio.categories?[_selectedCategory] ?? [];
      final walls = raw.whereType<Walls>().toList();
      return _buildWallpaperGrid(context, walls, isLandscape: true);
    }

    switch (_currentTab) {
      case MacOSNavTab.desktop4k:
        return _buildDesktop4KView(context, isDark);
      case MacOSNavTab.categories:
        return _buildCategoriesView(context, isDark);
      case MacOSNavTab.favorites:
        return _buildFavoritesView(context, isDark);
      case MacOSNavTab.settings:
        return const SettingsPage();
    }
  }

  // ──────────────── DESKTOP 4K VIEW ──────────────────────────

  Widget _buildDesktop4KView(BuildContext context, bool isDark) {
    return Consumer<WallRio>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.desktopWallList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    'assets/app_icon/icon_liquid_glass.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading wallpapers…",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        final walls = _getFilteredWalls(provider.desktopWallList);
        if (walls.isEmpty) {
          return _buildEmptyState(
            icon: Icons.desktop_windows_rounded,
            title: "No wallpapers found",
            subtitle: "Try clearing your search or changing filters.",
          );
        }

        return _buildWallpaperGrid(context, walls, isLandscape: true);
      },
    );
  }

  // ──────────────── CATEGORIES VIEW ──────────────────────────

  Widget _buildCategoriesView(BuildContext context, bool isDark) {
    final accent = context.appColors.accent;
    return Consumer<WallRio>(
      builder: (context, provider, _) {
        final categories = provider.categories ?? {};
        if (categories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.grid_view_rounded,
            title: "No categories available",
            subtitle: "Categories are loading…",
          );
        }

        final keys = categories.keys.toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final colCount = (constraints.maxWidth / 250).floor().clamp(2, 6);

            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(28),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colCount,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.5,
              ),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final categoryName = keys[index];
                final walls = categories[categoryName] ?? [];
                final sampleWall = walls.isNotEmpty ? walls.first : null;

                return _LiquidCategoryCard(
                  categoryName: categoryName,
                  wallCount: walls.length,
                  thumbnailUrl: sampleWall?.thumbnail ?? '',
                  isDark: isDark,
                  accent: accent,
                  onTap: () => setState(() => _selectedCategory = categoryName),
                );
              },
            );
          },
        );
      },
    );
  }

  // ──────────────── FAVORITES VIEW ───────────────────────────

  Widget _buildFavoritesView(BuildContext context, bool isDark) {
    return Consumer<FavouriteProvider>(
      builder: (context, favProvider, _) {
        final favList = favProvider.wallList;
        if (favList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border_rounded,
            title: "No favorites yet",
            subtitle: "Hover on wallpapers and tap the heart to save!",
          );
        }

        return _buildWallpaperGrid(context, favList, isLandscape: true);
      },
    );
  }

  // ──────────────── WALLPAPER GRID ───────────────────────────

  Widget _buildWallpaperGrid(
    BuildContext context,
    List<Walls> walls, {
    required bool isLandscape,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final targetWidth = isLandscape ? 340.0 : 220.0;
        final colCount =
            (width / targetWidth).floor().clamp(2, isLandscape ? 5 : 8);
        final aspectRatio = isLandscape ? 16 / 10 : 0.58;

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: aspectRatio,
          ),
          itemCount: walls.length,
          itemBuilder: (context, index) {
            final wall = walls[index];
            return MacOSWallpaperCard(
              wall: wall,
              isLandscape: isLandscape,
              onTap: () {
                MacOSWallpaperPreviewDialog.show(
                  context,
                  wallList: walls,
                  initialIndex: index,
                );
              },
              onSetDesktop: () {
                final action =
                    Provider.of<WallActionProvider>(context, listen: false);
                action.applyMacOsWallpaper(context, wall.url);
              },
              onDownload: () {
                final action =
                    Provider.of<WallActionProvider>(context, listen: false);
                action.saveMacOsWallpaper(
                    context, wall.url, "${wall.name}_${wall.id}");
              },
            );
          },
        );
      },
    );
  }

  // ──────────────── EMPTY STATE ──────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WallRio icon in empty state
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/app_icon/icon_liquid_glass.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Icon(
            icon,
            size: 40,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIQUID SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════

/// Sidebar navigation item with liquid hover/selection effects
class _LiquidNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color accent;
  final String? badge;
  final VoidCallback onTap;

  const _LiquidNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  State<_LiquidNavButton> createState() => _LiquidNavButtonState();
}

class _LiquidNavButtonState extends State<_LiquidNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final hoverOrActive = active || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [
                      widget.accent.withValues(alpha: 0.18),
                      widget.accent.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : (_hovered
                    ? LinearGradient(
                        colors: [
                          widget.accent.withValues(alpha: 0.08),
                          widget.accent.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null),
            color: hoverOrActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(
                    color: widget.accent.withValues(alpha: 0.15),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Animated icon with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: active
                      ? widget.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: active
                      ? widget.accent
                      : (_hovered
                          ? (widget.isDark ? Colors.white : Colors.black87)
                          : (widget.isDark ? Colors.white54 : Colors.black54)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? widget.accent
                        : (widget.isDark ? Colors.white : Colors.black87),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accent,
                        widget.accent.withValues(alpha: 0.7)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liquid glass filter chip for toolbar
class _LiquidFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _LiquidFilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_LiquidFilterChip> createState() => _LiquidFilterChipState();
}

class _LiquidFilterChipState extends State<_LiquidFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      widget.accent,
                      widget.accent.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: widget.isSelected
                ? null
                : (_hovered
                    ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06))
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03))),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent.withValues(alpha: 0.5)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
              color: widget.isSelected
                  ? Colors.white
                  : (widget.isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

/// Liquid Category Card with frosted label
class _LiquidCategoryCard extends StatefulWidget {
  final String categoryName;
  final int wallCount;
  final String thumbnailUrl;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _LiquidCategoryCard({
    required this.categoryName,
    required this.wallCount,
    required this.thumbnailUrl,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_LiquidCategoryCard> createState() => _LiquidCategoryCardState();
}

class _LiquidCategoryCardState extends State<_LiquidCategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
              _hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.5)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.accent.withValues(alpha: 0.2)
                    : Colors.black
                        .withValues(alpha: widget.isDark ? 0.25 : 0.05),
                blurRadius: _hovered ? 16 : 6,
                offset: Offset(0, _hovered ? 6 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.thumbnailUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                // Liquid glass overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                // Centered frosted label
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.categoryName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${widget.wallCount} wallpapers",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
