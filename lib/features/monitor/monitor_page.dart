import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../../network/http_manager.dart';
import 'rp4_program_loader.dart';
import 'monitor_d9000_status.dart';
import 'monitor_watch_status.dart';
import 'widgets/monitor_register_sidebar.dart';

/// 监控页 MVP：RP4 主程序 + 运行行高亮（对齐 Android MonitorActivity）。
class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  static const _lineHeight = 28.0;

  List<String> _lines = const [];
  bool _loading = true;
  String? _error;
  double _fontSize = 14;
  int _lastScrollTarget = -1;
  List<int> _lastHighlightLines = const [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
    _loadProgram();
    RobotTelemetry.instance.addListener(_onTelemetryChanged);
  }

  @override
  void dispose() {
    RobotTelemetry.instance.removeListener(_onTelemetryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTelemetryChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCurrentLine();
    });
  }

  Future<void> _syncProgramLines() async {
    try {
      final lines = await Rp4ProgramLoader.loadMainProgram();
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _lastScrollTarget = -1;
        _lastHighlightLines = const [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrentLine();
      });
    } catch (_) {
      // 同步失败不影响运行追踪
    }
  }

  Future<void> _loadProgram() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lines = await Rp4ProgramLoader.loadMainProgram();
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _loading = false;
        _lastScrollTarget = -1;
        _lastHighlightLines = const [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrentLine();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToCurrentLine() {
    if (!_scrollController.hasClients || _lines.isEmpty) return;

    final telemetry = RobotTelemetry.instance;
    final highlights = telemetry.codeLineIndices;
    final target = telemetry.primaryCodeLineIndex;
    if (target == null || target >= _lines.length) return;

    final highlightChanged = !listEquals(highlights, _lastHighlightLines);
    if (!highlightChanged && target == _lastScrollTarget) return;

    _lastHighlightLines = List<int>.from(highlights);
    _lastScrollTarget = target;

    final viewport = _scrollController.position.viewportDimension;
    final centeredOffset =
        target * _lineHeight - (viewport - _lineHeight) / 2;
    final offset = centeredOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if ((_scrollController.offset - offset).abs() < _lineHeight / 2) {
      return;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _startAutoRun() async {
    final t = RobotTelemetry.instance;
    if (t.isRobotMoving) {
      _showTip('机器人运动中，无法启动自动运行');
      return;
    }
    if (t.motorAlarm) {
      _showTip(RobotAlarmInfo.controlAlarmHint);
      return;
    }
    try {
      await HttpManager.instance.robotAutoRunStart(
        speedPercent: t.speedPercent,
      );
      LpStatusLog.instance.info('已发送自动运行指令', openPanel: false);
      unawaited(_syncProgramLines());
    } catch (e) {
      _showTip('自动运行失败：$e');
    }
  }

  Future<void> _stopAutoRun() async {
    try {
      await HttpManager.instance.robotAutoRunStop();
      LpStatusLog.instance.info('已发送停止指令', openPanel: false);
    } catch (e) {
      _showTip('停止失败：$e');
    }
  }

  void _showTip(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LpRobotColors.pageBackground,
      body: Column(
        children: [
          LpRobotPoseBar(
            pageTitle: '程序监控',
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(
              tooltip: '刷新程序',
              onPressed: _loading ? null : _loadProgram,
              icon: const Icon(Icons.refresh, size: 20),
              color: LpRobotColors.textDark,
              visualDensity: VisualDensity.compact,
            ),
          ),
          _Toolbar(
            onStart: _startAutoRun,
            onStop: _stopAutoRun,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 66,
                          child: _ProgramPanel(
                            loading: _loading,
                            error: _error,
                            lines: _lines,
                            fontSize: _fontSize,
                            scrollController: _scrollController,
                            lineHeight: _lineHeight,
                            onFontIncrease: () =>
                                setState(() => _fontSize += 1),
                            onFontDecrease: () => setState(
                              () => _fontSize = (_fontSize - 1).clamp(10, 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          flex: 38,
                          child: MonitorRegisterSidebar(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _PrintPanel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onStart,
    required this.onStop,
  });

  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotTelemetry.instance,
      builder: (context, _) {
        final t = RobotTelemetry.instance;
        final moving = t.isRobotMoving;
        return Material(
          color: LpRobotColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: moving ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('自动运行'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      Text(
                        '${t.speedPercentValue}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LpRobotColors.primary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: t.speedPercentValue.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${t.speedPercentValue}%',
                          onChanged: (v) {
                            t.setSpeedPercentValue(v.round());
                          },
                          onChangeEnd: (v) {
                            final fraction = v.round() / 100.0;
                            unawaited(
                              HttpManager.instance.setSpeedPercent(
                                fraction,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (moving)
                  const Text(
                    '运行中',
                    style: TextStyle(
                      color: LpRobotColors.liveValue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  t.motorAlarmDisplay,
                  style: TextStyle(
                    color: t.motorAlarm
                        ? LpRobotColors.alarm
                        : LpRobotColors.liveValue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgramPanel extends StatelessWidget {
  const _ProgramPanel({
    required this.loading,
    required this.error,
    required this.lines,
    required this.fontSize,
    required this.scrollController,
    required this.lineHeight,
    required this.onFontIncrease,
    required this.onFontDecrease,
  });

  final bool loading;
  final String? error;
  final List<String> lines;
  final double fontSize;
  final ScrollController scrollController;
  final double lineHeight;
  final VoidCallback onFontIncrease;
  final VoidCallback onFontDecrease;

  static const _codeBackground = Color(0xFFFFEBD6);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: LpRobotColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '主程序 (main.rp4)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LpRobotColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '增大字号',
                    onPressed: onFontIncrease,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: LpRobotColors.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: '减小字号',
                    onPressed: onFontDecrease,
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: LpRobotColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: _codeBackground,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: LpRobotColors.alarm)));
    }
    if (lines.isEmpty) {
      return const Center(child: Text('暂无 RP4 程序，请先在 Blockly 中保存'));
    }

    return ListenableBuilder(
      listenable: RobotTelemetry.instance,
      builder: (context, _) {
        final highlights = RobotTelemetry.instance.codeLineIndices.toSet();
        return ListView.builder(
          key: const PageStorageKey<String>('monitor_rp4_list'),
          controller: scrollController,
          itemExtent: lineHeight,
          itemCount: lines.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final active = highlights.contains(index);
            return ColoredBox(
              color: active
                  ? LpRobotColors.primary.withValues(alpha: 0.22)
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: active
                              ? LpRobotColors.primary
                              : LpRobotColors.label,
                          fontFamily: 'Consolas',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lines[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: 'Consolas',
                          color: active
                              ? LpRobotColors.textDark
                              : LpRobotColors.label,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PrintPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: LpRobotColors.primary.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '状态窗口',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                RobotTelemetry.instance,
                MonitorWatchStatus.instance,
              ]),
              builder: (context, _) {
                final printLines = RobotTelemetry.instance.printInfo;
                final d9000Line =
                    MonitorWatchStatus.instance.d9000StatusLine;
                final lines = <String>[
                  ?d9000Line,
                  ...printLines,
                ];

                if (lines.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无打印信息',
                      style: TextStyle(color: LpRobotColors.label),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final isD9000 =
                        d9000Line != null && index == 0 && line == d9000Line;
                    final value = MonitorWatchStatus.instance.d9000Value;
                    final color = isD9000 && value != null
                        ? (MonitorD9000Status.isFailure(value)
                            ? LpRobotColors.alarm
                            : MonitorD9000Status.isBusy(value)
                                ? LpRobotColors.primary
                                : LpRobotColors.liveValue)
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Consolas',
                          color: color,
                        ),
                      ),
                    );
                  },
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
