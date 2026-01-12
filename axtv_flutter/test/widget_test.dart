import 'package:flutter_test/flutter_test.dart';
import 'package:axtv_flutter/app.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('AxTV'), findsNothing);
  });
}
