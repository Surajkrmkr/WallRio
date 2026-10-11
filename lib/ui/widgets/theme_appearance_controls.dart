import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';

/// Shared Theme & Appearance controls, extracted out of
/// [ThemeAppearanceSheet]'s private helper methods so both the
/// "Theme & Appearance" bottom sheet (theme_appearance_page.dart) and the
/// Personalization Hub's "Appearance" section render the EXACT same
/// widgets — no copy-pasted row-building logic between the two surfaces.
///
/// All three read/write through [AppThemeManager]; the Pro paywall is the
/// same full plans page (`OnboardingScreen4` — monthly/quarterly/yearly/
/// lifetime) used everywhere else in the app, not the older `PlusSubscription`
/// dialog.

bool _isPro() => UserProfile.plusMember;

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

class _ThemeModeOption {
  final AppThemeMode mode;
  final IconData icon;
  final String label;
  const _ThemeModeOption(this.mode, this.icon, this.label);
}

/// "System / Light / Dark" segmented row. Always free — never PRO-gated.
class ThemeModeRow extends StatelessWidget {
  final AppThemeManager manager;
  const ThemeModeRow({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final options = <_ThemeModeOption>[
      _ThemeModeOption(
          AppThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      _ThemeModeOption(AppThemeMode.light, Icons.light_mode_rounded, 'Light'),
      _ThemeModeOption(AppThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];

    void onSelect(AppThemeMode mode) {
      final darkThemeProvider =
          Provider.of<DarkThemeProvider>(context, listen: false);
      manager.setMode(mode, syncDarkThemeProvider: darkThemeProvider);
    }

    final colors = context.appColors;
    return Row(
      children: options.map((option) {
        final mode = option.mode;
        final icon = option.icon;
        final label = option.label;
        final selected = manager.mode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option == options.last ? 0 : 10),
            child: GestureDetector(
              onTap: () => onSelect(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? colors.accentContainer : colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? colors.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 22,
                        color: selected ? colors.accent : colors.textSecondary),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected ? colors.accent : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// "Standard / OLED Black / Deep Navy / Soft Gradient" radio-chip row.
/// Non-standard styles are PRO-gated per [BackgroundStyleOption.isPro].
class BackgroundStyleRow extends StatelessWidget {
  final AppThemeManager manager;
  const BackgroundStyleRow({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locked = !_isPro();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: BackgroundStyleOption.values.map((option) {
        final selected =
            manager.premiumTheme == null && manager.backgroundStyle == option;
        final optionLocked = option.isPro && locked;
        return GestureDetector(
          onTap: () {
            if (optionLocked) {
              _openPaywall(context);
              return;
            }
            manager.setBackgroundStyle(option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : (optionLocked
                          ? Icons.lock_rounded
                          : Icons.radio_button_off_rounded),
                  size: 18,
                  color: selected ? colors.accent : colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// "Adapt accent to your wallpaper" toggle tile. PRO-gated.
class DynamicAccentTile extends StatelessWidget {
  final AppThemeManager manager;
  const DynamicAccentTile({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final locked = !_isPro();
    Widget toggle = Platform.isIOS
        ? CNSwitch(
            value: manager.dynamicAccentEnabled,
            onChanged: locked
                ? (_) => _openPaywall(context)
                : (val) => manager.setDynamicAccentEnabled(val),
            color: context.appColors.accent,
          )
        : Switch(
            value: manager.dynamicAccentEnabled,
            onChanged: locked
                ? (_) => _openPaywall(context)
                : (val) => manager.setDynamicAccentEnabled(val),
            activeThumbColor: context.appColors.accent,
            // Explicit track color so it always matches the selected accent
            // even if the surrounding ColorScheme hasn't re-seeded yet.
            activeTrackColor: context.appColors.accent.withValues(alpha: 0.5),
          );

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text('Adapt accent to your wallpaper'),
        subtitle: const Text('Match WallRio to your current wallpaper.'),
        trailing: locked
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  toggle,
                ],
              )
            : toggle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
