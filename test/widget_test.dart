// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallrio/services/ads_config.dart';
import 'package:wallrio/services/consent_manager.dart';
import 'package:wallrio/ui/widgets/ads_widget.dart';
import 'package:wallrio/ui/widgets/inline_banner_ad_widget.dart';
import 'package:wallrio/ui/widgets/shimmer_widget.dart';
import 'package:wallrio/ui/widgets/sponsored_ad_card.dart';
import 'package:wallrio/ui/widgets/sticky_bottom_banner_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConsentManager initialization smoke test', () {
    expect(ConsentManager.instance, isNotNull);
  });

  testWidgets('Disabled ads render no banners or loading placeholders',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AdsWidget(),
            InlineBannerAdWidget(),
            StickyBottomBannerWidget(),
            SponsoredAdCard(),
          ],
        ),
      ),
    ));

    expect(find.byType(AdWidget), findsNothing);
    expect(find.byType(ShimmerWidget), findsNothing);
    for (final widgetType in [
      AdsWidget,
      InlineBannerAdWidget,
      StickyBottomBannerWidget,
      SponsoredAdCard,
    ]) {
      expect(tester.getSize(find.byType(widgetType)).height, 0);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: AdsConfig.enabled);

  testWidgets('Disabled ads hide the rewarded unlock action', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => AdsWidget.getPlusDialog(context),
      ),
    ));

    expect(find.text('Watch Ad to Unlock'), findsNothing);
    expect(find.text('Go PRO'), findsOneWidget);
    expect(find.text('Upgrade to PRO to get access to premium wallpapers.'),
      findsOneWidget);
  }, skip: AdsConfig.enabled);
}
