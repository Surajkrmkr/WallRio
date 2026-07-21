import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/theme_data.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final String fullProductId = widget.collection.productId.startsWith('com.wallrio.collection.')
        ? widget.collection.productId
        : 'com.wallrio.collection.${widget.collection.productId}';
    final product = subProvider.products
        .cast<dynamic>()
        .firstWhere((p) => p.id == fullProductId, orElse: () => null);

    final wallCount = widget.collection.walls?.length ?? 0;
    // Matches Profile's bottom sheet background color token
    final sheetColor = isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7);

    return glassSheetBackground(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: supportsGlassSheet ? Colors.transparent : sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgDarkAccentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, color: bgDarkAccentColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock ${widget.collection.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wallCount > 0
                  ? 'Get instant access to all $wallCount wallpapers in this collection — forever.'
                  : 'Get instant access to every wallpaper in this collection — forever.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              icon: Icons.all_inclusive_rounded,
              text: 'Every wallpaper in ${widget.collection.name}',
              textColor: textColor,
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.high_quality_rounded,
              text: 'Full-resolution downloads',
              textColor: textColor,
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.bolt_rounded,
              text: 'One-time payment, no subscription',
              textColor: textColor,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessingPurchase
                    ? null
                    : () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgDarkAccentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: bgDarkAccentColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isProcessingPurchase
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        product != null ? 'Unlock for ${product.price}' : 'Unlock Collection',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
      tint: sheetColor,
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: bgDarkAccentColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
