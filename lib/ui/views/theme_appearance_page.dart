import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

/// Opens the "Theme & Appearance" personalization sheet, reached from the
/// existing Appearance section in settings_page.dart. Presented the same way
/// every other WallRio bottom sheet is (`CNBottomSheet.show`, rounded top,
/// transparent barrier) rather than as a full pushed page.
void showThemeAppearanceSheet(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  CNBottomSheet.show(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: Platform.isIOS,
    // Cap the sheet well short of full-screen so it reads as a partial
    // sheet (the page behind stays visible/dimmed), matching the reference
    // UX, instead of the Flexible+SingleChildScrollView content inside
    // greedily expanding to the full screen height.
    constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => const ThemeAppearanceSheet(),
  );
}

/// Sheet content for "Theme & Appearance". Everything here reads/writes
/// through [AppThemeManager]; the Pro paywall is the same full plans page
/// (`OnboardingScreen4` — monthly/quarterly/yearly/lifetime) used elsewhere
/// in the app (main Settings "Unlock Pro" banner, Personalization Hub
/// icon/frame locks) — no new purchase flow is introduced.
class ThemeAppearanceSheet extends StatelessWidget {
  const ThemeAppearanceSheet({super.key});

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

  @override
  Widget build(BuildContext context) {
    final sheetColor = context.appColors.card;

    Widget sheetContent = glassSheetBackground(
      Container(
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!Platform.isIOS) _manualDragHandle(context),
              _header(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<AppThemeManager>(
                    builder: (context, manager, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(context, 'THEME MODE'),
                          const SizedBox(height: 10),
                          ThemeModeRow(manager: manager),
                          const SizedBox(height: 22),
                          _sectionLabel(context, 'ACCENT COLOR'),
                          const SizedBox(height: 10),
                          _accentGrid(context, manager),
                          const SizedBox(height: 22),
                          _sectionLabel(context, 'BACKGROUND STYLE'),
                          const SizedBox(height: 10),
                          BackgroundStyleRow(manager: manager),
                          const SizedBox(height: 22),
                          _sectionLabel(context, 'PREMIUM THEMES'),
                          const SizedBox(height: 10),
                          _premiumThemesRow(context, manager),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      tint: sheetColor,
    );

    return sheetContent;
  }

  // ─── Drag handle (Android only — iOS gets a native one) ────────

  Widget _manualDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.appColors.divider,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ─── Header: title + BETA badge + close button ─────────────────

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      child: Row(
        children: [
          Text(
            'Themes',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.appColors.accentContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PRO/BETA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.appColors.accent,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded,
                color: context.appColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.appColors.textTertiary,
      ),
    );
  }

  // ─── Accent Color grid (3 per row, icon chip + label) ───────────

  Widget _accentGrid(BuildContext context, AppThemeManager manager) {
    final colors = context.appColors;
    final options = AccentColorOption.values;

    Widget tile(AccentColorOption option) {
      final selected = manager.premiumTheme == null && manager.accent == option;
      final locked = option.isPro && !_isPro;
      return GestureDetector(
        onTap: () {
          if (locked) {
            _openPaywall(context);
            return;
          }
          manager.setAccent(option);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? option.palette.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: option.palette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  if (locked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock_rounded,
                            color: colors.textTertiary, size: 9),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: options.map(tile).toList(),
    );
  }

  // ─── Premium themes row ────────────────────────────────────────

  Widget _premiumThemesRow(BuildContext context, AppThemeManager manager) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: premiumThemeConfigurations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final theme = premiumThemeConfigurations[index];
          final selected = manager.premiumTheme?.id == theme.id;
          final locked = theme.isPro && !_isPro;
          return GestureDetector(
            onTap: () {
              if (locked) {
                _openPaywall(context);
                return;
              }
              manager.setPremiumTheme(theme);
            },
            child: Container(
              width: 88,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.backgroundColorSet.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? theme.accentPalette.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.accentPalette.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      if (locked)
                        const Icon(Icons.lock_rounded,
                            color: Colors.white54, size: 14)
                      else if (selected)
                        Icon(Icons.check_circle_rounded,
                            color: theme.accentPalette.primary, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    theme.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PRO',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
