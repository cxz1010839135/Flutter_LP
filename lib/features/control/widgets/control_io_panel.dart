import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_io_state.dart';
import '../../../core/robot_paths.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import '../control_assets.dart';
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
  late final Future<({File? off, File? on})> _cellFilesFuture = _loadCellFiles();

  Future<({File? off, File? on})> _loadCellFiles() async {
    final off =
        await RobotPaths.findMainNavImageFile(ControlAssets.ioCellOffName);
    final on =
        await RobotPaths.findMainNavImageFile(ControlAssets.ioCellOnName);
    return (off: off, on: on);
  }

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
    return FutureBuilder<({File? off, File? on})>(
      future: _cellFilesFuture,
      builder: (context, fileSnap) {
        final cellFiles = fileSnap.data;
        return ListenableBuilder(
          listenable: Listenable.merge([
            RobotTelemetry.instance,
            RobotState.instance,
          ]),
          builder: (context, _) {
            final moduleCount = _moduleCount;
            final module = _moduleIndex.clamp(0, moduleCount - 1);
            if (_moduleIndex != module) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_moduleIndex != module) {
                  setState(() => _moduleIndex = module);
                }
              });
            }
            final online = RobotState.instance.isConnected;
            final t = RobotTelemetry.instance;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧模块滚轮：随模块数刷新，可拖动/滚轮切换扩展页。
                SizedBox(
                  width: 56,
                  child: ControlIoModulePicker(
                    key: ValueKey('io-mod-$moduleCount'),
                    moduleCount: moduleCount,
                    selectedIndex: module,
                    onChanged: (v) {
                      if (_moduleIndex != v) {
                        setState(() => _moduleIndex = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      key: ValueKey<int>(module),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _IoBank(
                            isOutput: false,
                            moduleIndex: module,
                            online: online,
                            telemetry: t,
                            cellFiles: cellFiles,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _IoBank(
                            isOutput: true,
                            moduleIndex: module,
                            online: online,
                            telemetry: t,
                            onOutputTap: _toggleOutput,
                            busy: _busy,
                            cellFiles: cellFiles,
                          ),
                        ),
                      ],
                    ),
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

class _IoBank extends StatelessWidget {
  const _IoBank({
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onOutputTap,
    this.busy = false,
    this.cellFiles,
  });

  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onOutputTap;
  final bool busy;
  final ({File? off, File? on})? cellFiles;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.controlAxisSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Align(
                alignment: Alignment.topLeft,
                child: Image.asset(
                  isOutput
                      ? ControlAssets.ioOutputLabel
                      : ControlAssets.ioInputLabel,
                  height: 22,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols = RobotIoState.controlRowWidth;
                  const rowGap = 2.0;
                  const bankPadV = 4.0;
                  final gridH =
                      constraints.maxHeight - bankPadV * 2 - rowGap;
                  final rowH = gridH / 2;
                  final slotW = constraints.maxWidth / cols;
                  final cellW = slotW * 0.96;
                  final cellH = rowH * 0.94;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: bankPadV),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: rowH,
                          child: _IoLaneRow(
                            row: 0,
                            cellW: cellW,
                            cellH: cellH,
                            slotW: slotW,
                            isOutput: isOutput,
                            moduleIndex: moduleIndex,
                            online: online,
                            telemetry: telemetry,
                            onOutputTap: onOutputTap,
                            busy: busy,
                            cellFiles: cellFiles,
                          ),
                        ),
                        const SizedBox(height: rowGap),
                        SizedBox(
                          height: rowH,
                          child: _IoLaneRow(
                            row: 1,
                            cellW: cellW,
                            cellH: cellH,
                            slotW: slotW,
                            isOutput: isOutput,
                            moduleIndex: moduleIndex,
                            online: online,
                            telemetry: telemetry,
                            onOutputTap: onOutputTap,
                            busy: busy,
                            cellFiles: cellFiles,
                          ),
                        ),
                      ],
                    ),
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
    required this.cellW,
    required this.cellH,
    required this.slotW,
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onOutputTap,
    this.busy = false,
    this.cellFiles,
  });

  final int row;
  final double cellW;
  final double cellH;
  final double slotW;
  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onOutputTap;
  final bool busy;
  final ({File? off, File? on})? cellFiles;

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
                cellW: cellW,
                cellH: cellH,
                isOutput: isOutput,
                moduleIndex: moduleIndex,
                online: online,
                telemetry: telemetry,
                onTap: isOutput ? onOutputTap : null,
                busy: busy,
                cellFiles: cellFiles,
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
    required this.cellW,
    required this.cellH,
    required this.isOutput,
    required this.moduleIndex,
    required this.online,
    required this.telemetry,
    this.onTap,
    this.busy = false,
    this.cellFiles,
  });

  final int lane;
  final double cellW;
  final double cellH;
  final bool isOutput;
  final int moduleIndex;
  final bool online;
  final RobotTelemetry telemetry;
  final Future<void> Function(int address)? onTap;
  final bool busy;
  final ({File? off, File? on})? cellFiles;

  @override
  Widget build(BuildContext context) {
    if (!RobotIoState.isControlLaneVisible(lane, isOutput: isOutput)) {
      return SizedBox(width: cellW, height: cellH);
    }

    final address = RobotIoState.ioAddress(moduleIndex, lane);
    final active = online &&
        (isOutput ? telemetry.outputAt(address) : telemetry.inputAt(address));
    final canTap = isOutput && onTap != null && online && !busy;
    final label = lane.toString().padLeft(2, '0');
    final fontSize = (cellH * 0.28).clamp(10.0, 16.0);
    final file = active ? (cellFiles?.on ?? cellFiles?.off) : cellFiles?.off;
    final asset = ControlAssets.ioCellAsset(active: active);

    final image = file != null
        ? Image.file(file, fit: BoxFit.contain, gaplessPlayback: true)
        : Image.asset(asset, fit: BoxFit.contain, gaplessPlayback: true);

    final cell = SizedBox(
      width: cellW,
      height: cellH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Align(
            alignment: const Alignment(0, 0.22),
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: active
                    ? LpRobotColors.primary
                    : const Color(0xFFB8A090),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );

    if (!canTap) return cell;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap!(address),
        borderRadius: BorderRadius.circular(4),
        child: cell,
      ),
    );
  }
}
