import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import '../driver/driver_page.dart';
import '../files/files_page.dart';

/// 维护页（对齐 Android [ToolActivity]：自动运行 / 调试开关 / 文件与驱动入口）。
class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
  }

  bool get _online => RobotState.instance.isConnected;

  Future<void> _runAction({
    required String successLog,
    required String failLog,
    required Future<void> Function() action,
  }) async {
    if (_busy) return;
    if (!_online) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      LpStatusLog.instance.success(successLog, openPanel: false);
      if (!mounted) return;
      await _showResultDialog(successLog);
    } catch (e) {
      final detail = failLog.endsWith('：') || failLog.endsWith(':')
          ? '$failLog$e'
          : '$failLog：$e';
      LpStatusLog.instance.warning(detail);
      if (!mounted) return;
      await _showResultDialog(detail);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResultDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAutoRun(bool enable) {
    return _runAction(
      successLog: enable ? '设置机代码自动运行成功！' : '取消机代码自动运行成功！',
      failLog: enable ? '设置机代码自动运行失败！' : '取消机代码自动运行失败！',
      action: () async {
        final res = await HttpManager.instance.setAutoRun(enable);
        res.ensureOk();
      },
    );
  }

  Future<void> _setDebugMode(bool enable) {
    return _runAction(
      successLog: enable ? '打开调试模式成功！' : '关闭调试模式成功！',
      failLog: enable ? '打开调试模式失败！' : '关闭调试模式失败！',
      action: () async {
        final res = await HttpManager.instance.setDebugMode(enable);
        res.ensureOk();
      },
    );
  }

  void _openFiles() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const FilesPage()),
    );
  }

  bool get _inDebugMode =>
      RobotTelemetry.instance.motorAlarmCode == RobotAlarmInfo.codeDebugMode;

  Future<void> _openDriverDebug() async {
    if (_busy) return;
    if (!_online) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (!_inDebugMode) {
      LpStatusLog.instance.warning('请先在上方打开调试模式');
      await _showResultDialog('请先点击「打开调试模式」，待控制器进入调试状态后再进入驱动器参数页。');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await HttpManager.instance.robotTechModeOnOff(modeState: 1);
      res.ensureOk();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const DriverPage()),
      );
    } catch (e) {
      LpStatusLog.instance.warning('进入驱动器调试失败：$e');
      if (mounted) {
        await _showResultDialog('进入驱动器调试失败：$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionsEnabled = _online && !_busy;

    return Scaffold(
      backgroundColor: LpRobotColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '维护',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  _ToolButtonRow(
                    left: _ToolActionButton(
                      label: '设置机代码自动运行',
                      primary: true,
                      enabled: actionsEnabled,
                      onPressed: () => _setAutoRun(true),
                    ),
                    right: _ToolActionButton(
                      label: '取消机代码自动运行',
                      primary: false,
                      enabled: actionsEnabled,
                      onPressed: () => _setAutoRun(false),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ToolButtonRow(
                    left: _ToolActionButton(
                      label: '打开调试模式',
                      primary: true,
                      enabled: actionsEnabled,
                      onPressed: () => _setDebugMode(true),
                    ),
                    right: _ToolActionButton(
                      label: '关闭调试模式',
                      primary: false,
                      enabled: actionsEnabled,
                      onPressed: () => _setDebugMode(false),
                    ),
                  ),
                  const Spacer(),
                  _ToolButtonRow(
                    left: _ToolEntryButton(
                      label: '文件管理 >',
                      enabled: !_busy,
                      onPressed: _openFiles,
                    ),
                    right: ListenableBuilder(
                      listenable: RobotTelemetry.instance,
                      builder: (context, _) {
                        return _ToolEntryButton(
                          label: '驱动器参数',
                          enabled: actionsEnabled && _inDebugMode,
                          onPressed: _openDriverDebug,
                        );
                      },
                    ),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(
                        color: LpRobotColors.primary,
                        backgroundColor: Color(0x22FF7E1A),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const LpStatusPanel(),
        ],
      ),
    );
  }
}

class _ToolButtonRow extends StatelessWidget {
  const _ToolButtonRow({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _ToolActionButton extends StatelessWidget {
  const _ToolActionButton({
    required this.label,
    required this.primary,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: enabled
          ? (primary ? LpRobotColors.primary : LpRobotColors.textDark)
          : Colors.grey,
    );

    return Material(
      color: LpRobotColors.surface,
      elevation: enabled ? 2 : 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? LpRobotColors.primary
                      .withValues(alpha: primary ? 0.45 : 0.25)
                  : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Center(
            child: Text(label, textAlign: TextAlign.center, style: style),
          ),
        ),
      ),
    );
  }
}

/// 底部功能入口（文件管理 / 驱动调试），样式略浅以区分上方指令按钮。
class _ToolEntryButton extends StatelessWidget {
  const _ToolEntryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LpRobotColors.surface,
      elevation: enabled ? 1 : 0,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? LpRobotColors.borderWarm.withValues(alpha: 0.65)
                  : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: enabled ? LpRobotColors.label : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
