import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';

/// 波形观测（对齐 GraphicFragment，简易折线展示）。
class DriverWaveformPanel extends StatelessWidget {
  const DriverWaveformPanel({
    super.key,
    required this.series,
    this.loading = false,
  });

  final Map<String, List<double>> series;
  final bool loading;

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: LpRobotColors.primary));
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
                border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.4)),
              ),
              child: CustomPaint(
                painter: _WaveformPainter(
                  series: [
                    for (var i = 0; i < keys.length; i++)
                      _WaveSeries(
                        series[keys[i]] ?? const [],
                        _colors[i % _colors.length],
                      ),
                  ],
                ),
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
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    var maxLen = 1;
    for (final s in series) {
      if (s.data.isEmpty) continue;
      maxLen = maxLen > s.data.length ? maxLen : s.data.length;
      for (final v in s.data) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }
    if (!minY.isFinite || minY == maxY) {
      minY = -1;
      maxY = 1;
    }
    final range = maxY - minY;

    for (final s in series) {
      if (s.data.length < 2) continue;
      final path = Path();
      for (var i = 0; i < s.data.length; i++) {
        final x = size.width * i / (maxLen - 1);
        final norm = (s.data[i] - minY) / range;
        final y = size.height * (1 - norm.clamp(0.0, 1.0));
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
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.series != series;
}
