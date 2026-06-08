import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App shows Blockly demo page', (WidgetTester tester) async {
    await tester.pumpWidget(const LpRobotApp());
    await tester.pump();

    expect(find.text('领鹏智能编程'), findsOneWidget);
  });
}
