import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_point_library.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import 'widgets/point_add_dialog.dart';
import 'widgets/point_library_action_rail.dart';
import 'widgets/point_library_table.dart';

/// 点库页（对齐 Android [PointLibraryActivity]）。
class PointLibraryPage extends StatefulWidget {
  const PointLibraryPage({super.key});

  @override
  State<PointLibraryPage> createState() => _PointLibraryPageState();
}

class _PointLibraryPageState extends State<PointLibraryPage> {
  int? _selectedIndex;
  bool _busy = false;

  RobotPoint? get _selectedPoint {
    final index = _selectedIndex;
    if (index == null) return null;
    return RobotPointLibrary.instance.pointByIndex(index);
  }

  int _suggestNextIndex() {
    final points = RobotPointLibrary.instance.points;
    if (points.isEmpty) return 1;
    return points.map((p) => p.index).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _applyResponse(dynamic root) async {
    if (root is Map<String, dynamic>) {
      RobotPointLibrary.instance.applyFromResponseRoot(root);
    }
  }

  Future<void> _onAdd() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final input = await PointAddDialog.show(
      context,
      suggestedIndex: _suggestNextIndex(),
    );
    if (input == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await HttpManager.instance.addPoint(
        pointIndex: input.index,
        label: input.label,
        describe: input.describe.isEmpty ? input.label : input.describe,
      );
      res.ensureOk();
      await _applyResponse(res.root);
      setState(() => _selectedIndex = input.index);
      LpStatusLog.instance.success('点位 P${input.index} 添加成功');
    } catch (e) {
      LpStatusLog.instance.error('点位添加失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onUpdate() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final point = _selectedPoint;
    if (point == null) {
      LpStatusLog.instance.warning('请先选中一个点位');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text('是否将当前位置示教到点位 P${point.index}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await HttpManager.instance.updatePointLabel(
        pointIndex: point.index,
        label: point.label,
      );
      res.ensureOk();
      await _applyResponse(res.root);
      LpStatusLog.instance.success('点位 P${point.index} 已更新');
    } catch (e) {
      LpStatusLog.instance.error('点位更新失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDelete() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final point = _selectedPoint;
    if (point == null) {
      LpStatusLog.instance.warning('请先选中一个点位');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text('是否删除点位 P${point.index}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.alarm,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await HttpManager.instance.deletePoint(
        pointIndex: point.index,
        label: point.label,
        describe: point.label,
        joints: point.joints,
      );
      res.ensureOk();
      await _applyResponse(res.root);
      setState(() => _selectedIndex = null);
      LpStatusLog.instance.success('点位 P${point.index} 已删除');
    } catch (e) {
      LpStatusLog.instance.error('点位删除失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRename(RobotPoint point) async {
    if (!RobotState.instance.isConnected) return;

    final controller = TextEditingController(text: point.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改名称 P${point.index}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newLabel == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await HttpManager.instance.updatePoint(
        pointIndex: point.index,
        label: newLabel,
        describe: newLabel,
        joints: point.joints,
        refresh: true,
      );
      res.ensureOk();
      await _applyResponse(res.root);
      LpStatusLog.instance.success('点位 P${point.index} 名称已修改');
    } catch (e) {
      LpStatusLog.instance.error('修改名称失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LpRobotColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '点位',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  RobotPointLibrary.instance,
                  RobotTelemetry.instance,
                ]),
                builder: (context, _) {
                  final axisCount =
                      RobotTelemetry.instance.pointTableAxisCount;
                  final points = RobotPointLibrary.instance.points;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: PointLibraryTable(
                          axisCount: axisCount,
                          points: points,
                          selectedIndex: _selectedIndex,
                          onSelected: (index) {
                            setState(() => _selectedIndex = index);
                          },
                          onRename: _busy ? null : _onRename,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: Stack(
                          children: [
                            PointLibraryActionRail(
                              busy: _busy,
                              onAdd: _onAdd,
                              onUpdate: _onUpdate,
                              onDelete: _onDelete,
                            ),
                            if (_busy)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Color(0x33FFFFFF),
                                  child: Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const LpStatusPanel(),
        ],
      ),
    );
  }
}
