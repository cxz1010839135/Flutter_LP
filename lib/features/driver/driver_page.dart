import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_alarm_info.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../files/robot_file_transfer.dart';
import 'driver_address_debug_page.dart';
import 'driver_params_model.dart';
import 'driver_params_service.dart';
import 'driver_tech_mode_gate.dart';
import 'driver_ui_style.dart';
import 'widgets/driver_params_panel.dart';
import 'widgets/driver_status_bar.dart';
import 'widgets/driver_title_bar.dart';
import 'widgets/driver_waveform_panel.dart';

/// 驱动器调试（对齐 Android [DriverActivity]）。
class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage>
    with SingleTickerProviderStateMixin {
  static const Duration _findPhaseTimeout = Duration(seconds: 30);
  final _service = DriverParamsService();
  final _model = DriverParamsModel();
  final _live = DriverAxisLiveStatus();

  late final TabController _tabController;
  Timer? _pollTimer;
  bool _busy = false;
  bool _exiting = false;
  bool _waveLoading = false;
  bool _pendingParamsRead = false;

  int _curAxis = 0;
  int _motorTab = 0;
  int _gainTab = 0;
  int _safeTab = 0;

  String _sampleCount = '2000';
  String _delayMs = '0';
  String _jerk = '0';
  String _currentMaxLimit = '5';
  String _speedMaxLimit = '3000';
  String _posErrMaxLimit = '10000';
  bool _refreshChart = false;
  bool _roundTrip = false;
  bool _loopMove = false;

  late List<AxisDebugRow> _axisRows;
  Map<String, List<double>> _waveSeries = const {};

  static const _tabTitles = ['驱动器参数', '波形观测'];

  @override
  void initState() {
    super.initState();
    RobotStatePoller.instance.start();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _initAxisRows();
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!DriverTechModeGate.instance.sessionActive) return;
      if (DriverTechModeGate.instance.transitionBusy) return;
      _readDriverParams();
    });
  }

  void _initAxisRows() {
    final count = _service.totalAxisNum;
    _axisRows = List.generate(count, (i) => AxisDebugRow(i));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _pollAxisStatus();
    });
  }

  Future<void> _pollAxisStatus() async {
    if (!RobotState.instance.isConnected || _busy || _exiting) return;
    if (DriverTechModeGate.instance.transitionBusy) return;
    try {
      final status = await _service.pollAxisStatus(_curAxis);
      if (!mounted) return;
      setState(() => _live
        ..checkCount = status.checkCount
        ..busVoltage = status.busVoltage
        ..epwmTime = status.epwmTime
        ..posErr = status.posErr
        ..currentRef = status.currentRef
        ..currentFdb = status.currentFdb
        ..speedRef = status.speedRef
        ..speedFdb = status.speedFdb
        ..speedWatch = status.speedWatch
        ..servoState = status.servoState
        ..posFdb = status.posFdb
        ..posRef = status.posRef
        ..encSingle = status.encSingle
        ..encMulti = status.encMulti
        ..findPhaseFlag = status.findPhaseFlag);
    } catch (_) {}
  }

  Future<void> _runBusy(Future<void> Function() action, {String? okMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (okMsg != null) {
        LpStatusLog.instance.success(okMsg, openPanel: false);
      }
    } catch (e) {
      LpStatusLog.instance.warning('$e');
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_pendingParamsRead) {
          _pendingParamsRead = false;
          _readDriverParams();
        }
      }
    }
  }

  Future<void> _exitPage() async {
    if (_exiting) return;
    _exiting = true;
    _pollTimer?.cancel();
    setState(() => _busy = true);
    try {
      await DriverTechModeGate.instance.exit();
    } catch (e) {
      LpStatusLog.instance.warning('退出调试模式失败：$e');
      if (mounted) {
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
    } finally {
      _exiting = false;
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
      }
    }
  }

  /// 按当前轴号读取驱动参数（对齐 Android Spinner 切换即 getParams）。
  Future<void> _readDriverParams({bool showSuccess = false}) async {
    if (_busy) {
      _pendingParamsRead = true;
      return;
    }
    final axis = _curAxis;
    await _runBusy(() async {
      await _service.readParams(axis, _model);
      if (!mounted) return;
      setState(() {});
    }, okMsg: showSuccess ? '读驱动参数成功！' : null);
  }

  void _onAxisChanged(int axis) {
    if (axis == _curAxis) return;
    setState(() => _curAxis = axis);
    _readDriverParams();
  }

  Future<void> _readDriver() => _readDriverParams(showSuccess: true);

  String _modelField(String key, {String fallback = '0'}) {
    final v = _model.get(key).trim();
    return v.isEmpty ? fallback : v;
  }

  void _onParamFieldChanged(String key, String value) {
    _model.set(key, value);
    if (key == 'control_mode' || key == 'speed_jog') {
      setState(() {});
    }
  }

  Future<void> _writeDriver() async {
    await _runBusy(() async {
      await _service.writeParams(_curAxis, _model);
    }, okMsg: '写驱动参数成功！');
  }

  Future<void> _writeFile() async {
    await _runBusy(() async {
      await _service.writeParamsToFile(_curAxis, _model);
    }, okMsg: '写文件参数成功！');
  }

  Future<void> _softReset() async {
    await _runBusy(() async {
      await _service.softReset();
    }, okMsg: '软复位成功！');
  }

  Future<void> _findPhase() async {
    final isRunning = _live.findPhaseFlag == 1;
    if (!isRunning) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('提示'),
          content: Text('${_curAxis + 1}轴电机将进行寻相'),
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
    }
    await _runBusy(() async {
      if (!isRunning && _live.servoState != 0) {
        final desc = RobotAlarmInfo.describeCode(_live.servoState);
        throw Exception(
          desc.isEmpty
              ? '${_curAxis + 1}轴存在报警代码：${_live.servoState}'
              : '${_curAxis + 1}轴存在报警代码：${_live.servoState}（$desc）',
        );
      }
      if (isRunning) {
        await _service.stopPhase(_curAxis);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _showFindPhaseTip(-2);
        return;
      }
      await _service.findPhase(_curAxis);
      final flag = await _waitFindPhaseResult();
      await _service.readParams(_curAxis, _model);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _showFindPhaseTip(flag);
      if (mounted) setState(() {});
    });
  }

  void _showFindPhaseTip(int flag) {
    final tip = switch (flag) {
      0 => '寻相完成,零相角度为${_modelField('zero_phase')}',
      -1 => '寻相超时,寻相失败',
      -2 => '已停止寻相',
      -3 => '电机报警，寻相失败',
      _ => '未知错误',
    };
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(tip),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<int> _waitFindPhaseResult() async {
    final deadline = DateTime.now().add(_findPhaseTimeout);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final status = await _service.pollAxisStatus(_curAxis);
      if (!mounted) return -2;
      setState(() => _live
        ..checkCount = status.checkCount
        ..busVoltage = status.busVoltage
        ..epwmTime = status.epwmTime
        ..posErr = status.posErr
        ..currentRef = status.currentRef
        ..currentFdb = status.currentFdb
        ..speedRef = status.speedRef
        ..speedFdb = status.speedFdb
        ..speedWatch = status.speedWatch
        ..servoState = status.servoState
        ..posFdb = status.posFdb
        ..posRef = status.posRef
        ..encSingle = status.encSingle
        ..encMulti = status.encMulti
        ..findPhaseFlag = status.findPhaseFlag);
      if (status.findPhaseFlag != 1) {
        if (status.servoState != 0) {
          return -3;
        }
        return status.findPhaseFlag;
      }
    }
    try {
      await _service.stopPhase(_curAxis);
    } catch (_) {}
    return -1;
  }

  Future<List<RemoteFileEntry>> _listSingleAxisDir(String dirKey) {
    return _service.listRemoteDir(dirKey);
  }

  void _clearSelectedRowServo() {
    for (final row in _axisRows) {
      row.servoOn = false;
      row.motionOn = false;
    }
  }

  Future<void> _loadSingleAxisFile(String filePath) async {
    await _runBusy(() async {
      await _service.loadSingleAxisParams(_curAxis, filePath, _model);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _clearSelectedRowServo();
      if (mounted) setState(() {});
    }, okMsg: '单轴参数已加载');
  }

  Future<void> _saveSingleAxisFile(String filePath) async {
    await _runBusy(() async {
      await _service.saveSingleAxisParams(_curAxis, filePath);
    }, okMsg: '单轴参数已保存');
  }

  Future<void> _posRef() async {
    await _runBusy(() async {
      final axes = <int>[];
      final pos = <int>[];
      final vel = <int>[];
      final acc = <int>[];
      final jerks = <int>[];
      final jerkVal = int.tryParse(_jerk) ?? 0;
      for (final row in _axisRows) {
        if (!row.motionOn && !row.servoOn) continue;
        axes.add(row.axisIndex);
        pos.add(int.tryParse(row.distance) ?? 0);
        vel.add(int.tryParse(row.vel) ?? 0);
        acc.add(int.tryParse(row.acc) ?? 0);
        jerks.add(jerkVal);
      }
      if (axes.isEmpty) {
        axes.add(_curAxis);
        pos.add(int.tryParse(_axisRows[_curAxis].distance) ?? 0);
        vel.add(int.tryParse(_axisRows[_curAxis].vel) ?? 0);
        acc.add(int.tryParse(_axisRows[_curAxis].acc) ?? 0);
        jerks.add(jerkVal);
      }
      await _service.techMove(
        returnTrip: _roundTrip ? 1 : 0,
        repeat: _loopMove ? 1 : 0,
        chart: _refreshChart ? 1 : 0,
        chartData: int.tryParse(_sampleCount) ?? 2000,
        chartAxis: _curAxis,
        delayMs: int.tryParse(_delayMs) ?? 0,
        axes: axes,
        positions: pos,
        velocities: vel,
        accs: acc,
        jerks: jerks,
      );
      if (_refreshChart) {
        await _pullWaveform();
      }
    }, okMsg: '点动指令已发送');
  }

  Future<void> _sampleWaveform() async {
    await _runBusy(() async {
      await _pullWaveform();
    });
  }

  Future<void> _pullWaveform() async {
    setState(() => _waveLoading = true);
    try {
      final len = int.tryParse(_sampleCount) ?? 2000;
      final data = await _service.fetchWaveformData(index: 0, len: len);
      if (!mounted) return;
      setState(() => _waveSeries = data);
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    } finally {
      if (mounted) setState(() => _waveLoading = false);
    }
  }

  void _onAxisMotionFieldChanged(int index, AxisDebugRow row) {
    _axisRows[index] = row;
  }

  Future<void> _onAxisServoChanged(int index, bool on) async {
    _axisRows[index].servoOn = on;
    if (_busy) return;
    try {
      await _service.setServo(index, on);
    } catch (e) {
      LpStatusLog.instance.warning('轴${index + 1}伺服开关失败：$e');
    }
  }

  Future<void> _onAxisMotionChanged(int index, bool on) async {
    _axisRows[index].motionOn = on;
    if (_busy) return;
    try {
      await _service.setMotionActive(index, on);
    } catch (e) {
      LpStatusLog.instance.warning('轴${index + 1}运动开关失败：$e');
    }
  }

  void _openAddressDebug() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DriverAddressDebugPage(initialAxis: _curAxis),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitPage();
      },
      child: Scaffold(
        backgroundColor: DriverUiStyle.pageBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DriverTitleBar(
              title: _tabTitles[_tabController.index],
              onBack: _exitPage,
            ),
            DriverStatusBar(
              live: _live,
              currentMaxLimit: _currentMaxLimit,
              speedMaxLimit: _speedMaxLimit,
              posErrMaxLimit: _posErrMaxLimit,
              onCurrentMaxLimitChanged: (v) => _currentMaxLimit = v,
              onSpeedMaxLimitChanged: (v) => _speedMaxLimit = v,
              onPosErrMaxLimitChanged: (v) => _posErrMaxLimit = v,
              onAddressDebug: _openAddressDebug,
            ),
            IgnorePointer(
              ignoring: _busy || _exiting,
              child: Material(
                color: DriverUiStyle.pageBackground,
                child: TabBar(
                  controller: _tabController,
                  labelColor: LpRobotColors.primary,
                  unselectedLabelColor: LpRobotColors.textDark,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorColor: LpRobotColors.primary,
                  tabs: const [
                    Tab(text: '驱动器参数'),
                    Tab(text: '波形观测'),
                  ],
                ),
              ),
            ),
            if (_busy)
              const LinearProgressIndicator(
                color: LpRobotColors.primary,
                backgroundColor: Color(0x22FF7E1A),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: (_busy || _exiting)
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: DriverParamsPanel(
                      model: _model,
                      curAxis: _curAxis,
                      axisCount: _service.totalAxisNum,
                      axisRows: _axisRows,
                      motorTab: _motorTab,
                      gainTab: _gainTab,
                      safeTab: _safeTab,
                      controlMode: _modelField('control_mode'),
                      jogSpeed: _modelField('speed_jog', fallback: '500'),
                      sampleCount: _sampleCount,
                      delayMs: _delayMs,
                      jerk: _jerk,
                      refreshChart: _refreshChart,
                      roundTrip: _roundTrip,
                      loopMove: _loopMove,
                      busy: _busy,
                      onAxisChanged: _onAxisChanged,
                      onMotorTabChanged: (v) => setState(() => _motorTab = v),
                      onGainTabChanged: (v) => setState(() => _gainTab = v),
                      onSafeTabChanged: (v) => setState(() => _safeTab = v),
                      onFieldChanged: _onParamFieldChanged,
                      onControlModeChanged: (v) =>
                          _onParamFieldChanged('control_mode', v),
                      onJogSpeedChanged: (v) =>
                          _onParamFieldChanged('speed_jog', v),
                      onSampleCountChanged: (v) => _sampleCount = v,
                      onDelayChanged: (v) => _delayMs = v,
                      onJerkChanged: (v) => _jerk = v,
                      onRefreshChartChanged: (v) =>
                          setState(() => _refreshChart = v),
                      onRoundTripChanged: (v) => setState(() => _roundTrip = v),
                      onLoopChanged: (v) => setState(() => _loopMove = v),
                      onAxisMotionFieldChanged: _onAxisMotionFieldChanged,
                      onAxisServoChanged: _onAxisServoChanged,
                      onAxisMotionChanged: _onAxisMotionChanged,
                      onReadDriver: _readDriver,
                      onWriteDriver: _writeDriver,
                      onWriteFile: _writeFile,
                      onPosRef: _posRef,
                      onSample: _sampleWaveform,
                      findPhaseButtonLabel: _live.findPhaseFlag == 1 ? '电机寻相中' : '电机寻相',
                      onFindPhase: _findPhase,
                      onSoftReset: _softReset,
                      onListSingleAxisDir: _listSingleAxisDir,
                      onLoadSingleAxisFile: _loadSingleAxisFile,
                      onSaveSingleAxisFile: _saveSingleAxisFile,
                    ),
                  ),
                  DriverWaveformPanel(
                    series: _waveSeries,
                    loading: _waveLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
