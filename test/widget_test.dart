// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallrio/services/consent_manager.dart';
import 'package:wallrio/ui/widgets/image_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConsentManager initialization smoke test', () {
    expect(ConsentManager.instance, isNotNull);
  });

  testWidgets('wallpaper image supports navigation stack layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                sizing: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 150,
                                child: CNImage(
                                  imageUrl: 'https://example.com/wallpaper.jpg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SizedBox(height: 60),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('featured wallpaper row supports intrinsic measurement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CNImage(imageUrl: 'https://example.com/wallpaper.jpg'),
                ),
                SizedBox(width: 100, height: 150),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scenario in [
    (name: 'thumbnail', height: 150.0, original: false, expected: 800),
    (name: 'larger thumbnail', height: 450.0, original: false, expected: 800),
    (
      name: 'full-screen preview',
      height: 150.0,
      original: true,
      expected: 1600,
    ),
  ]) {
    testWidgets('${scenario.name} uses bounded decoding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              devicePixelRatio: 2,
            ),
            child: Center(
              child: SizedBox(
                width: 100,
                height: scenario.height,
                child: CNImage(
                  imageUrl: 'https://example.com/wallpaper.jpg',
                  isOriginalImg: scenario.original,
                ),
              ),
            ),
          ),
        ),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.memCacheHeight, scenario.expected);
      expect(image.memCacheWidth, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
