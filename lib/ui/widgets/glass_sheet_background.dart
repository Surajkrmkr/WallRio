import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';

/// Whether the real Liquid Glass rendering is available (iOS/macOS 26+).
/// Bottom sheet content widgets use this to decide whether to punch a
/// transparent hole in their own background for the glass blur to show
/// through — below iOS 26 the glass wrapper below is a no-op, so the
/// original opaque background must stay in place there.
bool get supportsGlassSheet => PlatformVersion.supportsLiquidGlass;

/// Wraps [child] in a Liquid Glass background shaped like a rounded-top
/// sheet. No-ops (returns [child] unchanged) below iOS 26.
///
/// Constructs [LiquidGlassContainer] directly (rather than the `.liquidGlass`
/// extension) so `autoHideOnModal` can be turned off: that flag exists to
/// hide a CN-widget sitting on a *host page* while a sheet covers it, but
/// here the glass container IS the sheet's own background, so there's
/// nothing to protect against — leaving it on risks the container hiding
/// itself and rendering fully transparent.
Widget glassSheetBackground(Widget child,
    {required Color tint, double cornerRadius = 32}) {
  if (!PlatformVersion.supportsLiquidGlass) return child;
  return LiquidGlassContainer(
    autoHideOnModal: false,
    config: LiquidGlassConfig(
      shape: CNGlassEffectShape.rect,
      cornerRadius: cornerRadius,
      tint: tint,
    ),
    child: child,
  );
}
