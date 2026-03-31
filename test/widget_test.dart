import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodgram/main.dart';

void main() {
  testWidgets('FoodGramApp smoke test', (WidgetTester tester) async {
    // Build the app wrapped in ProviderScope (required by Riverpod).
    await tester.pumpWidget(
      const ProviderScope(
        child: FoodGramApp(),
      ),
    );

    // Pump one frame — the app should render without throwing.
    await tester.pump();

    // The app should be present in the widget tree.
    expect(find.byType(FoodGramApp), findsOneWidget);
  });
}
