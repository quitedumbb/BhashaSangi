import 'package:flutter_test/flutter_test.dart';
import 'package:bhasha_sangi_frontend/main.dart';

void main() {
  testWidgets('Bhasha Sangi app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BhashaSangiApp());
    await tester.pump();

    // Verify brand title is present
    expect(find.text('BHASHA SANGI'), findsWidgets);
  });
}
