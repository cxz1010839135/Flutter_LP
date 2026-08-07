import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/lp_app_assets.dart';
import '../../app/lp_app_fonts.dart';
import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../app/widgets/lp_status_panel.dart';
import '../../core/lp_status_log.dart';
import '../../core/maintenance_edit_gate.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../core/robot_telemetry.dart';
import '../driver/driver_page.dart';
import '../driver/driver_tech_mode_gate.dart';
import '../driver/driver_ui_style.dart';
import '../files/files_page.dart';
import '../tool/tool_page.dart';
import 'config_file_defs.dart';
import 'config_file_service.dart';
import 'driver_params_dps_codec.dart';

/// 文件配置向导（对齐 Android [ConfigFileActivity]）。
class ConfigFilePage extends StatefulWidget {
  const ConfigFilePage({super.key});

  @override
  State<ConfigFilePage> createState() => _ConfigFilePageState();
}

class _ConfigFilePageState extends State<ConfigFilePage> {
  final _service = ConfigFileService.instance;

  int _stepIndex = 0;
  bool _showDriverPanel = false;
  bool _loading = false;
  bool _fileExists = true;
  List<ConfigFileRow> _rows = [];
  int? _selectedRow;
  bool _driverExists = true;
  List<DriverParamsRow> _driverRows = [];
  DriverParamsFileLayout? _driverLayout;
  int _driverAxisCount = 6;
  int? _selectedDriverRow;

  /// 全选时会连点多行，短时内只弹一次提示。
  DateTime? _lastBlockedTipAt;

  List<ConfigFileStepDef> get _steps =>
      buildConfigFileSteps(RobotState.instance.robotModel);

  ConfigFileStepDef get _step {
    final step = stepByIndex(_steps, _stepIndex);
    assert(step != null);
    return step!;
  }

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
    _loadStep();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadStep() async {
    if (!RobotState.instance.isConnected) return;
    setState(() {
      _loading = true;
      _selectedRow = null;
    });
    try {
      final result = await _service.load(_step);
      if (!mounted) return;
      setState(() {
        _fileExists = result.exists;
        _rows = result.rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      LpStatusLog.instance.warning('获取文件失败：$e');
    }
  }

  Future<void> _loadDriverPanel() async {
    setState(() => _loading = true);
    try {
      final result = await _service.loadDriverParams(
        RobotState.instance.robotModel,
      );
      if (!mounted) return;
      setState(() {
        _driverExists = result.exists;
        _driverRows = result.rows;
        _driverLayout = result.layout;
        _driverAxisCount = result.layout?.axisCount ?? result.axisCount;
        _selectedDriverRow = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      LpStatusLog.instance.warning('获取驱动参数文件失败：$e');
    }
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示信息'),
        content: Text(message),
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
    return ok == true;
  }

  Future<void> _saveFile() async {
    if (!await _confirm('是否保存该文件')) return;
    setState(() => _loading = true);
    try {
      await _service.save(_step, _rows);
      if (!mounted) return;
      LpStatusLog.instance.success('修改参数成功！', openPanel: false);
      // 对齐 Android：上传后短暂等待再刷新，避免立即读文件竞态。
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final result = await _service.load(_step);
      if (!mounted) return;
      setState(() {
        _fileExists = result.exists;
        _rows = result.rows;
        _selectedRow = null;
      });
    } catch (e) {
      LpStatusLog.instance.warning('修改参数失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createFile() async {
    if (!await _confirm('是否创建该文件')) return;
    setState(() => _loading = true);
    try {
      await _service.createDefault(_step);
      LpStatusLog.instance.success('创建文件成功！', openPanel: false);
      await _loadStep();
    } catch (e) {
      LpStatusLog.instance.warning('创建文件失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyEtherCat() async {
    setState(() => _loading = true);
    try {
      await _service.applyEtherCat(_rows);
      LpStatusLog.instance.success('配置扩展文件成功！', openPanel: false);
      await _service.save(_step, _rows);
      await _loadStep();
    } catch (e) {
      LpStatusLog.instance.warning('配置扩展文件失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDriverFile() async {
    if (_driverLayout == null) {
      LpStatusLog.instance.warning('驱动参数布局未加载，请重新打开');
      return;
    }
    if (!await _confirm('是否保存该文件')) return;
    setState(() => _loading = true);
    try {
      await _service.saveDriverParams(
        RobotState.instance.robotModel,
        _driverRows,
        _driverLayout!,
      );
      if (!mounted) return;
      LpStatusLog.instance.success('保存文件成功！', openPanel: false);
      setState(() => _loading = false);
    } catch (e) {
      LpStatusLog.instance.warning('保存文件失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showBlockedTip() async {
    final now = DateTime.now();
    if (_lastBlockedTipAt != null &&
        now.difference(_lastBlockedTipAt!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastBlockedTipAt = now;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text(MaintenanceEditGate.blockedTip),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 运动中点选/勾选：提示且不进入修改。
  bool _guardSelectForEdit() {
    if (MaintenanceEditGate.canEdit()) return true;
    unawaited(_showBlockedTip());
    return false;
  }

  Future<void> _editDriverRow(int index) async {
    final row = _driverRows[index];
    final readOnly = !MaintenanceEditGate.canEdit();
    if (readOnly) {
      await _showBlockedTip();
      if (!mounted) return;
      await _showDriverRowViewDialog(row);
      return;
    }
    final axisCount = _driverAxisCount;
    final headers = DriverParamsDpsCodec.axisHeadersFor(axisCount);
    final controllers = List.generate(
      axisCount,
      (i) => TextEditingController(
        text: i < row.values.length ? row.values[i] : '',
      ),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改：${row.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < axisCount; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: headers[i],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    if (saved == true) {
      setState(() {
        _driverRows[index] = row.copyWith(
          values: controllers.map((c) => c.text.trim()).toList(),
        );
      });
    }
    for (final c in controllers) {
      c.dispose();
    }
  }

  void _goNext() {
    if (_showDriverPanel) return;
    final next = nextConfigNavIndex(_stepIndex);
    if (next == null) {
      setState(() {
        _showDriverPanel = true;
        _selectedRow = null;
      });
      _loadDriverPanel();
      return;
    }
    setState(() {
      _stepIndex = next;
      _selectedRow = null;
    });
    _loadStep();
  }

  void _goBack() {
    if (_showDriverPanel) {
      setState(() {
        _showDriverPanel = false;
        _stepIndex = configFileNavOrder.last;
      });
      _loadStep();
      return;
    }
    final prev = prevConfigNavIndex(_stepIndex);
    if (prev == null) return;
    setState(() {
      _stepIndex = prev;
      _selectedRow = null;
    });
    _loadStep();
  }

  void _addRow() {
    final labels = _step.buildRowLabels();
    final name = _rows.length < labels.length
        ? labels[_rows.length]
        : '条目${_rows.length}';
    setState(() {
      _rows = [
        ..._rows,
        ConfigFileRow(
          name: name,
          values: List.filled(_step.editableColumnCount, ''),
        ),
      ];
    });
  }

  void _removeRow() {
    if (_rows.isEmpty) return;
    if (_rows.length <= _step.minRows) return;
    setState(() {
      final idx = _selectedRow ?? _rows.length - 1;
      _rows = [..._rows]..removeAt(idx.clamp(0, _rows.length - 1));
      _selectedRow = null;
    });
  }

  Future<void> _openDebugMode() async {
    final gate = DriverTechModeGate.instance;
    if (!gate.canEnterDriverPage) {
      if (gate.transitionBusy || DriverTechModeGate.isControllerInitializing) {
        LpStatusLog.instance.warning('调试模式切换中，请等待控制器就绪');
      } else {
        LpStatusLog.instance.warning('请先连接控制器');
      }
      return;
    }
    try {
      await gate.enter();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const DriverPage()),
      );
    } catch (e) {
      LpStatusLog.instance.warning('进入调试模式失败：$e');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('提示'),
          content: Text('$e'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _editRow(int index) async {
    final row = _rows[index];
    final readOnly = !MaintenanceEditGate.canEdit();
    if (readOnly) {
      await _showBlockedTip();
      if (!mounted) return;
      await _showRowViewDialog(row);
      return;
    }
    final controllers = List.generate(
      _step.editableColumnCount,
      (i) => TextEditingController(
        text: i < row.values.length ? row.values[i] : '',
      ),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改：${row.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _step.editableColumnCount; i++)
                if (i < _step.columnHeaders.length &&
                    _step.columnHeaders[i].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: _step.columnHeaders[i],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )
                else if (_step.editableColumnCount == 1)
                  TextField(
                    controller: controllers[i],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
            ],
          ),
        ),
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
    if (saved == true) {
      setState(() {
        _rows[index] = row.copyWith(
          values: controllers.map((c) => c.text.trim()).toList(),
        );
      });
    }
    for (final c in controllers) {
      c.dispose();
    }
  }

  Future<void> _showRowViewDialog(ConfigFileRow row) {
    final lines = <String>[];
    for (var i = 0; i < _step.editableColumnCount; i++) {
      final header = i < _step.columnHeaders.length
          ? _step.columnHeaders[i]
          : '值';
      final value = i < row.values.length ? row.values[i] : '';
      if (header.isEmpty && _step.editableColumnCount == 1) {
        lines.add(value);
      } else if (header.isNotEmpty) {
        lines.add('$header：$value');
      }
    }
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('查看：${row.name}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Text(
              lines.isEmpty ? '（无数据）' : lines.join('\n'),
              style: DriverUiStyle.configBodyStyle,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDriverRowViewDialog(DriverParamsRow row) {
    final headers = DriverParamsDpsCodec.axisHeadersFor(_driverAxisCount);
    final lines = <String>[];
    for (var i = 0; i < _driverAxisCount; i++) {
      final value = i < row.values.length ? row.values[i] : '';
      lines.add('${headers[i]}：$value');
    }
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('查看：${row.name}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Text(
              lines.join('\n'),
              style: DriverUiStyle.configBodyStyle,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotTelemetry.instance,
        DriverTechModeGate.instance,
      ]),
      builder: (context, _) {
        final initBusy = DriverTechModeGate.isControllerInitializing;
        final canEdit = MaintenanceEditGate.canEdit();

        return Theme(
          data: DriverUiStyle.configFilePageTheme(Theme.of(context)),
          child: Scaffold(
            backgroundColor: DriverUiStyle.pageBackground,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LpRobotPoseBar(
                  pageTitle: '文件配置',
                  titleBarOnly: true,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _showDriverPanel
                      ? _buildDriverPanel()
                      : _buildStepPanel(),
                ),
                _buildBottomBar(initBusy: initBusy, canEdit: canEdit),
                const LpStatusPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧说明：wenjian-leftbox-bg
          SizedBox(
            width: 260,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(LpAppAssets.configLeftBoxBg),
                  fit: BoxFit.fill,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 10, 12),
                child: _buildTipsList(_step.tips),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 主内容：wenjian-main-boxbg（含左上角页签位）
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(LpAppAssets.configMainBoxBg),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 16, 6),
                    child: Text(
                      _step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LpAppFonts.style(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: LpRobotColors.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : !_fileExists
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      LpAppAssets.configMainBoxIcon,
                                      width: 88,
                                      height: 72,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '文件不存在',
                                      style: LpAppFonts.style(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xCC3F260F),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildTable(),
                  ),
                  if (_fileExists &&
                      _step.allowAdd &&
                      MaintenanceEditGate.canEdit())
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('添加条目'),
                          ),
                          if (_step.allowRemove)
                            TextButton.icon(
                              onPressed: _removeRow,
                              icon: const Icon(Icons.remove, size: 18),
                              label: const Text('删除条目'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final headers = <String>['名称', ..._step.columnHeaders.where((h) => h.isNotEmpty)];
    if (headers.length == 1 && _step.editableColumnCount == 1) {
      headers.add('值');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            LpRobotColors.primary.withValues(alpha: 0.12),
          ),
          columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
          rows: [
            for (var i = 0; i < _rows.length; i++)
              DataRow(
                cells: [
                  DataCell(
                    Text(_rows[i].name),
                    onTap: () {
                      if (!_guardSelectForEdit()) return;
                      setState(() => _selectedRow = i);
                      unawaited(_editRow(i));
                    },
                  ),
                  ...List.generate(
                    _step.editableColumnCount,
                    (col) => DataCell(
                      Text(
                        col < _rows[i].values.length
                            ? _rows[i].values[col]
                            : '',
                      ),
                      onTap: () {
                        if (!_guardSelectForEdit()) return;
                        setState(() => _selectedRow = i);
                        unawaited(_editRow(i));
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(LpAppAssets.configMainBoxBg),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 16, 6),
              child: Text(
                '驱控文件参数(保存后请重启驱控) · 当前 $_driverAxisCount 轴',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LpAppFonts.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LpRobotColors.textDark,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_driverExists
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                LpAppAssets.configMainBoxIcon,
                                width: 88,
                                height: 72,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '该文件不存在',
                                style: LpAppFonts.style(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xCC3F260F),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildDriverTable(),
            ),
            if (_driverExists && MaintenanceEditGate.canEdit())
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _WenjianFootButton(
                    label: '保存文件',
                    primary: true,
                    enabled: !_loading,
                    onPressed: _saveDriverFile,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverTable() {
    final axisHeaders = DriverParamsDpsCodec.axisHeadersFor(_driverAxisCount);
    final headers = ['名称', ...axisHeaders];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                LpRobotColors.primary.withValues(alpha: 0.12),
              ),
              columnSpacing: 20,
              columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
              rows: [
                for (var i = 0; i < _driverRows.length; i++)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(_driverRows[i].name),
                        ),
                        onTap: () {
                          if (!_guardSelectForEdit()) return;
                          setState(() => _selectedDriverRow = i);
                          unawaited(_editDriverRow(i));
                        },
                      ),
                      ...List.generate(
                        _driverAxisCount,
                        (col) => DataCell(
                          Text(
                            col < _driverRows[i].values.length
                                ? _driverRows[i].values[col]
                                : '',
                          ),
                          onTap: () {
                            if (!_guardSelectForEdit()) return;
                            setState(() => _selectedDriverRow = i);
                            unawaited(_editDriverRow(i));
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar({required bool initBusy, required bool canEdit}) {
    final nextEnabled = !_loading;
    final createEnabled = !_loading && canEdit;

    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(LpAppAssets.configFootBg),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _navLink('文件管理', () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const FilesPage()),
                );
              }),
              _navDivider(),
              // 「版本」改为「配置」，仍进入原版本/维护页。
              _navLink('配置', () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const ToolPage()),
                );
              }),
              _navDivider(),
              if (initBusy || DriverTechModeGate.instance.transitionBusy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _navLink(
                  '调试模式',
                  canEdit && DriverTechModeGate.instance.canEnterDriverPage
                      ? _openDebugMode
                      : null,
                ),
              const Spacer(),
              if (!_showDriverPanel && !_fileExists && canEdit) ...[
                _WenjianFootButton(
                  label: '创建该文件',
                  primary: true,
                  enabled: createEnabled,
                  onPressed: _createFile,
                ),
                const SizedBox(width: 10),
              ],
              if (!_showDriverPanel &&
                  _fileExists &&
                  !_step.hideSave &&
                  canEdit) ...[
                _WenjianFootButton(
                  label: '保存文件',
                  primary: true,
                  enabled: !_loading,
                  onPressed: _saveFile,
                ),
                const SizedBox(width: 10),
              ],
              if (!_showDriverPanel &&
                  _fileExists &&
                  _step.showEtherCatButton &&
                  canEdit) ...[
                _WenjianFootButton(
                  label: '配置扩展',
                  primary: true,
                  enabled: !_loading,
                  onPressed: _applyEtherCat,
                ),
                const SizedBox(width: 10),
              ],
              if (_showDriverPanel || prevConfigNavIndex(_stepIndex) != null) ...[
                _WenjianFootButton(
                  label: _showDriverPanel ? '上一页' : '上一步',
                  primary: false,
                  highlightOnHover: true,
                  enabled: !_loading,
                  onPressed: _goBack,
                ),
                const SizedBox(width: 10),
              ],
              _WenjianFootButton(
                label: _showDriverPanel ? '完成' : '下一步',
                primary: false,
                highlightOnHover: true,
                enabled: nextEnabled,
                onPressed: _showDriverPanel
                    ? () => Navigator.of(context).pop()
                    : _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 1,
        height: 18,
        color: LpRobotColors.primary.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback? onPressed, {bool selected = false}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: LpRobotColors.primary,
        disabledForegroundColor: selected
            ? LpRobotColors.primary
            : LpRobotColors.primary.withValues(alpha: 0.4),
        textStyle: LpAppFonts.style(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: LpRobotColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  /// 左侧说明：数字叠在六边形切图上（图2底 + 图3标号）。
  Widget _buildTipsList(String tips) {
    final items = _parseTipItems(tips);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    LpAppAssets.configLeftBoxTt,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  Text(
                    '${item.number}',
                    style: LpAppFonts.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.text,
                style: LpAppFonts.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.textDark,
                  height: 1.55,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TipItem> _parseTipItems(String tips) {
    final raw = tips.trim();
    if (raw.isEmpty) return const [];
    final lines = raw.split(RegExp(r'\r?\n'));
    final items = <_TipItem>[];
    final numbered = RegExp(r'^(\d+)[、．.．]\s*(.*)$');
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final m = numbered.firstMatch(t);
      if (m != null) {
        items.add(_TipItem(
          number: int.tryParse(m.group(1)!) ?? (items.length + 1),
          text: m.group(2) ?? '',
        ));
      } else if (items.isNotEmpty) {
        final last = items.removeLast();
        items.add(_TipItem(number: last.number, text: '${last.text}\n$t'));
      } else {
        items.add(_TipItem(number: items.length + 1, text: t));
      }
    }
    return items;
  }
}

class _TipItem {
  const _TipItem({required this.number, required this.text});
  final int number;
  final String text;
}

/// 底部操作按钮：切图 wenjian-foot-btn1（主色）/ btn2（次色）。
/// [highlightOnHover]：上下页默认次色，鼠标悬停/焦点才变主色。
class _WenjianFootButton extends StatefulWidget {
  const _WenjianFootButton({
    required this.label,
    required this.primary,
    required this.enabled,
    required this.onPressed,
    this.highlightOnHover = false,
  });

  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback onPressed;
  final bool highlightOnHover;

  @override
  State<_WenjianFootButton> createState() => _WenjianFootButtonState();
}

class _WenjianFootButtonState extends State<_WenjianFootButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hot = widget.highlightOnHover && (_hovered || _focused);
    final usePrimary = widget.enabled && (widget.primary || hot);
    final asset =
        usePrimary ? LpAppAssets.configFootBtn1 : LpAppAssets.configFootBtn2;
    final textColor = usePrimary
        ? Colors.white
        : LpRobotColors.textDark.withValues(alpha: widget.enabled ? 0.85 : 0.45);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.85,
      child: Focus(
        canRequestFocus: widget.enabled,
        onFocusChange: (v) {
          if (_focused == v) return;
          setState(() => _focused = v);
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (!widget.enabled || _hovered) return;
            setState(() => _hovered = true);
          },
          onExit: (_) {
            if (!_hovered) return;
            setState(() => _hovered = false);
          },
          child: GestureDetector(
            onTap: widget.enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 132,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(asset),
                  fit: BoxFit.fill,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: LpAppFonts.style(
                  fontSize: 15,
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
