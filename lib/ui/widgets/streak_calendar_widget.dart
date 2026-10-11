import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';
import 'package:wallrio/ui/widgets/diamond_text.dart';

/// Shared streak card used in the profile sheet, Settings and Rewards Hub.
class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({super.key, this.openHubOnTap = true});

  /// False inside the Rewards Hub itself.
  final bool openHubOnTap;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressionProvider, SubscriptionProvider>(
      builder: (context, provider, sub, _) {
        if (sub.subscriptionDaysLeft.isNotEmpty) return const SizedBox.shrink();
        final progression = provider.progression;
        if (progression == null) return const SizedBox.shrink();

        final colors = context.appColors;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final checkedIn = provider.isCheckedInToday();
        final taskDone = provider.dailyTaskDone;
        final streak = progression.currentStreak;
        final reward = provider.todayCheckInReward;
        // Days already completed in the current 7-day cycle.
        final doneInCycle =
            streak == 0 ? 0 : (checkedIn ? ((streak - 1) % 7) + 1 : streak % 7);

        final String subtitle = checkedIn
            ? 'Done for today · come back tomorrow'
            : taskDone
                ? 'Check in now to earn +$reward 💎'
                : 'Set or save 1 wallpaper to unlock check-in';

        final card = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: isDark ? 0.22 : 0.14),
                colors.secondary.withValues(alpha: isDark ? 0.10 : 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak-day streak',
                          style: TextStyle(
                            fontFamily: appFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        DiamondText(
                          subtitle,
                          style: TextStyle(
                            fontFamily: appFontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Streak freeze: saves your streak if you miss '
                        'one day. Refills every 7 days.',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.ac_unit_rounded,
                              size: 13, color: Color(0xFF4FC3F7)),
                          const SizedBox(width: 3),
                          Text(
                            '${provider.streakFreezes}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _DayPill(
                        day: i + 1,
                        done: i < doneInCycle,
                        today: !checkedIn && i == doneInCycle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: checkedIn || !taskDone
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          provider.manualCheckIn();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        colors.accent.withValues(alpha: 0.15),
                    disabledForegroundColor: colors.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: DiamondText(
                    checkedIn
                        ? '✓ Checked in'
                        : taskDone
                            ? 'Check in · +$reward 💎'
                            : 'Save or set a wallpaper first',
                    style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );

        if (!openHubOnTap) return card;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardsHubPage()),
          ),
          child: card,
        );
      },
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day, required this.done, required this.today});

  final int day;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: done
                ? colors.accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: today ? Border.all(color: colors.accent, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(
                  '+$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: today ? colors.accent : colors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'Day $day',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
