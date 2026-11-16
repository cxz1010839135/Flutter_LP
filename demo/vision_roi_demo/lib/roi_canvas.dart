import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'mjpeg_client.dart';
import 'roi_model.dart';

/// 视觉画布：
/// - 显示 MJPEG 流当前帧（fit 包含于视口，保持纵横比）
/// - 在图像上叠加 ROI（图像像素坐标系），支持选择/拖动/改端点、按模式新建
/// - 滚轮缩放（以光标为中心）、空手拖动平移
class VisionCanvas extends StatefulWidget {
  const VisionCanvas({
    super.key,
    required this.stream,
    required this.rois,
    required this.selectedId,
    required this.mode,
    required this.onSelect,
    required this.onCreate,
    required this.onUpdate,
  });

  final MjpegStream stream;
  final List<RoiShape> rois;
  final String? selectedId;
  final ToolMode mode;
  final ValueChanged<String?> onSelect;
  final ValueChanged<RoiShape> onCreate;
  final ValueChanged<RoiShape> onUpdate;

  @override
  State<VisionCanvas> createState() => _VisionCanvasState();
}

enum _DragAction { none, pan, create, move, resize }

class _VisionCanvasState extends State<VisionCanvas> {
  double _zoom = 1.0;
  Offset _pan = Offset.zero; // 视口像素

  _DragAction _action = _DragAction.none;
  Offset _lastViewport = Offset.zero;
  RoiShape? _draft;
  int _resizeIndex = -1;

  // ---- 坐标系 ---------------------------------------------------------
  // 视口 → 显示空间：center + pan，再整体 scale(zoom)
  Matrix4 _matrix(Size vp, Size disp) {
    final m = Matrix4.identity()
      ..translateByDouble((vp.width - disp.width) / 2, (vp.height - disp.height) / 2, 0, 1)
      ..translateByDouble(_pan.dx, _pan.dy, 0, 1)
      ..translateByDouble(disp.width / 2, disp.height / 2, 0, 1)
      ..scaleByDouble(_zoom, _zoom, 1, 1)
      ..translateByDouble(-disp.width / 2, -disp.height / 2, 0, 1);
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: widget.stream.image,
      builder: (context, img, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: widget.stream.error,
          builder: (context, err, _) {
            return LayoutBuilder(builder: (context, cons) {
              final vp = Size(cons.maxWidth, cons.maxHeight);
              Widget content;
              if (img == null) {
                content = Stack(children: [
                  Center(
                    child: Text(
                      err == null ? '等待图像流…' : '图像流错误：$err',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                    ),
                  ),
                ]);
              } else {
                final iw = img.width.toDouble();
                final ih = img.height.toDouble();
                final fit = math.min(vp.width / iw, vp.height / ih);
                final disp = Size(iw * fit, ih * fit);
                final m = _matrix(vp, disp);
                content = Stack(children: [
                  Transform(
                    transform: m,
                    child: SizedBox(
                      width: disp.width,
                      height: disp.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _FramePainter(img)),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RoiPainter(
                                rois: widget.rois,
                                selectedId: widget.selectedId,
                                draft: _draft,
                                // ROI 存图像像素坐标，显示空间 = 图像 × fit，
                                // 必须与帧内容同缩放，否则与图像（及下位机回显）错位
                                scale: fit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ZoomBar(
                      zoom: _zoom,
                      onZoomIn: () => _zoomAt(vp, disp, vp.center(Offset.zero), 3),
                      onZoomOut: () => _zoomAt(vp, disp, vp.center(Offset.zero), -3),
                      onReset: () => setState(() {
                        _zoom = 1;
                        _pan = Offset.zero;
                      }),
                    ),
                  ),
                ]);
              }
              return MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: ClipRect(
                  child: Listener(
                    onPointerSignal: (s) {
                      if (s is PointerScrollEvent && img != null) {
                        final iw = img.width.toDouble();
                        final ih = img.height.toDouble();
                        final fit = math.min(vp.width / iw, vp.height / ih);
                        _zoomAt(vp, Size(iw * fit, ih * fit), s.localPosition,
                            -s.scrollDelta.dy / 6.0);
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (d) => img != null
                          ? _onDown(vp, _dispSize(vp, img), d.localFocalPoint, img)
                          : null,
                      onScaleUpdate: (d) => img != null
                          ? _onMove(vp, _dispSize(vp, img), d.localFocalPoint)
                          : null,
                      onScaleEnd: (_) => _onUp(),
                      child: content,
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  Size _dispSize(Size vp, ui.Image img) {
    final fit = math.min(vp.width / img.width, vp.height / img.height);
    return Size(img.width * fit, img.height * fit);
  }

  // ---- 手势 -----------------------------------------------------------

  Offset _toImage(Size vp, Size disp, Offset viewportPoint, ui.Image img) {
    final m = _matrix(vp, disp);
    final inv = Matrix4.inverted(m);
    final p = MatrixUtils.transformPoint(inv, viewportPoint);
    // 显示空间 → 图像像素
    return Offset(p.dx * img.width / disp.width, p.dy * img.height / disp.height);
  }

  Offset _imageDelta(Size disp, ui.Image img, Offset viewportDelta) {
    final k = img.width / disp.width;
    return viewportDelta * k / _zoom;
  }

  void _onDown(Size vp, Size disp, Offset pos, ui.Image img) {
    _lastViewport = pos;
    final imgPos = _toImage(vp, disp, pos, img);

    if (widget.mode != ToolMode.select) {
      _action = _DragAction.create;
      _draft = RoiShape(
        id: 'draft',
        type: switch (widget.mode) {
          ToolMode.rect => RoiType.rect,
          ToolMode.line => RoiType.line,
          _ => RoiType.ellipse,
        },
        p1: imgPos,
        p2: imgPos,
      );
      return;
    }

    // 已选中的 ROI：优先命中手柄
    final sel = _find(widget.selectedId);
    if (sel != null) {
      final handles = sel.handles();
      for (int i = 0; i < handles.length; i++) {
        if ((handles[i] - imgPos).distance <= 10) {
          _action = _DragAction.resize;
          _resizeIndex = i;
          return;
        }
      }
    }
    // 命中任意 ROI（后画的优先）
    for (final r in widget.rois.reversed) {
      if (r.contains(imgPos)) {
        widget.onSelect(r.id);
        _action = _DragAction.move;
        return;
      }
    }
    _action = _DragAction.pan;
  }

  void _onMove(Size vp, Size disp, Offset pos) {
    final deltaViewport = pos - _lastViewport;
    _lastViewport = pos;
    final img = widget.stream.image.value;
    if (img == null) return;

    switch (_action) {
      case _DragAction.none:
        return;
      case _DragAction.pan:
        setState(() => _pan += deltaViewport);
      case _DragAction.create:
        final imgPos = _toImage(vp, disp, pos, img);
        setState(() {
          _draft?.p2 = imgPos;
        });
      case _DragAction.move:
        final sel = _find(widget.selectedId);
        if (sel == null) return;
        setState(() {
          final d = _imageDelta(disp, img, deltaViewport);
          sel.p1 += d;
          sel.p2 += d;
          _clampRoi(sel, img);
        });
        widget.onUpdate(sel);
      case _DragAction.resize:
        final sel = _find(widget.selectedId);
        if (sel == null) return;
        setState(() {
          final imgPos = _toImage(vp, disp, pos, img);
          sel.setHandle(_resizeIndex, imgPos);
          _clampRoi(sel, img);
        });
        widget.onUpdate(sel);
    }
  }

  void _onUp() {
    if (_action == _DragAction.create && _draft != null) {
      final d = _draft!;
      final minLen = (d.type == RoiType.line)
          ? (d.p2 - d.p1).distance >= 8
          : d.bounds.width >= 8 && d.bounds.height >= 8;
      if (minLen) {
        widget.onCreate(d);
      }
    }
    _draft = null;
    _action = _DragAction.none;
    _resizeIndex = -1;
  }

  RoiShape? _find(String? id) {
    if (id == null) return null;
    for (final r in widget.rois) {
      if (r.id == id) return r;
    }
    return null;
  }

  void _clampRoi(RoiShape r, ui.Image img) {
    final size = Size(img.width.toDouble(), img.height.toDouble());
    Offset cl(Offset p) => Offset(
          p.dx.clamp(0, size.width),
          p.dy.clamp(0, size.height),
        );
    r.p1 = cl(r.p1);
    r.p2 = cl(r.p2);
  }

  void _zoomAt(Size vp, Size disp, Offset cursor, double dz) {
    setState(() {
      final old = _zoom;
      _zoom = (_zoom * math.pow(1.002, dz * 100)).clamp(0.5, 8.0);
      if (_zoom == old) return;
      // 保持光标下的图像点不动：光标相对显示中心的位置变化量补偿到 pan
      final center = Offset(vp.width / 2, vp.height / 2) + _pan;
      final off = cursor - center;
      _pan += off * (1 - old / _zoom) * 1.0;
    });
  }
}

// ---------------------------------------------------------------- painters

class _FramePainter extends CustomPainter {
  _FramePainter(this.image);

  final ui.Image image;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.image != image;
}

class _RoiPainter extends CustomPainter {
  _RoiPainter({
    required this.rois,
    required this.selectedId,
    required this.draft,
    required this.scale,
  });

  final List<RoiShape> rois;
  final String? selectedId;
  final RoiShape? draft;

  /// 显示空间 = 图像像素 × scale（帧内容按同比例缩放）
  final double scale;

  static const _green = Color(0xFF22C55E);
  static const _cyan = Color(0xFF22D3EE);
  static const _yellow = Color(0xFFFACC15);
  static const _white = Color(0xFFE5E7EB);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.scale(scale);
    for (final r in rois) {
      _paintShape(canvas, r, selected: r.id == selectedId);
    }
    if (draft != null) {
      _paintShape(canvas, draft!, selected: true);
    }
  }

  void _paintShape(ui.Canvas canvas, RoiShape r, {required bool selected}) {
    final mainColor = r.type == RoiType.line ? _cyan : _green;
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = selected ? 2.4 : 1.8
      ..color = selected ? _yellow : mainColor;

    switch (r.type) {
      case RoiType.rect:
        canvas.drawRect(r.bounds, stroke);
        _drawLabel(canvas, r, '矩形 ${r.bounds.width.round()}×${r.bounds.height.round()}');
      case RoiType.ellipse:
        canvas.drawOval(r.bounds, stroke);
        _drawLabel(canvas, r, '圆 D${r.bounds.width.round()}');
      case RoiType.line:
        canvas.drawLine(r.p1, r.p2, stroke);
        _drawCaliperTicks(canvas, r, mainColor);
        _drawArrow(canvas, r.p1, r.p2, mainColor);
        _drawLabel(canvas, r, '卡尺 ${(r.p2 - r.p1).distance.round()}px');
    }

    if (selected) {
      final hp = ui.Paint()..color = _yellow;
      final hb = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const ui.Color(0xFF111111);
      for (final h in r.handles()) {
        canvas.drawRect(Rect.fromCenter(center: h, width: 9, height: 9), hp);
        canvas.drawRect(Rect.fromCenter(center: h, width: 9, height: 9), hb);
      }
    }
  }

  void _drawCaliperTicks(ui.Canvas canvas, RoiShape r, ui.Color color) {
    final dir = r.p2 - r.p1;
    final len = dir.distance;
    if (len < 2) return;
    final unit = dir / len;
    final normal = ui.Offset(-unit.dy, unit.dx);
    final tick = ui.Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (double d = 0; d <= len; d += 14) {
      final p = r.p1 + unit * d;
      canvas.drawLine(p - normal * 4, p + normal * 4, tick);
    }
  }

  void _drawArrow(ui.Canvas canvas, ui.Offset from, ui.Offset to, ui.Color color) {
    final dir = to - from;
    final len = dir.distance;
    if (len < 2) return;
    final unit = dir / len;
    final normal = ui.Offset(-unit.dy, unit.dx);
    final back = to - unit * 13;
    final path = ui.Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo((back + normal * 6).dx, (back + normal * 6).dy)
      ..lineTo((back - normal * 6).dx, (back - normal * 6).dy)
      ..close();
    canvas.drawPath(path, ui.Paint()..color = color);
  }

  void _drawLabel(ui.Canvas canvas, RoiShape r, String text) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 11))
      ..pushStyle(ui.TextStyle(color: _white))
      ..addText(text);
    final p = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 200));
    final at = Offset(
      math.max(0.0, r.bounds.left),
      math.max(0.0, r.bounds.top - 16),
    );
    canvas.drawParagraph(p, at);
  }

  @override
  bool shouldRepaint(covariant _RoiPainter oldDelegate) => true;
}

// ---------------------------------------------------------------- 缩放条

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xCC1B1D21);
    Widget btn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(icon, size: 16, color: const Color(0xFFD1D5DB)),
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.add, '放大', onZoomIn),
          SizedBox(
            width: 52,
            child: Text(
              '${(zoom * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE5E7EB)),
            ),
          ),
          btn(Icons.remove, '缩小', onZoomOut),
          btn(Icons.center_focus_strong, '复位', onReset),
        ],
      ),
    );
  }
}
