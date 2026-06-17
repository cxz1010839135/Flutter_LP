import 'package:flutter/material.dart';

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

  Future<void> _editDriverRow(int index) async {
    final row = _driverRows[index];
    final readOnly = !MaintenanceEditGate.canEdit();
    if (readOnly) {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 280,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: DriverUiStyle.panelDecoration(),
          child: SingleChildScrollView(
            child: Text(
              _step.tips.isEmpty ? ' ' : _step.tips,
              style: DriverUiStyle.configBodyStyle.copyWith(height: 1.65),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            decoration: DriverUiStyle.panelDecoration(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Text(
                  _step.title,
                  style: DriverUiStyle.configTitleStyle,
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : !_fileExists
                        ? const Center(
                            child: Text(
                              '文件不存在',
                              style: DriverUiStyle.configPlaceholderStyle,
                            ),
                          )
                        : _buildTable(),
              ),
              if (_fileExists && _step.allowAdd && MaintenanceEditGate.canEdit())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                selected: _selectedRow == i,
                onSelectChanged: (_) {
                  setState(() => _selectedRow = i);
                  _editRow(i);
                },
                cells: [
                  DataCell(Text(_rows[i].name)),
                  ...List.generate(
                    _step.editableColumnCount,
                    (col) => DataCell(
                      Text(
                        col < _rows[i].values.length
                            ? _rows[i].values[col]
                            : '',
                      ),
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
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: DriverUiStyle.panelDecoration(),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '驱控文件参数(保存后请重启驱控) · 当前 $_driverAxisCount 轴',
            textAlign: TextAlign.center,
            style: DriverUiStyle.configTitleStyle,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_driverExists
                  ? const Center(
                      child: Text(
                        '该文件不存在',
                        style: DriverUiStyle.configPlaceholderStyle,
                      ),
                    )
                  : _buildDriverTable(),
        ),
        if (_driverExists && MaintenanceEditGate.canEdit())
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _loading ? null : _saveDriverFile,
                child: const Text('保存文件'),
              ),
            ),
          ),
      ],
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
                    selected: _selectedDriverRow == i,
                    onSelectChanged: (_) {
                      setState(() => _selectedDriverRow = i);
                      _editDriverRow(i);
                    },
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(_driverRows[i].name),
                        ),
                      ),
                      ...List.generate(
                        _driverAxisCount,
                        (col) => DataCell(
                          Text(
                            col < _driverRows[i].values.length
                                ? _driverRows[i].values[col]
                                : '',
                          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DriverUiStyle.panelBackground,
        border: Border(
          top: BorderSide(color: LpRobotColors.borderWarm.withValues(alpha: 0.65)),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const FilesPage()),
            ),
            child: const Text('文件管理 >'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const ToolPage()),
            ),
            child: const Text('版本'),
          ),
          if (initBusy || DriverTechModeGate.instance.transitionBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: canEdit && DriverTechModeGate.instance.canEnterDriverPage
                  ? _openDebugMode
                  : null,
              child: const Text('调试模式'),
            ),
          const Spacer(),
          if (!_showDriverPanel && !_fileExists && canEdit)
            FilledButton(
              onPressed: _loading ? null : _createFile,
              child: const Text('创建该文件'),
            ),
          if (!_showDriverPanel && _fileExists && !_step.hideSave && canEdit)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton(
                onPressed: _loading ? null : _saveFile,
                child: const Text('保存文件'),
              ),
            ),
          if (!_showDriverPanel && _fileExists && _step.showEtherCatButton && canEdit)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton(
                onPressed: _loading ? null : _applyEtherCat,
                child: const Text('配置扩展'),
              ),
            ),
          if (_showDriverPanel || prevConfigNavIndex(_stepIndex) != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton(
                onPressed: _loading ? null : _goBack,
                child: Text(_showDriverPanel ? '上一页' : '上一步'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilledButton(
              onPressed: _loading
                  ? null
                  : _showDriverPanel
                      ? () => Navigator.of(context).pop()
                      : _goNext,
              child: Text(_showDriverPanel ? '完成' : '下一步'),
            ),
          ),
        ],
      ),
    );
  }
}
