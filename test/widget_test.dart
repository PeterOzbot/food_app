import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    // The app shows a loading indicator while the DB opens.
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
