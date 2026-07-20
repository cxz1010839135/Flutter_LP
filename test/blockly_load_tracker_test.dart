import 'package:flutter_application_1/blockly/lp_blockly_load_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('加载超时不会伪装成完成并关闭遮罩', () async {
    final events = <({int percent, String message})>[];
    final tracker = LpBlocklyLoadTracker(
      onProgress: (percent, message) {
        events.add((percent: percent, message: message));
      },
      maxLoadDuration: const Duration(milliseconds: 10),
    );

    tracker.reset();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(events, isNotEmpty);
    expect(events.last.percent, 98);
    expect(events.last.message, contains('继续检测'));
    expect(events.any((event) => event.percent == 100), isFalse);

    tracker.dispose();
  });

  test('页面和资源就绪后正常完成', () async {
    final percents = <int>[];
    final tracker = LpBlocklyLoadTracker(
      onProgress: (percent, _) => percents.add(percent),
      idleDuration: const Duration(milliseconds: 10),
      maxLoadDuration: const Duration(seconds: 1),
    );

    tracker.reset();
    tracker.handleRequest(
      const BlocklyServerRequestEvent(
        method: 'GET',
        path: '/blockly/demos/code/index.html',
        statusCode: 200,
        index: 1,
      ),
    );
    tracker.markJsLoadComplete();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(percents.last, 100);
    tracker.dispose();
  });

  test('只有 HTTP 请求或出现 404 时不能判定 Blockly 已就绪', () async {
    final events = <({int percent, String message})>[];
    final tracker = LpBlocklyLoadTracker(
      onProgress: (percent, message) {
        events.add((percent: percent, message: message));
      },
      idleDuration: const Duration(milliseconds: 10),
      maxLoadDuration: const Duration(seconds: 1),
    );

    tracker.reset();
    for (var i = 0; i < 8; i++) {
      tracker.handleRequest(
        BlocklyServerRequestEvent(
          method: 'GET',
          path: '/blockly/module_$i.js',
          statusCode: i == 3 ? 404 : 200,
          index: i + 1,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(events.any((event) => event.percent == 100), isFalse);
    expect(events.any((event) => event.message.contains('HTTP 404')), isTrue);
    tracker.dispose();
  });
}
