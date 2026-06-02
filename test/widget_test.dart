import 'package:flutter_test/flutter_test.dart';

import 'package:mxpertz_test/main.dart';

void main() {
  testWidgets('shows the LuxeLoft splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('uxeLoft'), findsOneWidget);
  });
}
