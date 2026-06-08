import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_robot_pose_bar.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_state.dart';
import '../../network/http_manager.dart';
import 'clr_zero_assets.dart';
import 'clr_zero_axis_config.dart';

/// 界面清零（对齐 Android [ClrZeroActivity]，角度均为输入框）。
class ClrZeroPage extends StatefulWidget {
  const ClrZeroPage({super.key});

  @override
  State<ClrZeroPage> createState() => _ClrZeroPageState();
}

class _ClrZeroPageState extends State<ClrZeroPage> {
  static const _motorType = 'A6';

  bool _busy = false;

  final _et0 = TextEditingController();
  final _et1 = TextEditingController();
  final _et2 = TextEditingController();
  final _et3 = TextEditingController(text: '0.00');
  final _et4 = TextEditingController();
  final _et5 = TextEditingController();
  final _etGenericAxis = TextEditingController();
  final _etGeneric = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyConfigDefaults();
  }

  void _applyConfigDefaults() {
    final cfg = ClrZeroAxisConfig.forCurrentRobot();
    _et0.text = cfg.defaultEt0;
    _et1.text = cfg.defaultEt1;
    _et2.text = cfg.defaultEt2;
    _et3.text = cfg.defaultEt3;
    _et4.text = cfg.defaultEt4;
    _et5.text = cfg.defaultEt5;
    _etGenericAxis.text = cfg.defaultGenericAxis;
  }

  @override
  void dispose() {
    _et0.dispose();
    _et1.dispose();
    _et2.dispose();
    _et3.dispose();
    _et4.dispose();
    _et5.dispose();
    _etGenericAxis.dispose();
    _etGeneric.dispose();
    super.dispose();
  }

  double? _parseAngle(String text) {
    return double.tryParse(text.trim());
  }

  Future<void> _clrAxis(int axisIndex, double angle) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await HttpManager.instance.clrZero(
        axis: axisIndex,
        angle: angle,
        motorType: _motorType,
      );
      LpStatusLog.instance.success('${axisIndex + 1} 轴清零已发送');
    } catch (e) {
      LpStatusLog.instance.warning('${axisIndex + 1} 轴清零失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onAxisButton(int index) async {
    final angle = switch (index) {
      0 => _parseAngle(_et0.text),
      1 => _parseAngle(_et1.text),
      2 => _parseAngle(_et2.text),
      3 => _parseAngle(_et3.text),
      4 => _parseAngle(_et4.text),
      5 => _parseAngle(_et5.text),
      _ => null,
    };
    if (angle == null) {
      LpStatusLog.instance.warning('清零参数错误');
      return;
    }
    await _clrAxis(index, angle);
  }

  Future<void> _onGenericClr() async {
    final axisNum = int.tryParse(_etGenericAxis.text.trim());
    final angle = _parseAngle(_etGeneric.text);
    if (axisNum == null || axisNum < 1 || angle == null) {
      LpStatusLog.instance.warning('请输入有效的轴号与角度');
      return;
    }
    await _clrAxis(axisNum - 1, angle);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ClrZeroAxisConfig.forCurrentRobot();

    return Scaffold(
      backgroundColor: LpRobotColors.controlCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LpRobotPoseBar(
            pageTitle: '界面清零',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    flex: 5,
                    child: _CenterDiagram(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AxisRow(
                            title: '1 轴',
                            field: _angleField(_et0),
                            buttonLabel: '1 轴清零',
                            onPressed: _busy ? null : () => _onAxisButton(0),
                          ),
                          _AxisRow(
                            title: '2 轴',
                            field: _angleField(_et1),
                            buttonLabel: '2 轴清零',
                            onPressed: _busy ? null : () => _onAxisButton(1),
                          ),
                          _AxisRow(
                            title: '3 轴',
                            field: _angleField(_et2),
                            buttonLabel: '3 轴清零',
                            onPressed: _busy ? null : () => _onAxisButton(2),
                          ),
                          _AxisRow(
                            title: '4 轴',
                            field: _angleField(_et3),
                            buttonLabel: '4 轴清零',
                            onPressed: _busy ? null : () => _onAxisButton(3),
                          ),
                          if (cfg.showAxis5)
                            _AxisRow(
                              title: '5 轴',
                              field: _angleField(_et4),
                              buttonLabel: '5 轴清零',
                              onPressed: _busy ? null : () => _onAxisButton(4),
                            ),
                          if (cfg.showAxis6)
                            _AxisRow(
                              title: '6 轴',
                              field: _angleField(_et5),
                              buttonLabel: '6 轴清零',
                              onPressed: _busy ? null : () => _onAxisButton(5),
                            ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const SizedBox(
                                width: 44,
                                child: Text('当前轴'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _axisNumberField(_etGenericAxis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _angleField(_etGeneric, hint: '角度'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _busy ? null : _onGenericClr,
                            child: const Text('清零'),
                          ),
                        ],
                      ),
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
}

class _CenterDiagram extends StatelessWidget {
  const _CenterDiagram();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotState.instance,
      builder: (context, _) {
        final type = RobotState.instance.robotType;
        final asset = ClrZeroAssets.diagramForRobotType(type);
        final caption = RobotState.instance.displayRobotLabel;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: LpRobotColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LpRobotColors.borderWarm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.precision_manufacturing,
                          size: 96,
                          color: LpRobotColors.primary.withValues(alpha: 0.85),
                        ),
                      );
                    },
                  ),
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: LpRobotColors.label,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.title,
    required this.field,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final Widget field;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(title)),
          Expanded(child: field),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

Widget _angleField(TextEditingController controller, {String? hint}) {
  return TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
    ],
    decoration: InputDecoration(
      hintText: hint ?? '角度',
      isDense: true,
    ),
  );
}

Widget _axisNumberField(TextEditingController controller) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: const InputDecoration(
      hintText: '轴号',
      isDense: true,
    ),
  );
}
