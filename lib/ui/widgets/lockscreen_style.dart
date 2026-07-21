/// Purely decorative lockscreen-style preview overlays for collection
/// wallpaper previews. These render fake, non-interactive clock/status
/// elements so a wallpaper preview reads like a real lockscreen — none of
/// the values shown (time, battery, signal) are live device data.
enum LockscreenStyle {
  minimalCentered,
  edgeToEdge,
  vertical,
  split,
  glassmorphism,
  calendarFocused,
  editorialSerif,
  geometric,
  bottomAligned,
  asymmetrical,
}

class LockscreenStyleManager {
  const LockscreenStyleManager._();

  static const List<LockscreenStyle> _styles = LockscreenStyle.values;

  /// Deterministic per-wall assignment so the same wallpaper always renders
  /// the same style (stable across rebuilds/scroll recycling) while still
  /// looking randomly varied across a collection.
  static LockscreenStyle styleForWall(int wallId) {
    final index = wallId.hashCode.abs() % _styles.length;
    return _styles[index];
  }
}
