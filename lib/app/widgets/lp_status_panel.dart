import 'package:flutter/material.dart';

import '../../core/lp_status_log.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_path_layout.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_robot_colors.dart';
import 'lp_shell_edge.dart';

/// Cursor 风格可折叠底部面板：标签导航 + 连接 / 消息 / 输出。
class LpStatusPanel extends StatelessWidget {
  const LpStatusPanel({super.key});

  static const _panelBg = LpRobotColors.statusPanelBackground;
  static const _muted = LpRobotColors.label;
  static const _text = LpRobotColors.textDark;
  static const _headerHeight = 32.0;
  static const _dividerHeight = 1.0;
  static const _bodyHeight = 135.0;
  static const _expandedHeight =
      _dividerHeight + _headerHeight + _bodyHeight;
  static const _collapsedHeight = _dividerHeight + _headerHeight;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
        LpStatusLog.instance,
      ]),
      builder: (context, _) {
        final robot = RobotState.instance;
        final log = LpStatusLog.instance;
        final expanded = log.panelExpanded;

        return Material(
          color: _panelBg,
          elevation: 0,
          child: SafeArea(
            top: false,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(color: _panelBg),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: expanded ? _expandedHeight : _collapsedHeight,
                    color: _panelBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PanelHeader(
                          expanded: expanded,
                          selectedTab: log.selectedTab,
                          onSelectTab: log.selectTab,
                          onToggle: log.togglePanel,
                          onClose: log.closePanel,
                        ),
                        if (expanded)
                          Expanded(
                            child: _PanelBody(
                              tab: log.selectedTab,
                              robot: robot,
                              log: log,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LpShellEdgeFade(
                    height: 8,
                    edge: LpShellEdge.top,
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

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.expanded,
    required this.selectedTab,
    required this.onSelectTab,
    required this.onToggle,
    required this.onClose,
  });

  final bool expanded;
  final LpStatusPanelTab selectedTab;
  final ValueChanged<LpStatusPanelTab> onSelectTab;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LpRobotColors.statusPanelHeader,
            LpRobotColors.statusPanelBackground,
          ],
        ),
      ),
      child: Container(
      height: LpStatusPanel._headerHeight,
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Row(
        children: [
          if (expanded)
            ...LpStatusPanelTab.values.map(
              (tab) => _TabChip(
                label: tab.label,
                selected: tab == selectedTab,
                onTap: () => onSelectTab(tab),
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: _CollapsedSummary(),
              ),
            ),
          if (expanded) const Spacer(),
          _HeaderIconButton(
            icon: expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            tooltip: expanded ? '收起面板' : '展开面板',
            onPressed: onToggle,
          ),
          if (expanded)
            _HeaderIconButton(
              icon: Icons.close,
              tooltip: '关闭',
              onPressed: onClose,
            ),
        ],
      ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
          child: Container(
          height: LpStatusPanel._headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? LpRobotColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.0,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? LpRobotColors.primary : LpRobotColors.label,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 28,
          height: LpStatusPanel._headerHeight,
          child: Icon(icon, size: 16, color: LpRobotColors.label),
        ),
      ),
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final robot = RobotState.instance;
    final telemetry = RobotTelemetry.instance;
    final log = LpStatusLog.instance;
    final latest = log.entries.isNotEmpty ? log.entries.first.message : null;

    var text = robot.isConnected
        ? '● 已连接 ${robot.serverBaseUrl}'
        : '○ 未连接 · 离线模式';

    if (robot.isConnected) {
      final name = robot.displayRobotLabel.trim();
      if (name.isNotEmpty && name != '离线') {
        text = '$name  ·  $text';
      }
    }

    if (robot.isConnected && telemetry.pose.hasData) {
      final p = telemetry.pose;
      text =
          '$text  ·  X:${p.x.toStringAsFixed(2)} Y:${p.y.toStringAsFixed(2)} '
          'J1:${p.joints[0].toStringAsFixed(2)}';
    }
    if (robot.isConnected && telemetry.motorAlarm) {
      text = '$text  ·  ${telemetry.motorAlarmDisplay}';
    } else if (latest != null && !telemetry.pose.hasData) {
      text = '$text  ·  $latest';
    } else if (latest != null && !robot.isConnected) {
      text = '$text  ·  $latest';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: telemetry.motorAlarm && robot.isConnected
                  ? LpRobotColors.alarm
                  : LpStatusPanel._text,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.tab,
    required this.robot,
    required this.log,
  });

  final LpStatusPanelTab tab;
  final RobotState robot;
  final LpStatusLog log;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case LpStatusPanelTab.connection:
        return _ConnectionTab(robot: robot);
      case LpStatusPanelTab.messages:
        return _LogListTab(
          entries: log.entriesFor(LpStatusPanelTab.messages),
          emptyHint: '暂无消息',
          onClear: () => log.clearTab(LpStatusPanelTab.messages),
        );
      case LpStatusPanelTab.output:
        return _LogListTab(
          entries: log.entriesFor(LpStatusPanelTab.output),
          emptyHint: '暂无输出',
          onClear: () => log.clearTab(LpStatusPanelTab.output),
          staticLines: [
            '程序目录：${RobotPathLayout.serverDir}/',
            '工程库：${RobotPathLayout.xmlLibraryDir}/',
          ],
        );
    }
  }
}

class _ConnectionTab extends StatelessWidget {
  const _ConnectionTab({required this.robot});

  final RobotState robot;

  @override
  Widget build(BuildContext context) {
    final connected = robot.isConnected;
    final telemetry = RobotTelemetry.instance;
    final statusColor =
        connected ? LpRobotColors.liveValue : LpStatusPanel._muted;
    final initOk = RobotAlarmInfo.initStatusOk(telemetry.initStatus);
    final batteryLow = telemetry.batteryLowDisplay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.circle : Icons.circle_outlined,
                  size: 8,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  connected ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (connected) ...[
              _monoLine('地址', robot.serverBaseUrl),
              if (robot.firmwareVersion.isNotEmpty)
                _monoLine('固件', robot.firmwareVersion),
              if (robot.robotModel.isNotEmpty)
                _monoLine('机型', robot.robotModel),
              if (robot.robotSerialNumber.isNotEmpty)
                _monoLine('序列号', robot.robotSerialNumber),
              _monoLine('IO总数量', telemetry.ioCountBodyPlusExt),
              _monoLine('总轴数量', telemetry.axisCountBodyPlusExt),
              _statusLine(
                '运行',
                telemetry.isRobotMoving ? '运动中' : '空闲',
                valueColor: telemetry.isRobotMoving
                    ? LpRobotColors.liveValue
                    : LpStatusPanel._text,
              ),
              _statusLine(
                '电机报警',
                telemetry.motorAlarmDisplay,
                valueColor: telemetry.motorAlarm
                    ? LpRobotColors.alarm
                    : LpRobotColors.liveValue,
              ),
              _statusLine(
                '启动状态',
                RobotAlarmInfo.formatInitStatus(telemetry.initStatus),
                valueColor:
                    initOk ? LpRobotColors.liveValue : LpRobotColors.alarm,
              ),
              _statusLine(
                '伺服',
                RobotAlarmInfo.formatServoState(telemetry.servoEnabled),
                valueColor: telemetry.servoEnabled
                    ? LpRobotColors.liveValue
                    : LpRobotColors.alarm,
              ),
              if (batteryLow != null)
                _statusLine(
                  '电池',
                  batteryLow,
                  valueColor: LpRobotColors.alarm,
                ),
              if (telemetry.motorAlarm)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    RobotAlarmInfo.controlAlarmHint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LpRobotColors.alarm,
                      height: 1.35,
                    ),
                  ),
                ),
            ] else
              const Text(
                '未连接控制器，当前为离线编辑模式。',
                style: TextStyle(fontSize: 12, color: LpStatusPanel._muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(String label, String value, {required Color valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(
                fontSize: 12,
                color: LpStatusPanel._muted,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(
                fontSize: 11.5,
                color: LpStatusPanel._muted,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 11.5,
                color: LpStatusPanel._text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogListTab extends StatelessWidget {
  const _LogListTab({
    required this.entries,
    required this.emptyHint,
    required this.onClear,
    this.staticLines = const [],
  });

  final List<LpLogEntry> entries;
  final String emptyHint;
  final VoidCallback onClear;
  final List<String> staticLines;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty && staticLines.isEmpty) {
      return Center(
        child: Text(
          emptyHint,
          style: const TextStyle(fontSize: 12, color: LpStatusPanel._muted),
        ),
      );
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 36, 8),
          children: [
            for (final line in staticLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LpStatusPanel._muted,
                  ),
                ),
              ),
            for (final entry in entries) _LogLine(entry: entry),
          ],
        ),
        if (entries.isNotEmpty)
          Positioned(
            top: 2,
            right: 4,
            child: Tooltip(
              message: '清空',
              child: InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 14, color: LpStatusPanel._muted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final LpLogEntry entry;

  Color get _levelColor {
    switch (entry.level) {
      case LpLogLevel.success:
        return LpRobotColors.liveValue;
      case LpLogLevel.warning:
        return LpRobotColors.primary;
      case LpLogLevel.error:
        return LpRobotColors.alarm;
      case LpLogLevel.info:
        return LpStatusPanel._text;
    }
  }

  String get _timeLabel {
    final t = entry.time;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '[$_timeLabel] ',
              style: const TextStyle(
                fontSize: 11,
                color: LpStatusPanel._muted,
              ),
            ),
            TextSpan(
              text: entry.message,
              style: TextStyle(
                fontSize: 11.5,
                color: _levelColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
