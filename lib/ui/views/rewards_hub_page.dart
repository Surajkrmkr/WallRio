import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/progression_provider.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/services/app_theme_tokens.dart';
import 'package:wallrio/services/responsive.dart';
import 'package:wallrio/ui/widgets/export.dart';
import 'package:wallrio/provider/ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

bool _isRating = false;

class RewardsHubPage extends StatelessWidget {
  const RewardsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ProgressionProvider>(
          builder: (context, progressionProvider, _) {
            final progression = progressionProvider.progression;
            if (progressionProvider.isLoading || progression == null) {
              return Center(
                  child: CircularProgressIndicator(
                      color: context.appColors.accent));
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverAppBarWidget(
                  showLogo: false,
                  showSearchBtn: false,
                  centeredTitle: true,
                  showBackBtn: true,
                  text: 'Rewards Hub',
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth:
                              ResponsiveHelper.getMaxContentWidth(context)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDiamondBalanceCard(context,
                                progression.diamondsBalance, isDarkMode),
                            const SizedBox(height: 12),
                            _buildDataWarning(isDarkMode),
                            const SizedBox(height: 24),
                            _sectionTitle(context, 'What Diamonds Unlock'),
                            _buildUnlockExamplesRow(context, isDarkMode),
                            const SizedBox(height: 32),
                            _sectionTitle(context, 'Earn Diamonds'),
                            _buildQuestsList(
                                context, progressionProvider, isDarkMode),
                            if (progression.dailyShares >= 2) ...[
                              const SizedBox(height: 16),
                              _buildShareLimitWarning(context, isDarkMode),
                            ],
                            const SizedBox(height: 32),
                            _buildStreakSection(
                                context, progressionProvider, isDarkMode),
                            const SizedBox(height: 32),
                            _sectionTitle(context, 'Your Journey'),
                            _buildMilestoneJourney(
                                context, progression, isDarkMode),
                            const SizedBox(height: 32),
                            _sectionTitle(context, 'Transaction History'),
                            _buildTransactionHistory(
                                context, progression, isDarkMode),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMilestoneJourney(
      BuildContext context, dynamic progression, bool isDarkMode) {
    final List<Map<String, dynamic>> milestones = [
      {
        'key': 'start',
        'label': 'Beginner',
        'desc': 'Started the journey',
        'req': 0,
        'icon': Icons.rocket_launch_rounded
      },
      {
        'key': 'streak_7',
        'label': 'Dedicated',
        'desc': '7 Day Streak',
        'req': 7,
        'type': 'streak',
        'icon': Icons.local_fire_department_rounded
      },
      {
        'key': 'streak_30',
        'label': 'Veteran',
        'desc': '30 Day Streak',
        'req': 30,
        'type': 'streak',
        'icon': Icons.workspace_premium_rounded
      },
      {
        'key': 'earner_500',
        'label': 'Diamond Hunter',
        'desc': 'Earned 500 💎',
        'req': 500,
        'type': 'earned',
        'icon': Icons.diamond_rounded
      },
      {
        'key': 'streak_90',
        'label': 'Legendary',
        'desc': '90 Day Streak',
        'req': 90,
        'type': 'streak',
        'icon': Icons.stars_rounded
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(milestones.length, (index) {
          final m = milestones[index];
          bool isCompleted = false;

          if (m['key'] == 'start') {
            isCompleted = true;
          } else if (m['type'] == 'streak') {
            isCompleted = progression.currentStreak >= m['req'];
          } else if (m['type'] == 'earned') {
            isCompleted = progression.lifetimeDiamondsEarned >= m['req'];
          }

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? context.appColors.accent
                            : (isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                    color: context.appColors.accent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                      child: Icon(m['icon'],
                          color: isCompleted ? Colors.white : Colors.grey,
                          size: 20),
                    ),
                    if (index < milestones.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? context.appColors.accent.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['label'],
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isCompleted
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        DiamondText(
                          m['desc'],
                          style: TextStyle(
                              fontSize: 11,
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.grey.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCompleted)
                  Icon(Icons.check_circle_rounded,
                      color: context.appColors.accent, size: 20)
                else
                  Text('LOCKED',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.withValues(alpha: 0.5),
                          letterSpacing: 1)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDataWarning(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Clearing app data or uninstalling will remove your locally saved diamonds.',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareLimitWarning(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: context.appColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You've reached today's sharing reward limit. Come back tomorrow to earn more Diamonds.",
              style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.accent,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondBalanceCard(
      BuildContext context, int balance, bool isDarkMode) {
    final accent = context.appColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'DIAMOND BALANCE',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: accent),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const DiamondIcon(size: 44),
              const SizedBox(width: 12),
              Text(
                balance.toString(),
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w900, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Use diamonds to unlock premium wallpapers & dynamic live content.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockExamplesRow(BuildContext context, bool isDarkMode) {
    Widget exampleItem(IconData icon, String title, String costStr) {
      return Expanded(
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.appColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: context.appColors.accent),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DiamondText(
                  costStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: context.appColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        exampleItem(Icons.wallpaper_rounded, 'Static Wallpaper', '20 💎'),
        const SizedBox(width: 8),
        exampleItem(Icons.motion_photos_on_rounded, 'Live Wallpaper', '30 💎'),
        const SizedBox(width: 8),
        exampleItem(Icons.laptop_mac_rounded, 'Desktop Wallpaper', '20 💎'),
      ],
    );
  }

  Widget _buildStreakSection(
      BuildContext context, ProgressionProvider provider, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Daily Streak'),
        const StreakCalendarWidget(openHubOnTap: false),
      ],
    );
  }

  Widget _buildQuestsList(
      BuildContext context, ProgressionProvider provider, bool isDarkMode) {
    final progression = provider.progression!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1,
      children: [
        _questCard(
          context: context,
          icon: Icons.play_circle_fill_rounded,
          title: 'Watch Ad',
          subtitle: 'Earn 10 💎',
          progressText: '${progression.dailyAdViews}/10',
          isDarkMode: isDarkMode,
          onTap: () {
            Provider.of<AdsProvider>(context, listen: false)
                .loadRewardedAd(context, onRewarded: () {
              // Global tracking handles this, no action needed here.
            });
          },
        ),
        _questCard(
          context: context,
          icon: Icons.alternate_email_rounded,
          title: 'Follow us on X',
          subtitle: 'Earn ${ProgressionProvider.followXReward} 💎',
          progressText: provider.followedX ? 'Done' : 'Follow',
          isDarkMode: isDarkMode,
          isActionable: !provider.followedX,
          onTap: () async {
            if (_isRating || provider.followedX) return;
            _isRating = true;
            try {
              final launched = await launchUrl(
                  Uri.parse(ProgressionProvider.followXUrl),
                  mode: LaunchMode.externalApplication);
              if (launched) {
                provider.trackAction(ActionType.followX);
              } else {
                ToastWidget.showToast("Could not open X.");
              }
            } finally {
              _isRating = false;
            }
          },
        ),
        _questCard(
          context: context,
          icon: Icons.share_rounded,
          title: 'Invite',
          subtitle:
              progression.dailyShares >= 2 ? 'Limit Reached' : 'Earn 5 💎',
          progressText:
              '${progression.dailyShares >= 2 ? 2 : progression.dailyShares}/2',
          isDarkMode: isDarkMode,
          isActionable: progression.dailyShares < 2,
          onTap: () {
            if (progression.dailyShares >= 2) {
              ToastWidget.showToast(
                  "You've reached today's sharing reward limit. Come back tomorrow to earn more Diamonds.");
              return;
            }
            // ignore: deprecated_member_use
            Share.share(
                'Check out WallRio for amazing AMOLED wallpapers! https://play.google.com/store/apps/details?id=com.shadowteam.wallrio');
            provider.trackAction(ActionType.shareApp);
          },
        ),
        _questCard(
          context: context,
          icon: Icons.auto_awesome_rounded,
          title: 'Loyalty',
          subtitle: 'Longest streak',
          progressText:
              '${progression.longestStreak} day${progression.longestStreak == 1 ? '' : 's'}',
          isDarkMode: isDarkMode,
          onTap: () {},
          isActionable: false,
        ),
      ],
    );
  }

  Widget _questCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? progressText,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool isActionable = true,
  }) {
    return Material(
      color: isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isActionable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActionable
                          ? context.appColors.accent.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 22,
                        color: isActionable
                            ? context.appColors.accent
                            : Colors.grey),
                  ),
                  if (isActionable)
                    const Icon(Icons.arrow_outward_rounded,
                        size: 14, color: Colors.grey),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  DiamondText(subtitle,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              if (progressText != null && progressText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(progressText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isActionable
                                ? (isDarkMode ? Colors.white70 : Colors.black87)
                                : Colors.grey)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(
      BuildContext context, dynamic progression, bool isDarkMode) {
    final history = progression.transactionHistory;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('No transactions yet',
              style: Theme.of(context).textTheme.labelSmall),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final tx = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: tx.isCredit
                      ? context.appColors.accent.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: Icon(
                    tx.isCredit ? Icons.add_rounded : Icons.remove_rounded,
                    color: tx.isCredit
                        ? context.appColors.accent
                        : Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.reason,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(DateFormat('MMM dd, hh:mm a').format(tx.timestamp),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                DiamondText(
                  '${tx.isCredit ? '+' : '-'}${tx.amount} 💎',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: tx.isCredit
                        ? context.appColors.accent
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: context.appColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }
}
