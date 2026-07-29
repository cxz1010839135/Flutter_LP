import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../files/robot_file_transfer.dart';
import '../driver_canshu_assets.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';
import 'driver_adaptive_value_field.dart';
import 'driver_param_widgets.dart';

typedef DriverAction = Future<void> Function();
typedef DriverDirLoader = Future<List<RemoteFileEntry>> Function(String dirKey);
typedef DriverFileAction = Future<void> Function(String filePath);

enum DriverBottomView { motionParams, singleAxisParams }

/// 第二区三列参数（电机 / 增益 / 安全）。
///
/// 左右顶格、三列等宽，列间距平分。
class DriverParamsMidColumns extends StatelessWidget {
  const DriverParamsMidColumns({
    super.key,
    required this.model,
    required this.motorTab,
    required this.gainTab,
    required this.safeTab,
    required this.busy,
    required this.onMotorTabChanged,
    required this.onGainTabChanged,
    required this.onSafeTabChanged,
    required this.onFieldChanged,
  });

  final DriverParamsModel model;
  final int motorTab;
  final int gainTab;
  final int safeTab;
  final bool busy;
  final ValueChanged<int> onMotorTabChanged;
  final ValueChanged<int> onGainTabChanged;
  final ValueChanged<int> onSafeTabChanged;
  final void Function(String key, String value) onFieldChanged;

  static const _colGap = 10.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DriverParamColumn(
              title: '电机参数设置',
              tabLabels: const ['1', '2', '3'],
              tabIndex: motorTab,
              onTabChanged: onMotorTabChanged,
              fieldGroups: const [
                DriverParamsDefs.motorTab1,
                DriverParamsDefs.motorTab2,
                DriverParamsDefs.motorTab3,
              ],
              model: model,
              onFieldChanged: onFieldChanged,
              sectionKey: 'motor',
              busy: busy,
            ),
          ),
          const SizedBox(width: _colGap),
          Expanded(
            child: DriverGainColumn(
              tabIndex: gainTab,
              onTabChanged: onGainTabChanged,
              model: model,
              onFieldChanged: onFieldChanged,
              busy: busy,
            ),
          ),
          const SizedBox(width: _colGap),
          Expanded(
            child: DriverParamColumn(
              title: '安全设置',
              tabLabels: const ['1', '2', '3'],
              tabIndex: safeTab,
              onTabChanged: onSafeTabChanged,
              fieldGroups: const [
                DriverParamsDefs.safeTab1,
                DriverParamsDefs.safeTab2,
                DriverParamsDefs.safeTab3,
              ],
              model: model,
              onFieldChanged: onFieldChanged,
              sectionKey: 'safe',
              busy: busy,
            ),
          ),
        ],
      ),
    );
  }
}

/// 驱动器参数主体（对齐 DriverParamsFragment）。
class DriverParamsPanel extends StatefulWidget {
  const DriverParamsPanel({
    super.key,
    required this.model,
    required this.curAxis,
    required this.axisCount,
    required this.axisRows,
    required this.motorTab,
    required this.gainTab,
    required this.safeTab,
    required this.controlMode,
    required this.jogSpeed,
    required this.sampleCount,
    required this.delayMs,
    required this.jerk,
    required this.refreshChart,
    required this.roundTrip,
    required this.loopMove,
    required this.busy,
    required this.onAxisChanged,
    required this.onMotorTabChanged,
    required this.onGainTabChanged,
    required this.onSafeTabChanged,
    required this.onFieldChanged,
    required this.onControlModeChanged,
    required this.onJogSpeedChanged,
    required this.onSampleCountChanged,
    required this.onDelayChanged,
    required this.onJerkChanged,
    required this.onRefreshChartChanged,
    required this.onRoundTripChanged,
    required this.onLoopChanged,
    required this.onAxisMotionFieldChanged,
    required this.onAxisServoChanged,
    required this.onAxisMotionChanged,
    required this.onReadDriver,
    required this.onWriteDriver,
    required this.onWriteFile,
    required this.onPosRef,
    required this.onSample,
    required this.onSoftReset,
    required this.findPhaseButtonLabel,
    required this.findPhaseActive,
    required this.onFindPhase,
    required this.onListSingleAxisDir,
    required this.onLoadSingleAxisFile,
    required this.onSaveSingleAxisFile,
  });

  final DriverParamsModel model;
  final int curAxis;
  final int axisCount;
  final List<AxisDebugRow> axisRows;
  final int motorTab;
  final int gainTab;
  final int safeTab;
  final String controlMode;
  final String jogSpeed;
  final String sampleCount;
  final String delayMs;
  final String jerk;
  final bool refreshChart;
  final bool roundTrip;
  final bool loopMove;
  final bool busy;
  final ValueChanged<int> onAxisChanged;
  final ValueChanged<int> onMotorTabChanged;
  final ValueChanged<int> onGainTabChanged;
  final ValueChanged<int> onSafeTabChanged;
  final void Function(String key, String value) onFieldChanged;
  final ValueChanged<String> onControlModeChanged;
  final ValueChanged<String> onJogSpeedChanged;
  final ValueChanged<String> onSampleCountChanged;
  final ValueChanged<String> onDelayChanged;
  final ValueChanged<String> onJerkChanged;
  final ValueChanged<bool> onRefreshChartChanged;
  final ValueChanged<bool> onRoundTripChanged;
  final ValueChanged<bool> onLoopChanged;
  final void Function(int index, AxisDebugRow row) onAxisMotionFieldChanged;
  final Future<void> Function(int index, bool on) onAxisServoChanged;
  final Future<void> Function(int index, bool on) onAxisMotionChanged;
  final DriverAction onReadDriver;
  final DriverAction onWriteDriver;
  final DriverAction onWriteFile;
  final DriverAction onPosRef;
  final DriverAction onSample;
  final DriverAction onSoftReset;
  final String findPhaseButtonLabel;
  final bool findPhaseActive;
  final DriverAction onFindPhase;
  final DriverDirLoader onListSingleAxisDir;
  final DriverFileAction onLoadSingleAxisFile;
  final DriverFileAction onSaveSingleAxisFile;

  @override
  State<DriverParamsPanel> createState() => _DriverParamsPanelState();
}

class _DriverParamsPanelState extends State<DriverParamsPanel> {
  static const String _singleAxisRoot = '/home/llmachine/pid_ini_file';

  DriverBottomView _bottomView = DriverBottomView.motionParams;
  String _remoteDirKey = _singleAxisRoot;
  bool _remoteLoading = false;
  List<RemoteFileEntry> _remoteEntries = const [];
  late final TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _fileNameController.addListener(_onSingleAxisFilenameChanged);
  }

  @override
  void dispose() {
    _fileNameController.removeListener(_onSingleAxisFilenameChanged);
    _fileNameController.dispose();
    super.dispose();
  }

  void _onSingleAxisFilenameChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _switchBottomView(DriverBottomView view) async {
    if (_bottomView == view) return;
    setState(() => _bottomView = view);
    if (view == DriverBottomView.singleAxisParams) {
      _fileNameController.clear();
      await _loadRemoteDir(_singleAxisRoot);
    }
  }

  Future<void> _loadRemoteDir(String dirKey) async {
    setState(() => _remoteLoading = true);
    try {
      final items = await widget.onListSingleAxisDir(dirKey);
      if (!mounted) return;
      setState(() {
        _remoteDirKey = dirKey;
        _remoteEntries = items;
      });
    } finally {
      if (mounted) {
        setState(() => _remoteLoading = false);
      }
    }
  }

  String _displayPath() {
    if (_remoteDirKey.isEmpty) return '/';
    return _remoteDirKey.endsWith('/') ? _remoteDirKey : '$_remoteDirKey/';
  }

  bool get _canSubmitSingleAxisFile => _fileNameController.text.trim().isNotEmpty;

  String? _parentDirKey() {
    final normalized = _remoteDirKey.replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty || normalized == '/') return null;
    final parts = normalized.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    parts.removeLast();
    if (parts.isEmpty) return '';
    return '/${parts.join('/')}';
  }

  Future<void> _loadSelectedSingleAxisFile() async {
    final rawName = _fileNameController.text.trim();
    if (rawName.isEmpty) return;
    final fileName = rawName.toLowerCase().endsWith('.txt')
        ? rawName
        : '$rawName.txt';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('是否加载该文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final path = '$_singleAxisRoot/$fileName';
    _fileNameController.text = fileName;
    await widget.onLoadSingleAxisFile(path);
    if (!mounted) return;
    await _switchBottomView(DriverBottomView.motionParams);
  }

  Future<void> _saveSelectedSingleAxisFile() async {
    final rawName = _fileNameController.text.trim();
    if (rawName.isEmpty || !_displayPath().contains('/pid_ini_file/')) return;
    final fileName = rawName.toLowerCase().endsWith('.txt')
        ? rawName
        : '$rawName.txt';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('是否保存该文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _fileNameController.text = fileName;
    await widget.onSaveSingleAxisFile(fileName);
    if (!mounted) return;
    await _switchBottomView(DriverBottomView.motionParams);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBottomControls(context);
  }

  Widget _buildBottomControls(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DriverUiStyle.panelBackground,
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAxisToolbar(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBottomModeRail(),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: LpRobotColors.borderWarm.withValues(alpha: 0.65),
                ),
                Expanded(
                  child: _bottomView == DriverBottomView.motionParams
                      ? _buildMotionParamsBody(context)
                      : _buildSingleAxisFileBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomModeRail() {
    Widget item(String label, DriverBottomView view) {
      final selected = _bottomView == view;
      return Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: FilledButton(
          onPressed: widget.busy
              ? null
              : () async {
                  if (view == DriverBottomView.singleAxisParams && selected) {
                    _fileNameController.clear();
                    await _loadRemoteDir(_singleAxisRoot);
                    return;
                  }
                  await _switchBottomView(view);
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: selected ? Colors.white : LpRobotColors.primary,
            backgroundColor: selected ? LpRobotColors.primary : Colors.white,
            side: const BorderSide(color: LpRobotColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
    }

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item('运动参数', DriverBottomView.motionParams),
          const SizedBox(height: 28),
          item('单轴参数', DriverBottomView.singleAxisParams),
        ],
      ),
    );
  }

  Widget _buildMotionParamsBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶栏：左对齐，组间留固定间隔。
          Row(
            children: [
              _miniField(
                context,
                '控制模式',
                widget.controlMode,
                widget.onControlModeChanged,
                helpKey: 'control_mode',
                valueWidth: 88,
              ),
              const SizedBox(width: 28),
              _miniField(
                context,
                'JOG速度',
                widget.jogSpeed,
                widget.onJogSpeedChanged,
                helpKey: 'speed_jog',
                signed: true,
                valueWidth: 88,
              ),
              const SizedBox(width: 28),
              _miniField(
                context,
                '采样数量',
                widget.sampleCount,
                widget.onSampleCountChanged,
                helpKey: 'sample_count',
                valueWidth: 88,
              ),
              const SizedBox(width: 28),
              _miniField(
                context,
                '矢量Jerk',
                widget.jerk,
                widget.onJerkChanged,
                helpKey: 'jerk',
                valueWidth: 132,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 多轴固定行高：超出可滚动，轴少则下方留白（不拉伸撑满）。
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.axisRows.length,
              itemExtent: 40,
              itemBuilder: (context, i) =>
                  _axisDebugRow(i, widget.axisRows[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAxisFileBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.busy || _remoteLoading
                    ? null
                    : () {
                        final parent = _parentDirKey();
                        if (parent == null) return;
                        _loadRemoteDir(parent);
                      },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  '路径：${_displayPath()}',
                  style: DriverUiStyle.controlLabelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LpRobotColors.borderWarm.withValues(alpha: 0.55)),
              ),
              child: _remoteLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _remoteEntries.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: LpRobotColors.borderWarm.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        final entry = _remoteEntries[index];
                        final selected =
                            !entry.isDir && _fileNameController.text.trim() == entry.name;
                        return ListTile(
                          leading: Icon(
                            entry.isDir ? Icons.folder_open : Icons.description_outlined,
                            color: LpRobotColors.primary,
                          ),
                          title: Text(entry.name),
                          selected: selected,
                          onTap: widget.busy
                              ? null
                              : () {
                                  if (entry.isDir) {
                                    _loadRemoteDir(entry.listPath);
                                    return;
                                  }
                                  setState(() => _fileNameController.text = entry.name);
                                },
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fileNameController,
                  enabled: !widget.busy,
                  decoration: const InputDecoration(
                    labelText: '文件名',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _actionBtn('加载', _loadSelectedSingleAxisFile, enabled: _canSubmitSingleAxisFile),
              const SizedBox(width: 8),
              _actionBtn('保存', _saveSelectedSingleAxisFile, enabled: _canSubmitSingleAxisFile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisToolbar(BuildContext context) {
    // 左右顶格、控件间平分间隔。
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: DriverUiStyle.toolbarBarDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('当前轴号:', style: DriverUiStyle.toolbarLabelStyle),
              const SizedBox(width: 6),
              _axisDropdown(),
            ],
          ),
          _actionBtn('读驱动参数', widget.onReadDriver),
          _actionBtn('写驱动参数', widget.onWriteDriver),
          _actionBtn('写文件参数', widget.onWriteFile),
          _check('刷新', widget.refreshChart, widget.onRefreshChartChanged),
          _check('往返', widget.roundTrip, widget.onRoundTripChanged),
          _check(
            '循环',
            widget.loopMove,
            widget.onLoopChanged,
            enabledWhenBusy: true,
          ),
          _miniField(
            context,
            '延时(ms)',
            widget.delayMs,
            widget.onDelayChanged,
            helpKey: 'delay_ms',
            valueWidth: 72,
          ),
          _actionBtn('软复位', widget.onSoftReset),
          _actionBtn(
            widget.findPhaseButtonLabel,
            widget.onFindPhase,
            highlighted: widget.findPhaseActive,
            enabled: !widget.busy || widget.findPhaseActive,
          ),
          _actionBtn(
            '采集波形',
            widget.onSample,
            enabled: widget.refreshChart,
          ),
          _actionBtn('点动', widget.onPosRef),
        ],
      ),
    );
  }

  Widget _axisDropdown() {
    // 高度对齐工具栏按钮（约 34），保持图2紧凑样式，不做图1的 51 高。
    return SizedBox(
      height: DriverUiStyle.actionBtnHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: DriverUiStyle.valueBoxDecoration(emphasize: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: widget.curAxis,
            isDense: true,
            style: DriverUiStyle.fieldTextStyle,
            items: List.generate(
              widget.axisCount,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  '${i + 1}',
                  style: DriverUiStyle.fieldTextStyle,
                ),
              ),
            ),
            onChanged: widget.busy
                ? null
                : (v) => v == null ? null : widget.onAxisChanged(v),
          ),
        ),
      ),
    );
  }

  Widget _axisDebugRow(int index, AxisDebugRow row) {
    // J 左顶格；加速度/速度/距离输入框加宽一倍，组间拉开，右顶格。
    return SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: LpRobotColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                'J${index + 1}',
                style: const TextStyle(
                  fontFamily: DriverUiStyle.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _rowCheck('伺服', row.servoOn, (v) {
              row.servoOn = v;
              widget.onAxisServoChanged(index, v);
            }),
            const SizedBox(width: 16),
            _rowCheck('运动', row.motionOn, (v) {
              row.motionOn = v;
              widget.onAxisMotionChanged(index, v);
            }),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _rowField('加速度', row.acc, (v) {
                    row.acc = v;
                    widget.onAxisMotionFieldChanged(index, row);
                  }),
                  _rowField('速度', row.vel, (v) {
                    row.vel = v;
                    widget.onAxisMotionFieldChanged(index, row);
                  }),
                  _rowField('距离', row.distance, (v) {
                    row.distance = v;
                    widget.onAxisMotionFieldChanged(index, row);
                  }, signed: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    DriverAction action, {
    bool enabled = true,
    bool compact = false,
    bool highlighted = false,
  }) {
    final canPress = enabled && (!widget.busy || highlighted);
    final w = compact
        ? DriverUiStyle.actionBtnWidth * 0.85
        : DriverUiStyle.actionBtnWidth;
    final h = compact
        ? DriverUiStyle.actionBtnHeight * 0.9
        : DriverUiStyle.actionBtnHeight;

    return SizedBox(
      width: w,
      height: h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPress ? () => action() : null,
          borderRadius: BorderRadius.circular(DriverUiStyle.actionBtnRadius),
          child: Ink(
            decoration: DriverUiStyle.actionBtnDecoration(enabled: canPress),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: DriverUiStyle.fontFamily,
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: canPress
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniField(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? helpKey,
    bool signed = false,
    double valueWidth = 96,
  }) {
    void showHelp(BuildContext context) {
      final help = helpKey == null ? null : DriverParamsDefs.helpOf(helpKey);
      if (help == null || help.isEmpty) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(label),
          content: Text(help),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: helpKey == null ? null : () => showHelp(context),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: DriverUiStyle.controlLabelStyle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: valueWidth,
          height: 34,
          child: DriverAdaptiveValueField(
            value: value,
            enabled: !widget.busy,
            onChanged: onChanged,
            signed: signed,
          ),
        ),
      ],
    );
  }

  Widget _rowField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool signed = false,
    // 相对先前缩短版加宽一倍（112 → 224）。
    double valueWidth = 224,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: DriverUiStyle.controlLabelStyle,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: valueWidth,
          height: 32,
          child: DriverAdaptiveValueField(
            value: value,
            enabled: !widget.busy,
            onChanged: onChanged,
            signed: signed,
          ),
        ),
      ],
    );
  }

  Widget _rowCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return _canshuCheck(
      label,
      value,
      widget.busy ? null : onChanged,
    );
  }

  Widget _check(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabledWhenBusy = false,
  }) {
    final enabled = !(widget.busy && !enabledWhenBusy);
    return _canshuCheck(label, value, enabled ? onChanged : null);
  }

  /// 切图勾选：`canshu-check1` 未选 / `canshu-check2` 选中。
  Widget _canshuCheck(
    String label,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    const size = 18.0;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: DriverUiStyle.compactControlLabelStyle),
            const SizedBox(width: 8),
            Opacity(
              opacity: onChanged == null ? 0.45 : 1,
              child: Image.asset(
                value ? DriverCanshuAssets.checkOn : DriverCanshuAssets.checkOff,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
