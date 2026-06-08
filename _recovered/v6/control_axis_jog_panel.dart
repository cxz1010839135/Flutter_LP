import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/lp_status_log.dart';
import '../../../core/robot_state.dart';
import '../../../core/robot_telemetry.dart';
import '../../../network/http_manager.dart';
import '../control_section.dart';
import 'control_image_tile.dart';
import 'control_mode_tile.dart';
import 'control_orange_speed_bar.dart';

class ControlAxisJogPanel extends StatefulWidget {
  const ControlAxisJogPanel({
    super.key,
    required this.axisIndex,
    required this.axisLabel,
    required this.isJointMode,
    this.maxSpeed = 2000,
    this.acceleration = 25,
  });

  final int axisIndex;
  final String axisLabel;
  final bool isJointMode;
  final double maxSpeed;
  final double acceleration;

  @override
  State<ControlAxisJogPanel> createState() => _ControlAxisJogPanelState();
}

class _ControlAxisJogPanelState extends State<ControlAxisJogPanel> {
  static const _jogBtnSize = 48.0;
  static const _jogGap = 6.0;

  final _maxSpeedCtrl = TextEditingController();
  final _accelCtrl = TextEditingController();
  final _longDistance = TextEditingController(text: '10.0');
  final _midDistance = TextEditingController(text: '1.0');
  final _shortDistance = TextEditingController(text: '0.1');

  ControlJogMode _mode = ControlJogMode.continuous;
  int _speedPercent = 50;
  bool _jogging = false;

  @override
  void initState() {
    super.initState();
    _maxSpeedCtrl.text = widget.maxSpeed.toStringAsFixed(0);
    _accelCtrl.text = widget.acceleration.toStringAsFixed(0);
    _speedPercent = RobotTelemetry.instance.speedPercentValue;
  }

  @override
  void dispose() {
    _maxSpeedCtrl.dispose();
    _accelCtrl.dispose();
    _longDistance.dispose();
    _midDistance.dispose();
    _shortDistance.dispose();
    super.dispose();
  }

  double get _maxVel => double.tryParse(_maxSpeedCtrl.text) ?? widget.maxSpeed;

  double get _minVel => _maxVel * 0.1;

  Future<void> _applySpeedPercent(int percent) async {
    final clamped = percent.clamp(1, 100);
    setState(() => _speedPercent = clamped);
    RobotTelemetry.instance.setSpeedPercentValue(clamped);
    if (!RobotState.instance.isConnected) return;
    try {
      await HttpManager.instance.setSpeedPercent(clamped / 100.0);
    } catch (e) {
      LpStatusLog.instance.warning('设置速度失败：$e');
    }
  }

  Future<void> _startJog(int dir) async {
    if (!RobotState.instance.isConnected) {
      LpStatusLog.instance.warning('请先连接控制器');
      return;
    }
    if (_jogging) return;
    _jogging = true;
    try {
      if (_mode == ControlJogMode.continuous) {
        if (widget.isJointMode) {
          await HttpManager.instance.robotJogStart(
            axis: widget.axisIndex,
            dir: dir,
            maxVel: _maxVel,
            minVel: _minVel,
          );
        } else {
          await HttpManager.instance.robotAxisStart(
            axis: widget.axisIndex,
            dir: dir,
            maxVel: _maxVel,
            minVel: _minVel,
          );
        }
      } else {
        final dis = _distanceForMode() * (dir < 0 ? -1 : 1);
        if (widget.isJointMode) {
          await HttpManager.instance.robotJogAbsMove(
            axis: widget.axisIndex,
            dis: dis,
            maxVel: _maxVel,
            minVel: _minVel,
          );
        } else {
          await HttpManager.instance.robotAxisAbsMove(
            axis: widget.axisIndex,
            dis: dis,
            maxVel: _maxVel,
            minVel: _minVel,
          );
        }
      }
    } catch (e) {
      LpStatusLog.instance.warning('点动失败：$e');
    } finally {
      _jogging = false;
    }
  }

  Future<void> _stopJog() async {
    if (!RobotState.instance.isConnected) return;
    try {
      if (widget.isJointMode) {
        await HttpManager.instance.robotJogStop(axis: widget.axisIndex);
      } else {
        await HttpManager.instance.robotAxisStop();
      }
    } catch (_) {}
  }

  double _distanceForMode() {
    final raw = switch (_mode) {
      ControlJogMode.longDistance => _longDistance.text,
      ControlJogMode.mediumDistance => _midDistance.text,
      ControlJogMode.shortDistance => _shortDistance.text,
      _ => '0',
    };
    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Expanded(child: _paramRow()),
          const SizedBox(height: 4),
          Expanded(child: _speedRow()),
          const SizedBox(height: 4),
          Expanded(child: _modeRow()),
        ],
      ),
    );
  }

  Widget _paramRow() {
    return Row(
      children: [
        _jogButton(dir: -1),
        const SizedBox(width: _jogGap),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _numField('最大速度', _maxSpeedCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _numField('加速度', _accelCtrl)),
            ],
          ),
        ),
        const SizedBox(width: _jogGap),
        _jogButton(dir: 1),
      ],
    );
  }

  Widget _speedRow() {
    return Row(
      children: [
        _jogButton(dir: -1),
        const SizedBox(width: _jogGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '速度 $_speedPercent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.label,
                ),
              ),
              Expanded(
                child: ControlOrangeSpeedBar(
                  value: _speedPercent,
                  onChanged: _applySpeedPercent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: _jogGap),
        _jogButton(dir: 1),
      ],
    );
  }

  Widget _modeRow() {
    return Row(
      children: [
        _jogButton(dir: -1),
        const SizedBox(width: _jogGap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ControlModeTile(
                  label: '连续',
                  selected: _mode == ControlJogMode.continuous,
                  onTap: () => setState(() => _mode = ControlJogMode.continuous),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ControlModeTile(
                  label: '长',
                  selected: _mode == ControlJogMode.longDistance,
                  onTap: () => setState(() => _mode = ControlJogMode.longDistance),
                  distanceController: _longDistance,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ControlModeTile(
                  label: '中',
                  selected: _mode == ControlJogMode.mediumDistance,
                  onTap: () =>
                      setState(() => _mode = ControlJogMode.mediumDistance),
                  distanceController: _midDistance,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ControlModeTile(
                  label: '短',
                  selected: _mode == ControlJogMode.shortDistance,
                  onTap: () =>
                      setState(() => _mode = ControlJogMode.shortDistance),
                  distanceController: _shortDistance,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: _jogGap),
        _jogButton(dir: 1),
      ],
    );
  }

  Widget _jogButton({required int dir}) {
    return SizedBox(
      width: _jogBtnSize,
      height: double.infinity,
      child: Listener(
        onPointerDown: (_) => _startJog(dir),
        onPointerUp: (_) => _stopJog(),
        onPointerCancel: (_) => _stopJog(),
        child: ControlImageTile(
          assetOff: ControlAssets.subtractUnpressed,
          assetOn: ControlAssets.subtractPressed,
          selected: false,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: LpRobotColors.label)),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: LpRobotColors.surfaceWarm,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }
}
