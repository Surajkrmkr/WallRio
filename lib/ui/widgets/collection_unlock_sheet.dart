import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
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

      final String shortId = widget.collection.productId.split('.').last;
      final String fullProductId = widget.collection.productId.startsWith('com.wallrio.collection.')
          ? widget.collection.productId
          : 'com.wallrio.collection.${widget.collection.productId}';

      subProvider.fetchProducts({fullProductId, shortId, widget.collection.productId});

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
              Navigator.pop(context);
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

    final String shortId = widget.collection.productId.split('.').last;
    final String fullProductId = widget.collection.productId.startsWith('com.wallrio.collection.')
        ? widget.collection.productId
        : 'com.wallrio.collection.${widget.collection.productId}';

    final product = subProvider.products
        .cast<dynamic>()
        .firstWhere((p) => p != null && (p.id == fullProductId || p.id == shortId || p.id.endsWith(shortId)), orElse: () => null);

    final wallCount = widget.collection.walls?.length ?? 0;
    final sheetColor = isDarkMode ? bgDark2Color : const Color(0xFFF2F2F7);

    Widget sheetContent = glassSheetBackground(
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
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ABFAA), Color(0xFF178A76)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ABFAA).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.collections_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.collection.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock full access to all wallpapers in this pack',
              style: TextStyle(
                fontSize: 13,
                color: subColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.photo_library_rounded,
                    text: '$wallCount Ultra-HD Wallpapers included',
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.all_inclusive_rounded,
                    text: 'Unlimited downloads & full resolution',
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.workspace_premium_rounded,
                    text: 'Permanent access once unlocked',
                    textColor: textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessingPurchase
                    ? null
                    : () async {
                        if (product != null) {
                          setState(() => _isProcessingPurchase = true);
                          await subProvider.buyProduct(product);
                          if (mounted) {
                            setState(() => _isProcessingPurchase = false);
                            Navigator.pop(context);
                          }
                        } else {
                          ToastWidget.showToast('Product store unavailable');
                        }
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

    if (ResponsiveHelper.isTablet(context)) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: sheetContent,
        ),
      );
    }

    return sheetContent;
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
