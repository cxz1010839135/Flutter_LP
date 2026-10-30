import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_path_layout.dart';
import '../../core/robot_point_library.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import 'point_library_file_io.dart';
import 'widgets/point_add_dialog.dart';
import 'widgets/point_library_action_rail.dart';
import 'widgets/point_library_import_dialog.dart';
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
    if (points.isEmpty) return 0;
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

  Future<void> _onRenameSelected() async {
    final point = _selectedPoint;
    if (point == null) {
      LpStatusLog.instance.warning('请先选中一个点位');
      return;
    }
    await _onRename(point);
  }

  Future<void> _onRename(RobotPoint point) async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

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
    if (newLabel.isEmpty) {
      LpStatusLog.instance.warning('名称不能为空');
      return;
    }
    if (newLabel == point.label) return;

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

  // --- 点位库文件（.rpt4）保存 / 导入（驱控 /home/llmachine/） ---

  /// 保存点位库：下载驱控当前点位库文件，存入 /home/llmachine/<自定义名>.rpt4。
  Future<void> _onSaveLibrary() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final rawName = await _askSaveName();
    if (rawName == null || !mounted) return;

    final String fileName;
    try {
      fileName = PointLibraryFileIo.normalizeName(rawName);
    } on FormatException catch (e) {
      LpStatusLog.instance.warning(e.message);
      return;
    }

    if (await _confirmOverwrite(fileName) != true) return;

    setState(() => _busy = true);
    try {
      final target = await PointLibraryFileIo.saveCurrentPointLibrary(
        fileName,
        onStatus: (m) => LpStatusLog.instance.info(m, openPanel: false),
      );
      LpStatusLog.instance.success('点位库已保存：$target');
    } catch (e) {
      LpStatusLog.instance.error('保存点位库失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 导入点位库：从内存卡（驱控目录）或本地目录选 .rpt4，
  /// 覆盖驱控当前点位库（para/rbt_Point.rpt4）并刷新点位列表。
  Future<void> _onImportLibrary() async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }

    final source = await PointLibraryImportDialog.show(context);
    if (source == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(
          '将用 ${source.fileName} 覆盖驱控当前点位库：\n'
          '${RobotPathLayout.robotPointLibFile}\n\n'
          '导入后点位列表将刷新，确定导入吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.alarm,
            ),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await PointLibraryFileIo.importAsCurrentPointLibrary(
        remoteEntry: source is PointImportRemote ? source.entry : null,
        localFile: source is PointImportLocal ? source.file : null,
        onStatus: (m) => LpStatusLog.instance.info(m, openPanel: false),
      );
      if (!mounted) return;
      setState(() => _selectedIndex = null);

      // 表格刷新已在服务内完成（固件返回数据优先，否则本地解析文件内容）。
      final count = RobotPointLibrary.instance.points.length;
      if (result.refreshed) {
        LpStatusLog.instance.success(
          '点位库已导入并刷新（共 $count 个点位）：${result.target}',
        );
      } else {
        final failed = <String>[
          for (final i in result.upsertFailures) 'P$i',
          for (final i in result.deleteFailures) '删P$i',
        ];
        LpStatusLog.instance.warning(
          '点位库文件已写入，表格已刷新（共 $count 个点位）。\n'
          '以下点位写入/删除驱控失败：${failed.join('、')}'
          '${result.errorDetail == null ? '' : '\n${result.errorDetail}'}',
        );
      }
    } catch (e) {
      LpStatusLog.instance.error('导入点位库失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 保存目录已有同名文件时确认覆盖；无法确认时不拦截，由上传后校验兜底。
  Future<bool?> _confirmOverwrite(String fileName) async {
    bool exists;
    try {
      exists = await PointLibraryFileIo.hasSavedPointFile(fileName);
    } catch (_) {
      return true;
    }
    if (!exists) return true;
    if (!mounted) return null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(
          '驱控 ${RobotPathLayout.robotPointFileTagPath} 已有同名文件：'
          '\n$fileName\n\n是否覆盖？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
            ),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
    return ok;
  }

  /// 输入保存名称；默认名 point_日期_时间，后缀 .rpt4 自动补齐。
  Future<String?> _askSaveName() async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final defaultName =
        'point_${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';

    final controller = TextEditingController(text: defaultName);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存点位库'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '文件名称',
                hintText: '默认后缀 .rpt4，可自定义',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '保存位置：驱控 ${RobotPathLayout.robotPointFileTagPath}',
              style: const TextStyle(fontSize: 12, color: LpRobotColors.label),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: LpRobotColors.primary,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
                        width: 88,
                        child: Stack(
                          children: [
                            PointLibraryActionRail(
                              busy: _busy,
                              onAdd: _onAdd,
                              onRename: _onRenameSelected,
                              onRefresh: _onUpdate,
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
          _buildPointFileBar(),
          const LpStatusPanel(),
        ],
      ),
    );
  }

  /// 底栏：保存点位库 / 导入点位库（.rpt4 存入驱控 /home/llmachine/）。
  Widget _buildPointFileBar() {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: LpRobotColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 44),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
    return Material(
      color: LpRobotColors.surfaceWarm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 保存/导入耗时操作时的可见进度，避免误以为卡住。
          if (_busy)
            const LinearProgressIndicator(
              color: LpRobotColors.primary,
              backgroundColor: Color(0x22FF7E1A),
              minHeight: 3,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _onSaveLibrary,
                    style: buttonStyle,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('保存点位库'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _onImportLibrary,
                    style: buttonStyle,
                    icon: const Icon(Icons.input_outlined, size: 18),
                    label: const Text('导入点位库'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
