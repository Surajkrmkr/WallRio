import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/onboarding/screens/onboarding_screen4.dart';
import 'package:wallrio/ui/widgets/export.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class CollectionUnlockSheet extends StatefulWidget {
  final Collections collection;

  const CollectionUnlockSheet({super.key, required this.collection});

  @override
  State<CollectionUnlockSheet> createState() => _CollectionUnlockSheetState();
}

class _CollectionUnlockSheetState extends State<CollectionUnlockSheet> {
  StreamSubscription<bool>? _purchaseSub;
  StreamSubscription<List<PurchaseDetails>>? _inAppSub;
  bool _isProcessingPurchase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final progProvider = Provider.of<ProgressionProvider>(context, listen: false);
      _purchaseSub = subProvider.successPurchasedStream.listen((success) {
        if (success) {
          progProvider.unlockCollectionIAP(widget.collection.productId);
          if (mounted) Navigator.pop(context, true);
        }
      });
      _inAppSub = InAppPurchase.instance.purchaseStream.listen((purchaseDetailsList) {
        for (var purchaseDetails in purchaseDetailsList) {
          if (purchaseDetails.status == PurchaseStatus.error ||
              purchaseDetails.status == PurchaseStatus.canceled) {
            if (mounted && _isProcessingPurchase) {
              setState(() {
                _isProcessingPurchase = false;
              });
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _inAppSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final progProvider = Provider.of<ProgressionProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String fullProductId = widget.collection.productId.startsWith('com.wallrio.collection.')
        ? widget.collection.productId
        : 'com.wallrio.collection.${widget.collection.productId}';
    final product = subProvider.products
        .cast<dynamic>()
        .firstWhere((p) => p.id == fullProductId, orElse: () => null);

    final int diamondCost = 750;
    final int userDiamonds = progProvider.progression?.diamondsBalance ?? 0;
    final bool canAfford = userDiamonds >= diamondCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.lock_rounded,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unlock ${widget.collection.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Diamond Option
          _buildOptionCard(
            context: context,
            title: 'Use Diamonds',
            subtitle: 'Balance: $userDiamonds 💎',
            trailingText: '$diamondCost 💎',
            icon: Icons.diamond_rounded,
            iconColor: Colors.blueAccent,
            onTap: () async {
              if (canAfford) {
                final success = await progProvider.redeemCollection(
                    widget.collection.productId, diamondCost);
                if (success) {
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                }
              } else {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RewardsHubPage()));
              }
            },
            buttonText: canAfford ? 'Redeem' : 'Earn More',
            isPrimary: false,
          ),
          const SizedBox(height: 12),

          // 2. Buy Collection Option
          _buildOptionCard(
            context: context,
            title: 'Buy Collection',
            subtitle: 'Yours forever (One-time)',
            trailingText: product != null ? product.price : '...',
            icon: Icons.shopping_cart_rounded,
            iconColor: Colors.green,
            onTap: _isProcessingPurchase ? () {} : () {
              if (product == null) {
                ToastWidget.showToast(
                    'Purchase currently unavailable. Try again later.');
                return;
              }
              setState(() {
                _isProcessingPurchase = true;
              });
              subProvider.buyProduct(product);
            },
            buttonText: _isProcessingPurchase ? 'Processing...' : 'Buy',
            isPrimary: false,
          ),
          const SizedBox(height: 12),

          // 3. Pro Subscription Option
          _buildOptionCard(
            context: context,
            title: 'Get Pro',
            subtitle: 'All collections (Yearly/Lifetime) + premium walls',
            trailingText: '',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (navContext) => OnboardingScreen4(
                            onComplete: () {
                              Navigator.pop(navContext);
                            },
                          )));
            },
            buttonText: 'Subscribe',
            isPrimary: true,
          ),




          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String trailingText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String buttonText,
    required bool isPrimary,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary
            ? null
            : (isDarkMode
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03)),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.2),
                  iconColor.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: isPrimary
              ? iconColor.withValues(alpha: 0.6)
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          width: isPrimary ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailingText.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              trailingText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isPrimary
                    ? iconColor
                    : (isDarkMode ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  color: isPrimary ? Colors.black : textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!isPrimary) return cardContent;

    // Wrap Primary card with a Best Value Badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cardContent,
        Positioned(
          top: -10,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'BEST VALUE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
