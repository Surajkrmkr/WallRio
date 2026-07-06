import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/personalization_provider.dart';

class PremiumBadgeWidget extends StatelessWidget {
  const PremiumBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalizationProvider>(
      builder: (context, personalization, _) {
        final badgeKey = personalization.personalization?.activeBadge ?? 'none';
        
        if (badgeKey == 'none') return const SizedBox.shrink();

        IconData iconData;
        Color color;
        String label;

        switch (badgeKey) {
          case 'badge_pro':
            iconData = Icons.workspace_premium_rounded;
            color = const Color(0xFF37C3A3);
            label = "PRO";
            break;
          case 'badge_premium':
            iconData = Icons.verified_rounded;
            color = Colors.blueAccent;
            label = "PREMIUM";
            break;
          case 'badge_elite':
            iconData = Icons.star_rounded;
            color = Colors.amber;
            label = "ELITE";
            break;
          case 'badge_diamond':
            iconData = Icons.diamond_rounded;
            color = Colors.cyanAccent;
            label = "DIAMOND";
            break;
          case 'badge_founder':
            iconData = Icons.auto_awesome_rounded;
            color = Colors.deepPurpleAccent;
            label = "FOUNDER";
            break;
          default:
            return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
