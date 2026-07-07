import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/views/rewards_hub_page.dart';

class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressionProvider>(
      builder: (context, provider, _) {
        final hasSub = Provider.of<SubscriptionProvider>(context).subscriptionDaysLeft.isNotEmpty;
        if (hasSub) return const SizedBox.shrink();
        
        final progression = provider.progression;
        if (progression == null) return const SizedBox.shrink();

        final bool checkedIn = provider.isCheckedInToday();
        final int currentStreak = progression.currentStreak;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RewardsHubPage()),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF7B540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background 3D Diamond with enhanced depth
                  Positioned(
                    top: -25,
                    right: -25,
                    child: Opacity(
                      opacity: 0.4,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: SizedBox(
                          width: 158,
                          height: 158,
                          child: Stack(
                            children: [
                              // 3D Depth Layer (Side of the diamond)
                              Positioned(
                                top: 6,
                                right: 0,
                                child: Icon(
                                  Icons.diamond_rounded,
                                  size: 147,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              // Main Faceted Face
                              ShaderMask(
                                shaderCallback: (rect) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade300,
                                    Colors.orange.shade600,
                                    Colors.orange.shade800,
                                  ],
                                  stops: const [0.1, 0.5, 0.9],
                                ).createShader(rect),
                                child: const Icon(
                                  Icons.diamond_rounded,
                                  size: 147,
                                  color: Colors.white,
                                ),
                              ),
                              // Top Highlight/Reflection
                              Positioned(
                                top: 2,
                                left: 10,
                                child: Icon(
                                  Icons.diamond_rounded,
                                  size: 143,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _build3DIcon(checkedIn),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Weekly Streak',
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.w900, 
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$currentStreak Day${currentStreak == 1 ? '' : 's'} Active',
                                      style: const TextStyle(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w700, 
                                        color: Color(0xFFFFE4E1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!checkedIn)
                              _buildPulseButton(provider)
                            else
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final bool isPassed = (currentStreak % 7 > index) || (currentStreak > 0 && currentStreak % 7 == 0);
                            final bool isCurrent = (currentStreak % 7 == index);
                            
                            return _build3DDaySlot(index, isPassed, isCurrent && !checkedIn);
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DIcon(bool active) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          active ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildPulseButton(ProgressionProvider provider) {
    return GestureDetector(
      onTap: () => provider.manualCheckIn(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'CHECK-IN',
          style: TextStyle(
            color: Color(0xFFF7B540), 
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _build3DDaySlot(int index, bool isPassed, bool isCurrent) {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 38,
          height: 42,
          decoration: BoxDecoration(
            color: isPassed ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent 
                  ? Colors.white 
                  : (isPassed ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isPassed ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Center(
            child: isPassed 
                ? const Icon(Icons.check_rounded, color: Color(0xFFF7B540), size: 18)
                : Text(
                    days[index],
                    style: const TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white70,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isPassed ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
