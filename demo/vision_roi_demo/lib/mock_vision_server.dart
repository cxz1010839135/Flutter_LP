import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'roi_model.dart';
import 'vision_params.dart';

/// 模拟下位机（视觉处理机）：
/// - GET  /stream            原始图像 MJPEG 流（multipart/x-mixed-replace，PNG 帧）
/// - GET  /processed/stream  处理结果流（叠加 ROI 描绘 + 模拟检测结果 + 收到的参数）
/// - POST /params            接收本机下发的 ROI + 参数（JSON），结果流实时生效
/// - GET  /status            基本信息
///
/// demo 阶段帧编码用 PNG（dart:ui 只有 PNG 编码器）；真实下位机通常是 JPEG，
/// 本机解析按帧二进制处理，两者无差别。
class MockVisionServer {
  MockVisionServer({this.frameW = 800, this.frameH = 600});

  final int frameW;
  final int frameH;

  static const _boundary = 'framebound';

  HttpServer? _server;
  bool _running = false;
  int _frameIndex = 0;
  double get _t => _frameIndex / 60.0;

  List<RoiShape> _rois = <RoiShape>[];
  Map<String, dynamic> _params = <String, dynamic>{};

  final List<StreamController<List<int>>> _rawSubs = <StreamController<List<int>>>[];
  final List<StreamController<List<int>>> _processedSubs = <StreamController<List<int>>>[];

  int get port => _server?.port ?? 0;
  bool get running => _running;

  Future<void> start({int port = 8600}) async {
    if (_running) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _running = true;
    _server!.listen(_onRequest, onError: (Object e) {/* 连接被客户端断开等，忽略 */});
    _loop();
  }

  Future<void> stop() async {
    _running = false;
    for (final s in _rawSubs) {
      await s.close();
    }
    for (final s in _processedSubs) {
      await s.close();
    }
    _rawSubs.clear();
    _processedSubs.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _loop() async {
    while (_running) {
      await _produceFrame();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  void _onRequest(HttpRequest req) {
    switch (req.uri.path) {
      case '/stream':
        _serveStream(req, _rawSubs);
      case '/processed/stream':
        _serveStream(req, _processedSubs);
      case '/params':
        _onParams(req);
      case '/status':
        _onStatus(req);
      default:
        req.response.statusCode = HttpStatus.notFound;
        req.response.close();
    }
  }

  void _serveStream(HttpRequest req, List<StreamController<List<int>>> subs) {
    req.response.statusCode = HttpStatus.ok;
    req.response.headers.set('Content-Type', 'multipart/x-mixed-replace; boundary=$_boundary');
    req.response.headers.set('Cache-Control', 'no-cache');
    final ctl = StreamController<List<int>>();
    req.response.addStream(ctl.stream).then((_) {
      req.response.close();
    }).catchError((Object e) {
      try {
        req.response.close();
      } catch (_) {}
    });
    subs.add(ctl);
    ctl.onCancel = () => subs.remove(ctl);
  }

  Future<void> _onParams(HttpRequest req) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final list = (json['rois'] as List?) ?? const [];
      _rois = list
          .map((e) => RoiShape.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      _params = ((json['params'] as Map?) ?? const {}).cast<String, dynamic>();
      // fail-loud：非法参数拒绝接收（校验逻辑与下位机真实实现同源同语义）
      final errs = VisionParams.fromJson(_params).validate();
      if (errs.isNotEmpty) {
        req.response.statusCode = HttpStatus.unprocessableEntity;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(<String, dynamic>{
          'ok': false,
          'code': errs,
        }));
        await req.response.close();
        return;
      }
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(<String, dynamic>{
        'ok': true,
        'rois': _rois.length,
        'params': _params,
      }));
    } catch (e) {
      req.response.statusCode = HttpStatus.badRequest;
      req.response.write(jsonEncode(<String, dynamic>{'ok': false, 'error': '$e'}));
    }
    await req.response.close();
  }

  Future<void> _onStatus(HttpRequest req) async {
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(<String, dynamic>{
      'ok': true,
      'width': frameW,
      'height': frameH,
      'frames': _frameIndex,
    }));
    await req.response.close();
  }

  // ---------------------------------------------------------------- frame

  Future<void> _produceFrame() async {
    final base = await _render(_drawBase);
    _frameIndex++;
    final processed = await _render(_drawProcessed);
    _broadcast(_rawSubs, base);
    _broadcast(_processedSubs, processed);
  }

  void _broadcast(List<StreamController<List<int>>> subs, Uint8List bytes) {
    final part = BytesBuilder()
      ..add(utf8.encode('--$_boundary\r\nContent-Type: image/png\r\nContent-Length: ${bytes.length}\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n'));
    final data = part.takeBytes();
    for (final s in List<StreamController<List<int>>>.from(subs)) {
      s.add(data);
    }
  }

  Future<Uint8List> _render(void Function(ui.Canvas c) painter) async {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec, Offset.zero & Size(frameW.toDouble(), frameH.toDouble()));
    painter(canvas);
    final img = await rec.endRecording().toImage(frameW, frameH);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return data!.buffer.asUint8List();
  }

  Offset get _partCenter => Offset(
        frameW / 2 + 240 * math.sin(_t * 0.7),
        frameH / 2 + 140 * math.cos(_t * 0.5),
      );

  void _drawBase(ui.Canvas c) {
    final w = frameW.toDouble();
    final h = frameH.toDouble();
    // 背景
    c.drawRect(Offset.zero & Size(w, h), ui.Paint()..color = const ui.Color(0xFF1C1E22));
    // 网格
    final grid = ui.Paint()..color = const ui.Color(0xFF26292F)..strokeWidth = 1;
    for (double x = 0; x <= w; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y <= h; y += 40) {
      c.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    // 十字中心
    final cross = ui.Paint()
      ..color = const ui.Color(0xFF3A3F48)
      ..strokeWidth = 1;
    c.drawLine(Offset(w / 2, h / 2 - 16), Offset(w / 2, h / 2 + 16), cross);
    c.drawLine(Offset(w / 2 - 16, h / 2), Offset(w / 2 + 16, h / 2), cross);

    // 移动的“工件”
    final center = _partCenter;
    final partRect = Rect.fromCenter(center: center, width: 220, height: 140);
    c.drawRRect(
      ui.RRect.fromRectAndRadius(partRect, const ui.Radius.circular(10)),
      ui.Paint()..color = const ui.Color(0xFFB9BEC6),
    );
    // 高光边缘
    c.drawRRect(
      ui.RRect.fromRectAndRadius(partRect.deflate(3), const ui.Radius.circular(8)),
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const ui.Color(0xFFDFE3E8),
    );
    // 圆孔
    c.drawCircle(center.translate(55, -25), 26, ui.Paint()..color = const ui.Color(0xFF14161A));
    // 第二个小孔
    c.drawCircle(center.translate(-65, 30), 14, ui.Paint()..color = const ui.Color(0xFF14161A));

    _drawCaption(c, 'MOCK CAM  800x600  frame=$_frameIndex', const Offset(10, 10),
        const ui.Color(0xFF6B7280));
  }

  void _drawProcessed(ui.Canvas c) {
    _drawBase(c);

    final green = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const ui.Color(0xFF22C55E);
    final red = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const ui.Color(0xFFEF4444);
    final yellow = const ui.Color(0xFFFACC15);

    final threshold = _params['threshold'];
    final polarity = _params['polarity'];
    _drawCaption(c, '阈值:${threshold ?? '-'}  极性:${polarity ?? '-'}  ROI:${_rois.length}',
        const Offset(10, 30), yellow);

    // ---- Z 偏移槽模拟 ----
    final zMode = _params['z_mode'];
    switch (zMode) {
      case 'measured':
        final refV = (_params['z_reference_v'] as num?)?.toDouble() ?? -1;
        final mmpp = (_params['z_mm_per_pixel'] as num?)?.toDouble() ?? 0;
        final dir = (_params['z_direction'] as num?)?.toInt() ?? 1;
        final fixed = (_params['z_fixed_offset_mm'] as num?)?.toDouble() ?? 0;
        final idx = (_params['z_value_index'] as num?)?.toInt() ?? 0;
        // 模拟“检测 v”：工件在视场中的垂直位置随移动变化
        final vMeas = _partCenter.dy + idx * 10;
        final dz = dir * (refV - vMeas) * mmpp + fixed;
        _drawCaption(c, 'z_mode=measured  dz=${dz.toStringAsFixed(2)}mm  '
            'v=${vMeas.toStringAsFixed(0)} 固定:$fixed', const Offset(10, 50), yellow);
      case 'random':
        _drawCaption(c, 'z_mode=random  ±${_params['z_random_range_mm']}mm',
            const Offset(10, 50), yellow);
      default:
        _drawCaption(c, 'z_mode=off  固定:${_params['z_fixed_offset_mm'] ?? 0}mm',
            const Offset(10, 50), yellow);
    }

    // ---- 角度槽回显 ----
    final rollMode = _params['roll_mode'];
    var rollLine = 'roll_mode=$rollMode';
    if (rollMode == 'measured') {
      rollLine += '  增益:${_params['roll_gain_deg_per_deg']}  '
          '容差:${_params['roll_tol_deg']}°';
    }
    _drawCaption(c, rollLine, const Offset(10, 70), yellow);

    for (final roi in _rois) {
      switch (roi.type) {
        case RoiType.rect:
          c.drawRect(roi.bounds, green);
          // 模拟检测结果：中心十字 + 边缘点
          final ctr = roi.bounds.center;
          c.drawLine(ctr.translate(-8, 0), ctr.translate(8, 0), red);
          c.drawLine(ctr.translate(0, -8), ctr.translate(0, 8), red);
          _drawCaption(c, 'W${roi.bounds.width.round()}xH${roi.bounds.height.round()}',
              roi.bounds.topLeft.translate(0, -18), yellow);
        case RoiType.line:
          // 卡尺线：主线 + 垂直刻度 + 方向箭头
          c.drawLine(roi.p1, roi.p2, green);
          final dir = (roi.p2 - roi.p1);
          final len = dir.distance;
          if (len > 1) {
            final unit = dir / len;
            final normal = ui.Offset(-unit.dy, unit.dx);
            final tick = ui.Paint()
              ..color = const ui.Color(0xFF22C55E)
              ..strokeWidth = 1;
            for (double d = 0; d <= len; d += 16) {
              final p = roi.p1 + unit * d;
              c.drawLine(p - normal * 5, p + normal * 5, tick);
            }
            // 箭头
            final tip = roi.p2;
            final back = tip - unit * 14;
            final a1 = back + normal * 6;
            final a2 = back - normal * 6;
            final arrow = ui.Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(a1.dx, a1.dy)
              ..lineTo(a2.dx, a2.dy)
              ..close();
            c.drawPath(arrow, ui.Paint()..color = const ui.Color(0xFF22C55E));
            // 模拟找到的边缘：中点垂直偏移
            final mid = roi.p1 + unit * (len / 2);
            c.drawLine(mid - normal * 10, mid + normal * 10, red);
            _drawCaption(c, 'L=${len.toStringAsFixed(1)}',
                mid.translate(10, -10), yellow);
          }
        case RoiType.ellipse:
          c.drawOval(roi.bounds, green);
          final ctr = roi.bounds.center;
          c.drawCircle(ctr, 3, ui.Paint()..color = const ui.Color(0xFFEF4444));
          _drawCaption(c, 'D=${roi.bounds.width.round()}', roi.bounds.topLeft.translate(0, -18), yellow);
      }
    }
  }

  void _drawCaption(ui.Canvas c, String text, ui.Offset at, ui.Color color) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 13))
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(text);
    final p = builder.build()..layout(const ui.ParagraphConstraints(width: 600));
    c.drawParagraph(p, at);
  }
}
