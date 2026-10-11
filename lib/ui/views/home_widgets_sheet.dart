import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

/// Opens a bottom sheet previewing WallRio's three Android home-screen
/// widgets (Static / Video / Desktop wallpapers) with a button that requests
/// the launcher pin the selected one directly — reached from the "Widget"
/// card in Settings > Personalization.
void showHomeScreenWidgetsSheet(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  CNBottomSheet.show(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: Platform.isIOS,
    constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => const HomeWidgetsSheet(),
  );
}

class _WidgetPreviewSpec {
  final String type; // matches native WidgetConstants.TYPE_*
  final String title;
  final String subtitle;
  final IconData icon;
  final bool portrait;
  const _WidgetPreviewSpec(
      {required this.type,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.portrait});
}

const _kWidgetSpecs = [
  _WidgetPreviewSpec(
    type: 'static',
    title: 'Fresh Wallpapers',
    subtitle: 'Explore new wallpapers →',
    icon: Icons.image_rounded,
    portrait: true,
  ),
  _WidgetPreviewSpec(
    type: 'video',
    title: 'Video Wallpapers',
    subtitle: 'Bring your screen to life →',
    icon: Icons.play_circle_fill_rounded,
    portrait: true,
  ),
  _WidgetPreviewSpec(
    type: 'desktop',
    title: 'Desktop Wallpapers',
    subtitle: '4K wallpapers for your setup →',
    icon: Icons.desktop_windows_rounded,
    portrait: false,
  ),
];

class HomeWidgetsSheet extends StatefulWidget {
  const HomeWidgetsSheet({super.key});

  @override
  State<HomeWidgetsSheet> createState() => _HomeWidgetsSheetState();
}

class _HomeWidgetsSheetState extends State<HomeWidgetsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isRequesting = false;

  // type -> cached items currently shown by that widget on the home screen
  // (same thumbnail files the native RemoteViews reads — readable directly
  // from Flutter since they live in this app's own private storage).
  final Map<String, List<Map<String, dynamic>>> _itemsByType = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kWidgetSpecs.length, vsync: this);
    _loadAllPreviews();
  }

  Future<void> _loadAllPreviews() async {
    for (final spec in _kWidgetSpecs) {
      final items =
          await HomeWidgetLaunchService.getCachedWidgetItems(spec.type);
      if (!mounted) return;
      setState(() => _itemsByType[spec.type] = items);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isPro => UserProfile.plusMember;

  void _openPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingScreen4(
          onComplete: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _addToHomeScreen(_WidgetPreviewSpec spec) async {
    if (!_isPro) {
      _openPaywall(context);
      return;
    }
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    final ok = await HomeWidgetLaunchService.requestPinWidget(spec.type);
    if (!mounted) return;
    setState(() => _isRequesting = false);
    // requestPinAppWidget hands the foreground briefly to the launcher's own
    // "place widget?" confirmation UI. Android (and some OEM skins
    // especially aggressively) silently drops a native Toast fired while
    // this app isn't the foreground activity — confirmed via
    // "Blocking custom toast ... package not in the foreground" in logcat
    // right after this call. A short delay lets our activity regain
    // foreground before the toast is requested, which reliably avoids that.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    ToastWidget.showToast(ok
        ? 'Check your home screen to place the widget'
        : 'Long-press your home screen, then find WallRio in Widgets');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return glassSheetBackground(
      Container(
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
                child: Row(
                  children: [
                    Text(
                      'Widgets',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded,
                          color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colors.accentContainer,
                      border: Border.all(color: colors.accent, width: 1.2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: colors.accent,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Static'),
                      Tab(text: 'Video'),
                      Tab(text: 'Desktop'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 230,
                child: TabBarView(
                  controller: _tabController,
                  children: _kWidgetSpecs
                      .map((spec) => _widgetPreviewMock(context, spec))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isRequesting
                        ? null
                        : () => _addToHomeScreen(
                            _kWidgetSpecs[_tabController.index]),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.buttonPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isPro) ...[
                                const Icon(Icons.lock_rounded,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                              ],
                              const Text(
                                'Add to Home Screen',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      tint: colors.card,
    );
  }

  // Mirrors the real native widget's layout (icon + title/subtitle on the
  // left, thumbnails on the right) and shows the SAME thumbnail files the
  // home-screen widget is currently displaying, read directly from this
  // app's private storage. Falls back to a plain icon tile only for a slot
  // that genuinely has no cached item yet (e.g. before the first refresh).
  Widget _widgetPreviewMock(BuildContext context, _WidgetPreviewSpec spec) {
    final colors = context.appColors;
    final items = _itemsByType[spec.type];
    final slotCount = spec.portrait ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: colors.accentContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(spec.icon, color: colors.accent, size: 18),
                  ),
                  Text(
                    spec.title,
                    maxLines: 2,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.subtitle,
                    maxLines: 2,
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 62,
              child: Row(
                children: List.generate(slotCount, (i) {
                  final item =
                      items != null && i < items.length ? items[i] : null;
                  final thumbPath = item?['thumbPath'] as String?;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: i == slotCount - 1 ? 0 : 6),
                      child: AspectRatio(
                        aspectRatio: spec.portrait ? 0.55 : 1.4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.card,
                              border: Border.all(color: colors.divider),
                            ),
                            child: (thumbPath != null &&
                                    thumbPath.isNotEmpty &&
                                    File(thumbPath).existsSync())
                                ? Image.file(
                                    File(thumbPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        spec.icon,
                                        color: colors.textTertiary,
                                        size: 18),
                                  )
                                : Icon(spec.icon,
                                    color: colors.textTertiary, size: 18),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
