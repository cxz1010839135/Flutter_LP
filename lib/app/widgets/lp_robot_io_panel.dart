import 'package:flutter/material.dart';

import '../../core/robot_io_state.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_robot_colors.dart';

/// IO 指示灯（16 路 IN/OUT，宽高自适应，避免横向溢出）。
class LpRobotIoPanel extends StatelessWidget {
  const LpRobotIoPanel({super.key});

  static const double _labelColWidth = 24;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final online = RobotState.instance.isConnected;
        final t = RobotTelemetry.instance;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final gridW = (w - _labelColWidth - 6) / 2;
            final cellW = (gridW - 6) / 4;
            final cellH = (h - 14) / 4;
            final cellSize = cellW < cellH ? cellW : cellH;
            final led = cellSize.clamp(6.0, 16.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _IoBlock(
                    title: 'IN',
                    flags: t.inputStatus,
                    online: online,
                    ledSize: led,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _IoBlock(
                    title: 'OUT',
                    flags: t.outputStatus,
                    online: online,
                    ledSize: led,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _IoBlock extends StatelessWidget {
  const _IoBlock({
    required this.title,
    required this.flags,
    required this.online,
    required this.ledSize,
  });

  final String title;
  final List<bool> flags;
  final bool online;
  final double ledSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 12,
          child: Row(
            children: [
              SizedBox(
                width: LpRobotIoPanel._labelColWidth,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: LpRobotColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var g = 0; g < 4; g++)
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${RobotIoState.columnGroupLabels[g]}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: LpRobotColors.label,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: LpRobotIoPanel._labelColWidth),
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0; row < 4; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < 4; col++)
                              Expanded(
                                child: Center(
                                  child: _Led(
                                    size: ledSize,
                                    on: online && _at(flags, row, col),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _at(List<bool> flags, int row, int col) {
    final i = row * 4 + col;
    return i >= 0 && i < flags.length && flags[i];
  }
}

class _Led extends StatelessWidget {
  const _Led({required this.size, required this.on});

  final double size;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: on ? LpRobotColors.ioChecked : LpRobotColors.surface,
          border: Border.all(
            color: on ? LpRobotColors.ioChecked : LpRobotColors.ioUnchecked,
            width: on ? 1.2 : 1.5,
          ),
        ),
      ),
    );
  }
}
