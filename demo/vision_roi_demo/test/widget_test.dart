import 'package:flutter_test/flutter_test.dart';

import 'package:vision_roi_demo/roi_model.dart';

void main() {
  test('RoiShape toJson/fromJson 往返保持图像像素坐标', () {
    final r = RoiShape(
      id: 'roi-1',
      type: RoiType.line,
      p1: const Offset(100.5, 200.25),
      p2: const Offset(300, 200.25),
      params: const {'threshold': 128},
    );

    final json = r.toJson();
    final back = RoiShape.fromJson(json);

    expect(back.id, 'roi-1');
    expect(back.type, RoiType.line);
    expect(back.p1, r.p1);
    expect(back.p2, r.p2);
    expect(back.params, {'threshold': 128});
  });

  test('RoiShape rect/ellipse 序列化', () {
    for (final type in RoiType.values) {
      final r = RoiShape(
        id: 'id-$type',
        type: type,
        p1: const Offset(10, 20),
        p2: const Offset(110, 120),
      );
      final back = RoiShape.fromJson(r.toJson());
      expect(back.type, type);
      expect(back.bounds, r.bounds);
    }
  });

  test('contains 命中判断', () {
    final rect = RoiShape(
      id: 'r',
      type: RoiType.rect,
      p1: const Offset(0, 0),
      p2: const Offset(100, 100),
    );
    expect(rect.contains(const Offset(50, 50)), isTrue);
    expect(rect.contains(const Offset(200, 200)), isFalse);

    final line = RoiShape(
      id: 'l',
      type: RoiType.line,
      p1: const Offset(0, 50),
      p2: const Offset(100, 50),
    );
    expect(line.contains(const Offset(50, 52)), isTrue);
    expect(line.contains(const Offset(50, 90)), isFalse);
  });
}
