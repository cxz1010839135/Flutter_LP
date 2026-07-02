import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../../files/robot_file_transfer.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';
import 'driver_param_widgets.dart';

typedef DriverAction = Future<void> Function();
typedef DriverDirLoader = Future<List<RemoteFileEntry>> Function(String dirKey);
typedef DriverFileAction = Future<void> Function(String filePath);

enum DriverBottomView { motionParams, singleAxisParams }

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
    final isSingleAxisView = _bottomView == DriverBottomView.singleAxisParams;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isSingleAxisView ? 4 : 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DriverParamColumn(
                  title: '电机参数设置',
                  tabLabels: const ['1', '2', '3'],
                  tabIndex: widget.motorTab,
                  onTabChanged: widget.onMotorTabChanged,
                  fieldGroups: const [
                    DriverParamsDefs.motorTab1,
                    DriverParamsDefs.motorTab2,
                    DriverParamsDefs.motorTab3,
                  ],
                  model: widget.model,
                  onFieldChanged: widget.onFieldChanged,
                  sectionKey: 'motor',
                  busy: widget.busy,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DriverGainColumn(
                  tabIndex: widget.gainTab,
                  onTabChanged: widget.onGainTabChanged,
                  model: widget.model,
                  onFieldChanged: widget.onFieldChanged,
                  busy: widget.busy,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DriverParamColumn(
                  title: '安全设置',
                  tabLabels: const ['1', '2', '3'],
                  tabIndex: widget.safeTab,
                  onTabChanged: widget.onSafeTabChanged,
                  fieldGroups: const [
                    DriverParamsDefs.safeTab1,
                    DriverParamsDefs.safeTab2,
                    DriverParamsDefs.safeTab3,
                  ],
                  model: widget.model,
                  onFieldChanged: widget.onFieldChanged,
                  sectionKey: 'safe',
                  busy: widget.busy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: isSingleAxisView ? 7 : 6,
          child: _buildBottomControls(context),
        ),
      ],
    );
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
        height: 64,
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
    }

    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item('运动参数', DriverBottomView.motionParams),
          item('单轴参数', DriverBottomView.singleAxisParams),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMotionParamsBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: _miniField(
                    context,
                    '控制模式',
                    widget.controlMode,
                    widget.onControlModeChanged,
                    helpKey: 'control_mode',
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _miniField(
                    context,
                    'JOG速度',
                    widget.jogSpeed,
                    widget.onJogSpeedChanged,
                    helpKey: 'speed_jog',
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _miniField(
                    context,
                    '采样数量',
                    widget.sampleCount,
                    widget.onSampleCountChanged,
                    helpKey: 'sample_count',
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _miniField(
                    context,
                    '矢量Jerk',
                    widget.jerk,
                    widget.onJerkChanged,
                    helpKey: 'jerk',
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.axisRows.length; i++)
                  _axisDebugRow(i, widget.axisRows[i]),
              ],
            ),
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: DriverUiStyle.toolbarBarDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('当前轴号:', style: DriverUiStyle.toolbarLabelStyle),
          const SizedBox(width: 10),
          _axisDropdown(prominent: true),
          const SizedBox(width: 18),
          _actionBtn('读驱动参数', widget.onReadDriver),
          const SizedBox(width: 10),
          _actionBtn('写驱动参数', widget.onWriteDriver),
          const SizedBox(width: 10),
          _actionBtn('写文件参数', widget.onWriteFile),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
                _check('刷新', widget.refreshChart, widget.onRefreshChartChanged),
                _check('往返', widget.roundTrip, widget.onRoundTripChanged),
                _check('循环', widget.loopMove, widget.onLoopChanged),
                SizedBox(
                  width: 130,
                  child: _miniField(
                    context,
                    '延时(ms)',
                    widget.delayMs,
                    widget.onDelayChanged,
                    helpKey: 'delay_ms',
                  ),
                ),
                _actionBtn('软复位', widget.onSoftReset),
                _actionBtn(widget.findPhaseButtonLabel, widget.onFindPhase),
                _actionBtn('采集波形', widget.onSample, enabled: widget.refreshChart),
                _actionBtn('点动', widget.onPosRef),
            ],
          ),
        ],
      ),
    );
  }

  Widget _axisDropdown({bool prominent = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 12 : 6,
        vertical: prominent ? 2 : 0,
      ),
      constraints: prominent ? const BoxConstraints(minWidth: 52) : null,
      decoration: DriverUiStyle.valueBoxDecoration(emphasize: true),
      child: DropdownButton<int>(
        value: widget.curAxis,
        underline: const SizedBox.shrink(),
        isDense: !prominent,
        style: prominent
            ? DriverUiStyle.fieldTextStyle
            : DriverUiStyle.compactFieldTextStyle,
        items: List.generate(
          widget.axisCount,
          (i) => DropdownMenuItem(
            value: i,
            child: Text(
              '${i + 1}',
              style: prominent
                  ? DriverUiStyle.fieldTextStyle
                  : DriverUiStyle.compactFieldTextStyle,
            ),
          ),
        ),
        onChanged: widget.busy ? null : (v) => v == null ? null : widget.onAxisChanged(v),
      ),
    );
  }

  Widget _axisDebugRow(int index, AxisDebugRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                'J${index + 1}',
                style: DriverUiStyle.controlLabelStyle,
              ),
            ),
            _rowCheck('伺服', row.servoOn, (v) {
              row.servoOn = v;
              widget.onAxisServoChanged(index, v);
            }),
            _rowCheck('运动', row.motionOn, (v) {
              row.motionOn = v;
              widget.onAxisMotionChanged(index, v);
            }),
            const SizedBox(width: 4),
            Expanded(child: _rowField('加速度', row.acc, (v) {
              row.acc = v;
              widget.onAxisMotionFieldChanged(index, row);
            })),
            const SizedBox(width: 4),
            Expanded(child: _rowField('速度', row.vel, (v) {
              row.vel = v;
              widget.onAxisMotionFieldChanged(index, row);
            })),
            const SizedBox(width: 4),
            Expanded(child: _rowField('距离', row.distance, (v) {
              row.distance = v;
              widget.onAxisMotionFieldChanged(index, row);
            })),
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
  }) {
    return OutlinedButton(
      onPressed: (widget.busy || !enabled) ? null : () => action(),
      style: OutlinedButton.styleFrom(
        foregroundColor: LpRobotColors.primary,
        side: const BorderSide(color: LpRobotColors.primary),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: compact ? Size.zero : const Size(0, 36),
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _miniField(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> onChanged,
    {String? helpKey,
    }
  ) {
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
      children: [
        Flexible(
          flex: 0,
          child: InkWell(
            onTap: helpKey == null ? null : () => showHelp(context),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DriverUiStyle.controlLabelStyle,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: SizedBox(
            height: 32,
            child: _DriverSmallField(
              value: value,
              enabled: !widget.busy,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowField(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      children: [
        Flexible(
          flex: 0,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DriverUiStyle.controlLabelStyle,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: SizedBox(
            height: 32,
            child: _DriverSmallField(
              value: value,
              enabled: !widget.busy,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: widget.busy ? null : (v) => onChanged(v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: DriverUiStyle.compactControlLabelStyle),
      ],
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: widget.busy ? null : (v) => onChanged(v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: DriverUiStyle.compactControlLabelStyle),
      ],
    );
  }
}

class _DriverSmallField extends StatefulWidget {
  const _DriverSmallField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<_DriverSmallField> createState() => _DriverSmallFieldState();
}

class _DriverSmallFieldState extends State<_DriverSmallField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _DriverSmallField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: DriverUiStyle.fieldTextStyle,
      decoration: DriverUiStyle.fieldDecoration(
        enabled: widget.enabled,
        compact: true,
      ),
    );
  }
}
