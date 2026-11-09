import 'dart:async';
import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show ProductDetails;
import 'package:wallrio/model/user_profile_model.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/app_theme_tokens.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/ui/widgets/glass_sheet_background.dart';

/// Shows the one-time, limited-time offer when a free user closes the paywall.
///
/// Returns true if the user tapped the offer (the purchase flow has started),
/// so the caller should leave the paywall open. Returns false when nothing was
/// shown or the user declined, and the caller should close the paywall as
/// usual. The 2 hour window opens the first time this shows and never resets.
Future<bool> maybeShowDropoffOffer(BuildContext context) async {
  final sub = Provider.of<SubscriptionProvider>(context, listen: false);
  if (!sub.shouldShowDropoff) return false;
  await sub.startDropoff();
  final choice = sub.dropoffChoice;
  if (choice == null || !context.mounted) return false;

  final claimed = await CNBottomSheet.show<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: Platform.isIOS,
    builder: (_) => _DropoffSheet(choice: choice),
  );
  return claimed == true;
}

/// Compact "offer ends in hh:mm:ss" line, for the paywall while the window
/// is open. Renders nothing otherwise.
class DropoffCountdownBanner extends StatefulWidget {
  const DropoffCountdownBanner({super.key});

  @override
  State<DropoffCountdownBanner> createState() => _DropoffCountdownBannerState();
}

class _DropoffCountdownBannerState extends State<DropoffCountdownBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    if (!sub.dropoffActive || sub.dropoffChoice == null) {
      return const SizedBox.shrink();
    }
    final left = DropoffOffer.remaining();
    if (left == Duration.zero) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFF6B35)),
          const SizedBox(width: 6),
          Text(
            'Special offer ends in ${DropoffOffer.format(left)}',
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width strip for the home screen while the limited-time offer is
/// open. Tapping it opens the paywall (via [onTap]). Renders nothing for Pro
/// members or once the window has closed.
class DropoffHomeBanner extends StatefulWidget {
  final VoidCallback onTap;
  const DropoffHomeBanner({super.key, required this.onTap});

  @override
  State<DropoffHomeBanner> createState() => _DropoffHomeBannerState();
}

class _DropoffHomeBannerState extends State<DropoffHomeBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    final choice = sub.dropoffChoice;
    final left = DropoffOffer.remaining();
    if (!sub.dropoffActive ||
        choice == null ||
        left == Duration.zero ||
        UserProfile.plusMember) {
      return const SizedBox.shrink();
    }
    const accent = Color(0xFFFF6B35);
    final percent = choice.percentOff;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF9A3C)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      percent == null
                          ? 'Limited-time Pro offer'
                          : '$percent% off WallRio Pro',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Ends in ${DropoffOffer.format(left)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropoffSheet extends StatefulWidget {
  final PlanChoice choice;
  const _DropoffSheet({required this.choice});

  @override
  State<_DropoffSheet> createState() => _DropoffSheetState();
}

class _DropoffSheetState extends State<_DropoffSheet> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DropoffOffer.remaining() == Duration.zero) {
        Navigator.of(context).pop(false);
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _claim() {
    HapticFeedback.mediumImpact();
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    final choice = widget.choice;
    // The purchase token must come from the offer, so find that exact product.
    ProductDetails? product;
    for (final p in sub.products) {
      if (sub.choiceFor(p)?.purchase.offerId == choice.purchase.offerId &&
          sub.choiceFor(p)?.basePlanId == choice.basePlanId) {
        product = p;
        break;
      }
    }
    Navigator.of(context).pop(true);
    if (product != null) sub.buyProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? bgDark2Color : Colors.white;
    final choice = widget.choice;
    final intro = choice.intro!;
    final percent = choice.percentOff;
    final left = DropoffOffer.remaining();
    const accent = Color(0xFFFF6B35);

    return glassSheetBackground(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Ends in ${DropoffOffer.format(left)}',
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Wait, one-time offer',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                percent == null
                    ? 'A special price on WallRio Pro, just for you.'
                    : '$percent% off your first ${choice.introPeriodText == null ? 'year' : choice.introPeriodText!.replaceFirst('first ', '')} of WallRio Pro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14.5),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    choice.recurring.formattedPrice,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 18,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    intro.formattedPrice,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _claim,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Claim ${percent ?? ''}${percent == null ? '' : '% off'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'No thanks',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              Text(
                'Then ${choice.recurring.formattedPrice} per year until canceled. '
                'Cancel anytime in Google Play.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
      tint: sheetColor,
    );
  }
}
