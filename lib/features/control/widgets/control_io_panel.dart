import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_io_state.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import 'control_io_module_picker.dart';

/// 操控页 IO 模式：左侧滚轮选扩展块，右侧仅一页 IN/OUT（对齐 Android `ll_control_io`）。
class ControlIoPanel extends StatefulWidget {
  const ControlIoPanel({super.key});

  @override
  State<ControlIoPanel> createState() => _ControlIoPanelState();
}

class _ControlIoPanelState extends State<ControlIoPanel> {
  int _moduleIndex = 0;
  bool _busy = false;

  int get _moduleCount {
    return RobotTelemetry.instance.ioModuleCount.clamp(1, 32);
  }

  Future<void> _toggleOutput(int address) async {
    if (_busy || !RobotState.instance.isConnected) return;
    final next = !RobotTelemetry.instance.outputAt(address);
    setState(() => _busy = true);
    try {
      await HttpManager.instance.robotSetOutput(outNum: address, state: next);
    } catch (e) {
      if (mounted) {
        LpStatusLog.instance.warning('IO 写入失败：$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleCount = _moduleCount;
    final module = _moduleIndex.clamp(0, moduleCount - 1);

    return ClipRect(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ControlIoModulePicker(
            moduleCount: moduleCount,
            selectedIndex: module,
            onChanged: (v) {
              if (_moduleIndex != v) setState(() => _moduleIndex = v);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                RobotTelemetry.instance,
                RobotState.instance,
              ]),
              builder: (context, _) {
                final online = RobotState.instance.isConnected;
                final t = RobotTelemetry.instance;
                return Column(
                  key: ValueKey<int>(module),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _IoBank(
                        title: 'IN',
                        isOutput: false,
                        moduleIndex: module,
                        online: online,
                        telemetry: t,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _IoBank(
                        title: 'OUT',
                        isOutput: true,
                        moduleIndex: module,
                        online: online,
                        telemetry: t,
                        onOutputTap: _toggleOutput,
                        busy: _busy,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IoBank extends StatelessWidget {
  const _IoBank({
    required this.title,
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onOutputTap,
    this.busy = false,
  });

  final String title;
  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onOutputTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surfaceWarm,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LpRobotColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols = RobotIoState.controlRowWidth;
                  final rowH = (constraints.maxHeight - 4) / 2;
                  final slotW = constraints.maxWidth / cols;
                  final size = slotW.clamp(12.0, rowH).clamp(12.0, 36.0);

                  return Column(
                    children: [
                      SizedBox(
                        height: rowH,
                        child: _IoLaneRow(
                          row: 0,
                          size: size,
                          slotW: slotW,
                          isOutput: isOutput,
                          moduleIndex: moduleIndex,
                          online: online,
                          telemetry: telemetry,
                          onOutputTap: onOutputTap,
                          busy: busy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: rowH,
                        child: _IoLaneRow(
                          row: 1,
                          size: size,
                          slotW: slotW,
                          isOutput: isOutput,
                          moduleIndex: moduleIndex,
                          online: online,
                          telemetry: telemetry,
                          onOutputTap: onOutputTap,
                          busy: busy,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IoLaneRow extends StatelessWidget {
  const _IoLaneRow({
    required this.row,
    required this.size,
    required this.slotW,
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onOutputTap,
    this.busy = false,
  });

  final int row;
  final double size;
  final double slotW;
  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onOutputTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    const cols = RobotIoState.controlRowWidth;
    return Row(
      children: [
        for (var col = 0; col < cols; col++)
          SizedBox(
            width: slotW,
            child: Center(
              child: _IoCell(
                lane: row * cols + col,
                size: size,
                isOutput: isOutput,
                moduleIndex: moduleIndex,
                online: online,
                telemetry: telemetry,
                onTap: isOutput ? onOutputTap : null,
                busy: busy,
              ),
            ),
          ),
      ],
    );
  }
}

class _IoCell extends StatelessWidget {
  const _IoCell({
    required this.lane,
    required this.size,
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onTap,
    this.busy = false,
  });

  final int lane;
  final double size;
  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (!RobotIoState.isControlLaneVisible(lane, isOutput: isOutput)) {
      return SizedBox(width: size, height: size);
    }

    final address = RobotIoState.ioAddress(moduleIndex, lane);
    final active = online &&
        (isOutput ? telemetry.outputAt(address) : telemetry.inputAt(address));
    final canTap = isOutput && onTap != null && online && !busy;

    final led = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: active ? LpRobotColors.ioChecked : LpRobotColors.surface,
          border: Border.all(
            color: active ? LpRobotColors.ioChecked : LpRobotColors.ioUnchecked,
            width: active ? 1.2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$lane',
            style: TextStyle(
              fontSize: (size * 0.38).clamp(7.0, 11.0),
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : LpRobotColors.label,
            ),
          ),
        ),
      ),
    );

    if (!canTap) return led;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap!(address),
        borderRadius: BorderRadius.circular(4),
        child: led,
      ),
    );
  }
}
