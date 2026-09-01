import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 波形观测（对齐 Android [MyGraphicView] / DriverActivity 采样缩放）。
///
/// 安卓在绘制前按上限归一化：
/// - 电流：`iq / (1638.4 * 电流上限)`
/// - 速度：`sp / (5.4613 * 速度上限)`
/// - 偏差：`pos_err / 偏差上限`
/// 归一化后 ±1 对应画布上下沿，0 在中线。
///
/// 若实际幅值超过上限，自动放大量程，避免曲线被裁切「显示不全」。
class DriverWaveformPanel extends StatelessWidget {
  const DriverWaveformPanel({
    super.key,
    required this.series,
    this.loading = false,
    this.currentMaxLimit = '5',
    this.speedMaxLimit = '3000',
    this.posErrMaxLimit = '10000',
  });

  final Map<String, List<double>> series;
  final bool loading;
  final String currentMaxLimit;
  final String speedMaxLimit;
  final String posErrMaxLimit;

  static const _labels = {
    'iq_ref': '电流指令',
    'iq_fbd': '电流反馈',
    'sp_ref': '速度指令',
    'sp_fbd': '速度反馈',
    'pos_err': '位置偏差',
  };

  static const _colors = [
    Color(0xFFFF7E1A),
    Color(0xFF00AF29),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
  ];

  /// 与 Android DriverActivity 采样缩放一致。
  static const _currentScaleFactor = 1638.4;
  static const _speedScaleFactor = 5.4613;

  double _parseLimit(String raw, double fallback) {
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0 || !v.isFinite) return fallback;
    return v;
  }

  double _maxAbs(List<double> data) {
    var m = 0.0;
    for (final v in data) {
      final a = v.abs();
      if (a > m) m = a;
    }
    return m;
  }

  /// 返回已归一化到约 ±1 的序列（超限时自动扩程）。
  List<_WaveSeries> _normalizedSeries() {
    final iqRef = series['iq_ref'] ?? const <double>[];
    final iqFbd = series['iq_fbd'] ?? const <double>[];
    final spRef = series['sp_ref'] ?? const <double>[];
    final spFbd = series['sp_fbd'] ?? const <double>[];
    final posErr = series['pos_err'] ?? const <double>[];

    final currentLimit = _parseLimit(currentMaxLimit, 5);
    final speedLimit = _parseLimit(speedMaxLimit, 3000);
    final posLimit = _parseLimit(posErrMaxLimit, 10000);

    var currentDiv = _currentScaleFactor * currentLimit;
    var speedDiv = _speedScaleFactor * speedLimit;
    var posDiv = posLimit;

    // 数据幅值超过上限时扩程，保证整条曲线落在可视区。
    currentDiv = math.max(
      currentDiv,
      math.max(_maxAbs(iqRef), _maxAbs(iqFbd)),
    );
    speedDiv = math.max(
      speedDiv,
      math.max(_maxAbs(spRef), _maxAbs(spFbd)),
    );
    posDiv = math.max(posDiv, _maxAbs(posErr));

    if (currentDiv < 1e-9) currentDiv = 1;
    if (speedDiv < 1e-9) speedDiv = 1;
    if (posDiv < 1e-9) posDiv = 1;

    List<double> scale(List<double> src, double div) =>
        [for (final v in src) v / div];

    final keys = _labels.keys.toList();
    final raw = <String, List<double>>{
      'iq_ref': scale(iqRef, currentDiv),
      'iq_fbd': scale(iqFbd, currentDiv),
      'sp_ref': scale(spRef, speedDiv),
      'sp_fbd': scale(spFbd, speedDiv),
      'pos_err': scale(posErr, posDiv),
    };

    return [
      for (var i = 0; i < keys.length; i++)
        _WaveSeries(raw[keys[i]] ?? const [], _colors[i % _colors.length]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: LpRobotColors.primary),
      );
    }
    final keys = _labels.keys.toList();
    final hasData = keys.any((k) => (series[k] ?? const []).isNotEmpty);
    if (!hasData) {
      return const Center(
        child: Text(
          '勾选「刷新」并执行点动/采集后在此查看波形',
          style: TextStyle(color: LpRobotColors.label, fontSize: 13),
        ),
      );
    }
    final painted = _normalizedSeries();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < keys.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _colors[i % _colors.length],
                    ),
                    const SizedBox(width: 4),
                    Text(_labels[keys[i]]!, style: const TextStyle(fontSize: 11)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LpRobotColors.surface,
                border: Border.all(
                  color: LpRobotColors.borderWarm.withValues(alpha: 0.4),
                ),
              ),
              child: CustomPaint(
                painter: _WaveformPainter(series: painted),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveSeries {
  _WaveSeries(this.data, this.color);
  final List<double> data;
  final Color color;
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.series});

  final List<_WaveSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    // 中线 + 上下四分线（对齐 Android MyGraphicView）
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), grid);
    canvas.drawLine(Offset(0, midY / 2), Offset(size.width, midY / 2), grid);
    canvas.drawLine(
      Offset(0, midY + midY / 2),
      Offset(size.width, midY + midY / 2),
      grid,
    );
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    var maxLen = 1;
    for (final s in series) {
      if (s.data.length > maxLen) maxLen = s.data.length;
    }
    if (maxLen < 2) return;

    for (final s in series) {
      if (s.data.length < 2) continue;
      final path = Path();
      for (var i = 0; i < s.data.length; i++) {
        final x = size.width * i / (maxLen - 1);
        // 安卓：y = data * y0 + y0；正值向下。轻微夹紧避免笔误飞出太多。
        final y = (s.data[i].clamp(-1.05, 1.05) * midY) + midY;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.series != series;
}
