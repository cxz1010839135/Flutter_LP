import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App shows connect page', (WidgetTester tester) async {
    await tester.pumpWidget(const LpRobotApp());
    await tester.pump();

    // 启动首屏为连接页：主按钮「连接」+ 离线预览按钮「不连接机器人」。
    expect(find.text('连接'), findsOneWidget);
    expect(find.text('离线预览'), findsOneWidget);
  });
}
