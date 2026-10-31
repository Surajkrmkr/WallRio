import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/dark_theme.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';

/// Drives the "Theme & Appearance" personalization system: theme mode
/// (system/light/dark), accent color, background style, premium theme
/// presets, and dynamic-accent-from-wallpaper.
///
/// Reconciliation with `DarkThemeProvider`: `DarkThemeProvider.darkTheme`
/// (a plain bool, persisted under the legacy "isDarkMode" key) remains the
/// single existing on/off dark-mode switch used by `_darkModeTile()` in
/// settings_page.dart and by any other code that already reads it. Rather
/// than duplicating that state, `AppThemeMode.light`/`AppThemeMode.dark`
/// are kept in sync with it one-directionally: whenever `setMode()` is
/// called with light/dark, we also flip `DarkThemeProvider.darkTheme` so
/// existing call sites keep working, and MaterialApp's `themeMode` in
/// main.dart is computed from *this* manager (which also adds the
/// previously-unsupported `ThemeMode.system`). See the comment on
/// `syncWithDarkThemeProvider` and in main.dart for details.
class AppThemeManager extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark;
  AccentColorOption _accent = AccentColorOption.emerald;
  BackgroundStyleOption _backgroundStyle = BackgroundStyleOption.standard;
  PremiumThemeConfiguration? _premiumTheme;
  bool _dynamicAccentEnabled = false;

  Color? _dynamicAccentColor;
  String? _lastPaletteExtractedUrl;

  AppThemeMode get mode => _mode;
  AccentColorOption get accent => _accent;
  BackgroundStyleOption get backgroundStyle => _backgroundStyle;
  PremiumThemeConfiguration? get premiumTheme => _premiumTheme;
  bool get dynamicAccentEnabled => _dynamicAccentEnabled;
  Color? get dynamicAccentColor => _dynamicAccentColor;

  AppThemeManager() {
    _loadData();
  }

  Future<void> _loadData() async {
    await AppThemeService().getData();
    _mode = AppThemeService.themeMode;
    _accent = AppThemeService.accentColor;
    _backgroundStyle = AppThemeService.backgroundStyle;
    _dynamicAccentEnabled = AppThemeService.dynamicAccentEnabled;
    final id = AppThemeService.premiumThemeId;
    _premiumTheme = id == null
        ? null
        : premiumThemeConfigurations
            .cast<PremiumThemeConfiguration?>()
            .firstWhere((t) => t?.id == id, orElse: () => null);
    notifyListeners();
    if (_dynamicAccentEnabled) {
      _maybeRefreshDynamicAccent(AppThemeService.lastAppliedWallpaperUrl);
    }
  }

  /// Sets the theme mode. If [syncDarkThemeProvider] is passed (it should be,
  /// from any call site that has one in scope), the legacy
  /// `DarkThemeProvider.darkTheme` bool is mirrored for light/dark so older
  /// code reading it directly keeps working. System mode has no legacy
  /// equivalent and is left as-is on `DarkThemeProvider`.
  void setMode(AppThemeMode mode, {DarkThemeProvider? syncDarkThemeProvider}) {
    _mode = mode;
    AppThemeService().saveThemeMode(mode);
    if (syncDarkThemeProvider != null) {
      if (mode == AppThemeMode.dark) {
        syncDarkThemeProvider.darkTheme = true;
      } else if (mode == AppThemeMode.light) {
        syncDarkThemeProvider.darkTheme = false;
      }
    }
    notifyListeners();
  }

  void setAccent(AccentColorOption accent) {
    _accent = accent;
    // Selecting an explicit accent overrides any active premium theme so
    // the swatches reflect what's actually applied.
    _premiumTheme = null;
    AppThemeService().saveAccentColor(accent);
    AppThemeService().savePremiumThemeId(null);
    notifyListeners();
  }

  void setBackgroundStyle(BackgroundStyleOption style) {
    _backgroundStyle = style;
    _premiumTheme = null;
    AppThemeService().saveBackgroundStyle(style);
    AppThemeService().savePremiumThemeId(null);
    notifyListeners();
  }

  void setPremiumTheme(PremiumThemeConfiguration theme) {
    _premiumTheme = theme;
    _accent = theme.accent;
    _backgroundStyle = theme.backgroundStyle;
    AppThemeService().savePremiumThemeId(theme.id);
    AppThemeService().saveAccentColor(theme.accent);
    AppThemeService().saveBackgroundStyle(theme.backgroundStyle);
    notifyListeners();
  }

  void setDynamicAccentEnabled(bool enabled) {
    _dynamicAccentEnabled = enabled;
    AppThemeService().saveDynamicAccentEnabled(enabled);
    if (enabled) {
      _maybeRefreshDynamicAccent(AppThemeService.lastAppliedWallpaperUrl);
    } else {
      _dynamicAccentColor = null;
    }
    notifyListeners();
  }

  /// Hook called (fire-and-forget) after a wallpaper is successfully applied
  /// at the existing call sites in navigation_page.dart / auto_wallpaper.dart.
  /// Persists the URL and, if Dynamic Accent is on, kicks off re-extraction.
  static Future<void> recordAppliedWallpaperUrl(String url) async {
    if (url.isEmpty) return;
    await AppThemeService().saveLastAppliedWallpaperUrl(url);
  }

  /// Called by consumers (e.g. after recordAppliedWallpaperUrl) to trigger a
  /// re-extraction if the manager instance is reachable. Safe to call
  /// unconditionally.
  void refreshDynamicAccentFor(String url) {
    if (!_dynamicAccentEnabled) return;
    _maybeRefreshDynamicAccent(url);
  }

  void _maybeRefreshDynamicAccent(String? url) {
    if (url == null || url.isEmpty) return;
    if (url == _lastPaletteExtractedUrl) return;
    _lastPaletteExtractedUrl = url;
    _extractDynamicAccent(url);
  }

  Future<void> _extractDynamicAccent(String url) async {
    Color resolved;
    try {
      // Small decode keeps quantization off the ANR path (see WallDetails).
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(
          CachedNetworkImageProvider(url,
              cacheManager: WallCacheManager.instance),
          width: 120,
        ),
        maximumColorCount: 10,
      );
      resolved = generator.dominantColor?.color ??
          (generator.colors.isNotEmpty ? generator.colors.first : null) ??
          _accent.palette.primary;
    } catch (error) {
      logger.w('Dynamic accent extraction failed for $url: $error');
      resolved = _accent.palette.primary;
    }
    if (resolved != _dynamicAccentColor) {
      _dynamicAccentColor = resolved;
      notifyListeners();
    }
  }

  // ─── Theme building ──────────────────────────────────────────────

  Color get _effectivePrimary => _dynamicAccentEnabled && _dynamicAccentColor != null
      ? _dynamicAccentColor!
      : _accent.palette.primary;

  AccentPalette get _effectivePalette => AccentPalette(
        primary: _effectivePrimary,
        primaryContainer: _accent.palette.primaryContainer,
        secondary: _accent.palette.secondary,
        secondaryContainer: _accent.palette.secondaryContainer,
        surfaceTint: _effectivePrimary,
        buttonColor: _effectivePrimary,
        selectedColor: _effectivePrimary,
        focusColor: _accent.palette.focusColor,
      );

  BackgroundColorSet get _effectiveBackgroundSet => _backgroundStyle.colorSet;

  /// Builds a `ThemeData` for the given brightness that layers the
  /// [AppSemanticColors] extension on top of the existing WallRioThemeData
  /// output, so nothing that already reads ColorScheme/TextTheme regresses.
  ///
  /// When mode==dark, accent==emerald, backgroundStyle==standard, no premium
  /// theme, and dynamic accent is off, this is equivalent (by construction)
  /// to today's `WallRioThemeData.getLightThemeData(isDarkTheme: true)`
  /// output plus the added extension — the regression guardrail described
  /// in the spec.
  ThemeData buildThemeData({required BuildContext context, required bool isDarkTheme}) {
    final base = WallRioThemeData.getLightThemeData(
        context: context,
        isDarkTheme: isDarkTheme,
        accentColor: _effectivePrimary);

    if (!isDarkTheme) {
      // Light mode: keep WallRioThemeData's improved light palette, but
      // still re-seed the ColorScheme off the selected accent (mirroring
      // the dark-mode branch below). Without this, Material widgets that
      // derive their color from `Theme.of(context).colorScheme` instead of
      // the semantic extension (e.g. `Switch`'s default track color) stay
      // pinned to the base Emerald seed even after the user picks a
      // different accent — visible as a track/thumb color mismatch.
      final palette = _effectivePalette;
      return base.copyWith(
        colorScheme:
            ColorScheme.fromSeed(seedColor: palette.primary, brightness: Brightness.light),
        extensions: [
        AppSemanticColors(
          background: whiteColor,
          surface: const Color(0xFFF7F7FA),
          surfaceElevated: const Color(0xFFFFFFFF),
          card: const Color(0xFFF2F2F7),
          primary: palette.primary,
          secondary: palette.secondary,
          accent: palette.primary,
          accentContainer: palette.primary.withValues(alpha: 0.12),
          textPrimary: const Color(0xFF1C1C1E),
          textSecondary: const Color(0xFF6E6E73),
          textTertiary: const Color(0xFF9A9AA0),
          divider: Colors.black.withValues(alpha: 0.08),
          icon: const Color(0xFF1C1C1E),
          buttonPrimary: palette.buttonColor,
          buttonSecondary: Colors.black.withValues(alpha: 0.06),
          danger: const Color(0xFFD64545),
          success: const Color(0xFF3EA063),
          warning: const Color(0xFFC98A2E),
        ),
      ]);
    }

    final bgSet = _effectiveBackgroundSet;
    final palette = _effectivePalette;

    return base.copyWith(
      scaffoldBackgroundColor: bgSet.background,
      colorScheme:
          ColorScheme.fromSeed(seedColor: palette.primary, brightness: Brightness.dark),
      // `copyWith` on ThemeData does not reach into already-built sub-themes,
      // so the app bar/dialog/bottom sheet/nav bar would otherwise stay
      // pinned to WallRioThemeData's base black regardless of the selected
      // background style. Re-derive them from the same BackgroundColorSet
      // that already drives scaffoldBackgroundColor/AppSemanticColors.
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: bgSet.background,
        surfaceTintColor: bgSet.background,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: bgSet.bottomSheet,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: bgSet.dialog,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: bgSet.navBar,
      ),
      extensions: [
        AppSemanticColors(
          background: bgSet.background,
          surface: bgSet.surface,
          surfaceElevated: bgSet.elevatedCard,
          card: bgSet.card,
          primary: palette.primary,
          secondary: palette.secondary,
          accent: palette.primary,
          accentContainer: palette.primary.withValues(alpha: 0.15),
          textPrimary: whiteColor,
          textSecondary: whiteColor.withValues(alpha: 0.7),
          textTertiary: whiteColor.withValues(alpha: 0.4),
          divider: whiteColor.withValues(alpha: 0.08),
          icon: whiteColor,
          buttonPrimary: palette.buttonColor,
          buttonSecondary: whiteColor.withValues(alpha: 0.1),
          danger: const Color(0xFFE05252),
          success: const Color(0xFF4CAF50),
          warning: const Color(0xFFF2A93B),
        ),
      ],
    );
  }
}
