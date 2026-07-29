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
import 'widgets/driver_canshu_section.dart';
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
  String _delayMs = '100';
  String _jerk = '1000000000';
  String _currentMaxLimit = '5';
  String _speedMaxLimit = '3000';
  String _posErrMaxLimit = '10000';
  bool _refreshChart = false;
  bool _roundTrip = false;
  bool _loopMove = false;
  bool _findPhaseRunning = false;
  bool _findPhaseCancelled = false;
  bool _loopSessionActive = false;

  /// 区域2（参数三列）相对区域2+3可用高度的占比；拖动分割条可调。
  double _midBottomSplit = 0.5;
  bool _splitDragging = false;
  double _splitDragOriginY = 0;
  double _splitDragOriginFrac = 0.5;
  double _splitUsableH = 1;

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
    _clearSelectedRowServo();
    if (mounted) setState(() {});
    await _runBusy(() async {
      await _service.writeParams(_curAxis, _model);
    }, okMsg: '写驱动参数成功！');
  }

  Future<void> _writeFile() async {
    _clearSelectedRowServo();
    if (mounted) setState(() {});
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
    final isRunning = _findPhaseRunning || _live.findPhaseFlag == 1;
    if (isRunning) {
      _findPhaseCancelled = true;
      setState(() => _findPhaseRunning = false);
      try {
        await _service.stopPhase(_curAxis);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _clearSelectedRowServo();
          setState(() {});
          _showFindPhaseTip(-2);
        }
      } catch (e) {
        LpStatusLog.instance.warning('停止寻相失败：$e');
      }
      return;
    }

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

    if (_live.servoState != 0) {
      final desc = RobotAlarmInfo.describeCode(_live.servoState);
      final msg = desc.isEmpty
          ? '${_curAxis + 1}轴存在报警代码：${_live.servoState}'
          : '${_curAxis + 1}轴存在报警代码：${_live.servoState}（$desc）';
      LpStatusLog.instance.warning(msg);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('提示'),
            content: Text(msg),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      return;
    }

    _findPhaseCancelled = false;
    setState(() => _findPhaseRunning = true);
    try {
      await _service.findPhase(_curAxis);
    } catch (e) {
      if (mounted) setState(() => _findPhaseRunning = false);
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
      return;
    }

    unawaited(_completeFindPhase());
  }

  Future<void> _completeFindPhase() async {
    final flag = await _waitFindPhaseResult();
    if (!mounted) return;
    setState(() => _findPhaseRunning = false);
    if (_findPhaseCancelled) return;
    try {
      await _service.readParams(_curAxis, _model);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } catch (_) {}
    if (!mounted || _findPhaseCancelled) return;
    _clearSelectedRowServo();
    _showFindPhaseTip(flag);
    setState(() {});
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
    if (_curAxis < 0 || _curAxis >= _axisRows.length) return;
    _axisRows[_curAxis].servoOn = false;
  }

  Future<void> _onLoopChanged(bool on) async {
    final wasOn = _loopMove;
    setState(() => _loopMove = on);
    if (wasOn && !on) {
      _loopSessionActive = false;
      try {
        await _service.stopTechLoop(chartAxis: _curAxis);
      } catch (e) {
        LpStatusLog.instance.warning('停止循环点动失败：$e');
      }
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
    final axes = <int>[];
    final pos = <int>[];
    final vel = <int>[];
    final acc = <int>[];
    final jerks = <int>[];
    final jerkVal = int.tryParse(_jerk) ?? 0;
    for (final row in _axisRows) {
      if (!row.motionOn) continue;
      axes.add(row.axisIndex);
      pos.add(int.tryParse(row.distance) ?? 0);
      vel.add(int.tryParse(row.vel) ?? 0);
      acc.add(int.tryParse(row.acc) ?? 0);
      jerks.add(jerkVal);
    }
    if (axes.isEmpty) return;
    if (_loopMove && _loopSessionActive) return;

    final loopMove = _loopMove;
    final refreshChart = _refreshChart;
    final delayMs = int.tryParse(_delayMs.trim()) ?? 0;

    Future<void> sendMove() => _service.techMove(
          returnTrip: _roundTrip ? 1 : 0,
          repeat: loopMove ? 1 : 0,
          chart: refreshChart ? 1 : 0,
          chartData: int.tryParse(_sampleCount) ?? 2000,
          chartAxis: _curAxis,
          delayMs: delayMs,
          axes: axes,
          positions: pos,
          velocities: vel,
          accs: acc,
          jerks: jerks,
        );

    try {
      if (loopMove) {
        // 循环模式：只发一次指令，不阻塞 UI（对齐安卓 repeat=1 由控制器循环）。
        await sendMove();
        _loopSessionActive = true;
        LpStatusLog.instance.success('点动指令已发送', openPanel: false);
        if (refreshChart) {
          unawaited(_fetchWaveformInBackground());
        }
        return;
      }

      await _runBusy(() async {
        await sendMove();
        if (refreshChart) {
          await _service.waitForTechDataReady();
          await _pullWaveform(switchToWaveTab: false);
        }
      }, okMsg: '点动指令已发送');
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
    }
  }

  Future<void> _fetchWaveformInBackground() async {
    try {
      await _service.waitForTechDataReady();
      await _pullWaveform(switchToWaveTab: false);
    } catch (_) {}
  }

  Future<void> _sampleWaveform() async {
    await _runBusy(() async {
      await _pullWaveform();
    });
  }

  Future<void> _pullWaveform({bool switchToWaveTab = true}) async {
    setState(() => _waveLoading = true);
    try {
      final len = int.tryParse(_sampleCount) ?? 2000;
      final data = await _service.fetchWaveformData(index: 0, len: len);
      if (!mounted) return;
      setState(() => _waveSeries = data);
      if (switchToWaveTab && _tabController.index != 1) {
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
        // 缩放由 MaterialApp 全局 LpUniformAppViewport 统一处理。
        body: DefaultTextStyle.merge(
          style: DriverUiStyle.pageLabelStyle,
          child: Column(
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
              Expanded(
                child: IgnorePointer(
                  ignoring: _busy || _exiting,
                  child: Builder(
                    builder: (context) {
                      final size = MediaQuery.sizeOf(context);
                      final padH = DriverUiStyle.pagePadH(size.width);
                      final padV = size.height * 0.004;
                      final showParams = _tabController.index == 0;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(padH, 2, padH, padV),
                        child: showParams
                            ? _buildResizableMidBottom()
                            : DriverCanshuSection(
                                tabIndex: _tabController.index,
                                tabsEnabled: !_busy && !_exiting,
                                onTabChanged: (i) {
                                  if (_tabController.index == i) return;
                                  _tabController.animateTo(i);
                                  setState(() {});
                                },
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: (_busy || _exiting)
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  children: [
                                    DriverParamsMidColumns(
                                      model: _model,
                                      motorTab: _motorTab,
                                      gainTab: _gainTab,
                                      safeTab: _safeTab,
                                      busy: _busy,
                                      onMotorTabChanged: (v) =>
                                          setState(() => _motorTab = v),
                                      onGainTabChanged: (v) =>
                                          setState(() => _gainTab = v),
                                      onSafeTabChanged: (v) =>
                                          setState(() => _safeTab = v),
                                      onFieldChanged: _onParamFieldChanged,
                                    ),
                                    DriverWaveformPanel(
                                      series: _waveSeries,
                                      loading: _waveLoading,
                                    ),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 区域2 / 区域3 可上下拖动拉伸。
  Widget _buildResizableMidBottom() {
    // 命中区略高，视觉条仍细，跟手用按下时的全局坐标绝对换算。
    const handleH = 14.0;
    const minFrac = 0.28;
    const maxFrac = 0.72;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxHeight;
        final usable = (total - handleH).clamp(1.0, double.infinity);
        _splitUsableH = usable;
        final frac = _midBottomSplit.clamp(minFrac, maxFrac);
        final topH = usable * frac;
        final bottomH = usable - topH;

        void applySplitFromGlobalY(double globalY) {
          final dy = globalY - _splitDragOriginY;
          final next =
              (_splitDragOriginFrac + dy / _splitUsableH).clamp(minFrac, maxFrac);
          if ((next - _midBottomSplit).abs() < 0.0001) return;
          setState(() => _midBottomSplit = next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: topH,
              child: DriverCanshuSection(
                tabIndex: _tabController.index,
                tabsEnabled: !_busy && !_exiting,
                onTabChanged: (i) {
                  if (_tabController.index == i) return;
                  _tabController.animateTo(i);
                  setState(() {});
                },
                child: TabBarView(
                  controller: _tabController,
                  physics: (_busy || _exiting)
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    DriverParamsMidColumns(
                      model: _model,
                      motorTab: _motorTab,
                      gainTab: _gainTab,
                      safeTab: _safeTab,
                      busy: _busy,
                      onMotorTabChanged: (v) =>
                          setState(() => _motorTab = v),
                      onGainTabChanged: (v) =>
                          setState(() => _gainTab = v),
                      onSafeTabChanged: (v) =>
                          setState(() => _safeTab = v),
                      onFieldChanged: _onParamFieldChanged,
                    ),
                    DriverWaveformPanel(
                      series: _waveSeries,
                      loading: _waveLoading,
                    ),
                  ],
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (d) {
                  _splitDragging = true;
                  _splitDragOriginY = d.globalPosition.dy;
                  _splitDragOriginFrac = frac;
                },
                onVerticalDragUpdate: (d) {
                  if (!_splitDragging) return;
                  applySplitFromGlobalY(d.globalPosition.dy);
                },
                onVerticalDragEnd: (_) => _splitDragging = false,
                onVerticalDragCancel: () => _splitDragging = false,
                child: SizedBox(
                  height: handleH,
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LpRobotColors.borderWarm.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: bottomH,
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
                onRoundTripChanged: (v) =>
                    setState(() => _roundTrip = v),
                onLoopChanged: _onLoopChanged,
                onAxisMotionFieldChanged: _onAxisMotionFieldChanged,
                onAxisServoChanged: _onAxisServoChanged,
                onAxisMotionChanged: _onAxisMotionChanged,
                onReadDriver: _readDriver,
                onWriteDriver: _writeDriver,
                onWriteFile: _writeFile,
                onPosRef: _posRef,
                onSample: _sampleWaveform,
                findPhaseActive:
                    _findPhaseRunning || _live.findPhaseFlag == 1,
                findPhaseButtonLabel:
                    _findPhaseRunning || _live.findPhaseFlag == 1
                        ? '电机寻相中'
                        : '电机寻相',
                onFindPhase: _findPhase,
                onSoftReset: _softReset,
                onListSingleAxisDir: _listSingleAxisDir,
                onLoadSingleAxisFile: _loadSingleAxisFile,
                onSaveSingleAxisFile: _saveSingleAxisFile,
              ),
            ),
          ],
        );
      },
    );
  }
}
