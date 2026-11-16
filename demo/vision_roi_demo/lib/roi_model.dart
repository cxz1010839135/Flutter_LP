import 'dart:ui';

/// ROI 类型：矩形框 / 卡尺线 / 圆（椭圆）
enum RoiType { rect, line, ellipse }

/// 画布工具模式
enum ToolMode { select, rect, line, ellipse }

/// 一个 ROI 形状。
///
/// 坐标一律使用【图像像素坐标系】（即下位机图像的原始像素坐标），
/// 显示时的缩放/平移由画布层负责换算，本类不关心显示状态。
class RoiShape {
  RoiShape({
    required this.id,
    required this.type,
    required this.p1,
    required this.p2,
    this.params = const <String, dynamic>{},
  });

  final String id;
  final RoiType type;

  /// rect/ellipse: 包围盒两个对角点；line: 起点（箭头尾）→ 终点（箭头方向）
  Offset p1;
  Offset p2;

  /// 该 ROI 自带的处理参数（阈值、极性等，demo 里先全局，结构上预留）
  Map<String, dynamic> params;

  Rect get bounds => Rect.fromPoints(p1, p2);

  bool contains(Offset point, [double slack = 6]) {
    switch (type) {
      case RoiType.rect:
        return bounds.inflate(slack).contains(point);
      case RoiType.ellipse:
        final r = bounds.inflate(slack);
        final c = r.center;
        final a = r.width / 2;
        final b = r.height / 2;
        if (a <= 0 || b <= 0) return false;
        final v = (point.dx - c.dx) / a * ((point.dx - c.dx) / a) +
            (point.dy - c.dy) / b * ((point.dy - c.dy) / b);
        return v <= 1;
      case RoiType.line:
        final rect = Rect.fromPoints(p1, p2).inflate(slack);
        if (!rect.contains(point)) return false;
        // 点到线段距离
        final dir = p2 - p1;
        final len2 = dir.distanceSquared;
        if (len2 < 1) return (point - p1).distance <= slack;
        var t = ((point - p1).dx * dir.dx + (point.dy - p1.dy) * dir.dy) / len2;
        t = t.clamp(0.0, 1.0);
        final proj = p1 + dir * t;
        return (point - proj).distance <= slack;
    }
  }

  /// 角点/端点手柄（图像坐标）
  List<Offset> handles() {
    switch (type) {
      case RoiType.line:
        return [p1, p2];
      default:
        final r = bounds;
        return [
          r.topLeft,
          r.topRight,
          r.bottomLeft,
          r.bottomRight,
        ];
    }
  }

  void setHandle(int index, Offset value) {
    switch (type) {
      case RoiType.line:
        if (index == 0) {
          p1 = value;
        } else {
          p2 = value;
        }
        return;
      default:
        switch (index) {
          case 0:
            p1 = value;
          case 1:
            p1 = Offset(value.dx, p1.dy);
            p2 = Offset(p2.dx, value.dy);
          case 2:
            p1 = Offset(value.dx, p1.dy);
            p2 = Offset(p2.dx, value.dy);
          case 3:
            p2 = value;
        }
        // 规范化：保证 bounds 方向一致
        final r = Rect.fromPoints(p1, p2);
        p1 = r.topLeft;
        p2 = r.bottomRight;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'p1': <double>[p1.dx, p1.dy],
        'p2': <double>[p2.dx, p2.dy],
        'params': params,
      };

  static RoiShape fromJson(Map<String, dynamic> json) {
    final p1 = List<double>.from(json['p1'] as List);
    final p2 = List<double>.from(json['p2'] as List);
    return RoiShape(
      id: json['id'] as String,
      type: RoiType.values.byName(json['type'] as String),
      p1: Offset(p1[0], p1[1]),
      p2: Offset(p2[0], p2[1]),
      params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
