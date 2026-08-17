import 'package:flutter/material.dart';

import '../../app/lp_app_assets.dart';
import '../../app/lp_app_fonts.dart';
import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/maintenance_edit_gate.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import '../driver/driver_page.dart';
import '../driver/driver_tech_mode_gate.dart';
import '../driver/driver_ui_style.dart';
import '../files/files_page.dart';

/// 配置页（对齐 Android [ToolActivity]：自动运行 / 调试开关 / 文件与驱动入口）。
///
/// 布局对齐图3：顶部标题栏不变；主区 main-daima-boxbg + 右侧竖排六键。
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
    final gate = DriverTechModeGate.instance;
    if (!gate.canEnterDriverPage) {
      if (gate.transitionBusy || DriverTechModeGate.isControllerInitializing) {
        await _showResultDialog('调试模式切换中，请等待控制器就绪后再进入驱动器参数页。');
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await gate.enter();
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

  bool get _canOpenDriver {
    return _online &&
        !_busy &&
        MaintenanceEditGate.canEdit() &&
        _inDebugMode &&
        DriverTechModeGate.instance.canEnterDriverPage;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotTelemetry.instance,
        DriverTechModeGate.instance,
      ]),
      builder: (context, _) {
        final stopped = MaintenanceEditGate.canEdit();
        final actionsEnabled = _online && !_busy && stopped;
        final gateBusy = DriverTechModeGate.instance.transitionBusy ||
            DriverTechModeGate.isControllerInitializing;

        return Scaffold(
          backgroundColor: DriverUiStyle.pageBackground,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LpRobotPoseBar(
                pageTitle: '配置',
                titleBarOnly: true,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(LpAppAssets.configDaimaBoxBg),
                        fit: BoxFit.fill,
                      ),
                    ),
                    // 只用 boxbg 自带底图，不再叠一层 Logo。
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 36, 20),
                            child: SizedBox(
                              width: 280,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: '设置机代码自动运行',
                                      primary: true,
                                      enabled: actionsEnabled,
                                      onPressed: () => _setAutoRun(true),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: '取消机代码自动运行',
                                      primary: false,
                                      enabled: actionsEnabled,
                                      onPressed: () => _setAutoRun(false),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: '打开调试模式',
                                      primary: true,
                                      enabled: actionsEnabled,
                                      onPressed: () => _setDebugMode(true),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: '关闭调试模式',
                                      primary: false,
                                      enabled: actionsEnabled,
                                      onPressed: () => _setDebugMode(false),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: '文件管理',
                                      primary: true,
                                      enabled: !_busy,
                                      onPressed: _openFiles,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _DaimaActionButton(
                                      label: gateBusy
                                          ? '驱动器参数设置…'
                                          : '驱动器参数设置',
                                      primary: false,
                                      enabled: _canOpenDriver,
                                      onPressed: _openDriverDebug,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_busy)
                          const Positioned(
                            left: 24,
                            right: 24,
                            bottom: 16,
                            child: LinearProgressIndicator(
                              color: LpRobotColors.primary,
                              backgroundColor: Color(0x22FF7E1A),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const LpStatusPanel(),
            ],
          ),
        );
      },
    );
  }
}

/// 配置页右侧按钮：主色 btn1bg / 次色 btn21bg。
class _DaimaActionButton extends StatelessWidget {
  const _DaimaActionButton({
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
    final asset = primary
        ? LpAppAssets.configDaimaBtnPrimary
        : LpAppAssets.configDaimaBtnSecondary;
    final textColor = !enabled
        ? Colors.grey
        : (primary ? Colors.white : LpRobotColors.textDark);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(asset),
                fit: BoxFit.fill,
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: LpAppFonts.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
