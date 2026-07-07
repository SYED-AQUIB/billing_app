import 'package:flutter_test/flutter_test.dart';

import 'package:grocery_billing_app/main.dart';

void main() {
  testWidgets('app starts on the home screen with navigation cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Grocery Billing'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
  });
}
