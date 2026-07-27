import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_robot_colors.dart';
import '../../core/lp_status_log.dart';
import 'driver_address_debug_service.dart';
import 'driver_ui_style.dart';
import 'widgets/driver_title_bar.dart';

/// 地址/总线/SDO 调试（比例严格对齐目标图1）。
///
/// 图1比例要点：
/// - 参数控制：左侧轴号约占 1/3，右侧地址/当前值 1:1 均分剩余，按钮贴右
/// - 总线：左侧地址与上方轴号同宽同列；当前值与上方「当前值」同列
/// - SDO：三列等分铺满，按钮贴右
class DriverAddressDebugPage extends StatefulWidget {
  const DriverAddressDebugPage({
    super.key,
    this.initialAxis = 0,
  });

  final int initialAxis;

  @override
  State<DriverAddressDebugPage> createState() => _DriverAddressDebugPageState();
}

class _DriverAddressDebugPageState extends State<DriverAddressDebugPage> {
  final _service = DriverAddressDebugService();

  final _axisCtrl = TextEditingController();
  final _readAddrCtrl = TextEditingController(text: '1');
  final _readValueCtrl = TextEditingController();
  final _writeAddrCtrl = TextEditingController(text: '1');
  final _writeValueCtrl = TextEditingController(text: '0');
  final _busAddrCtrl = TextEditingController(text: '0');
  final _busReadCtrl = TextEditingController();
  final _busWriteCtrl = TextEditingController(text: '0');
  final _sdoAxisCtrl = TextEditingController();
  final _sdoIndexCtrl = TextEditingController(text: '6060');
  final _sdoSubIndexCtrl = TextEditingController(text: '0');
  final _sdoSizeCtrl = TextEditingController(text: '32');
  final _sdoReadDataCtrl = TextEditingController();
  final _sdoWriteDataCtrl = TextEditingController(text: '0');

  bool _busy = false;

  /// 左侧栏 : 右侧内容 ≈ 1 : 2（左侧约 1/3）。
  static const _leftFlex = 1;
  static const _rightFlex = 2;
  static const _labelW = 64.0;
  static const _sdoLabelW = 70.0;
  static const _btnW = 72.0;
  static const _inputH = 40.0;
  static const _rowGap = 12.0;
  static const _cardGap = 10.0;
  static const _sideGap = 16.0;
  static const _colGap = 14.0;
  static const _readFill = Color(0xFFFFE8D4);
  static const _cardBorder = Color(0xFFFFBE7F);
  static const _ribbon = Color(0xFFFF7E1A);

  @override
  void initState() {
    super.initState();
    _axisCtrl.text = '${widget.initialAxis}';
    _sdoAxisCtrl.text = '${widget.initialAxis}';
  }

  @override
  void dispose() {
    _axisCtrl.dispose();
    _readAddrCtrl.dispose();
    _readValueCtrl.dispose();
    _writeAddrCtrl.dispose();
    _writeValueCtrl.dispose();
    _busAddrCtrl.dispose();
    _busReadCtrl.dispose();
    _busWriteCtrl.dispose();
    _sdoAxisCtrl.dispose();
    _sdoIndexCtrl.dispose();
    _sdoSubIndexCtrl.dispose();
    _sdoSizeCtrl.dispose();
    _sdoReadDataCtrl.dispose();
    _sdoWriteDataCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? okMsg}) async {
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _readDriverParam() async {
    await _run(() async {
      final axis = DriverAddressDebugService.parseInt(_axisCtrl.text);
      final addr = DriverAddressDebugService.parseInt(_readAddrCtrl.text);
      final value = await _service.readDriverParam(axis: axis, addr: addr);
      setState(() => _readValueCtrl.text = value);
    }, okMsg: '读取控制参数成功');
  }

  Future<void> _writeDriverParam() async {
    await _run(() async {
      final axis = DriverAddressDebugService.parseInt(_axisCtrl.text);
      final addr = DriverAddressDebugService.parseInt(_writeAddrCtrl.text);
      final value = DriverAddressDebugService.parseInt(_writeValueCtrl.text);
      await _service.writeDriverParam(axis: axis, addr: addr, value: value);
    }, okMsg: '写入控制参数成功');
  }

  Future<void> _readBusData() async {
    await _run(() async {
      final addr = DriverAddressDebugService.parseInt(_busAddrCtrl.text);
      final value = await _service.readBusData(addr: addr);
      setState(() => _busReadCtrl.text = value);
    }, okMsg: '读取总线参数成功');
  }

  Future<void> _writeBusData() async {
    await _run(() async {
      final addr = DriverAddressDebugService.parseInt(_busAddrCtrl.text);
      final value = DriverAddressDebugService.parseInt(_busWriteCtrl.text);
      await _service.writeBusData(addr: addr, value: value);
    }, okMsg: '写入总线参数成功');
  }

  Future<void> _readSdo() async {
    await _run(() async {
      final axis = DriverAddressDebugService.parseInt(_sdoAxisCtrl.text);
      final index = DriverAddressDebugService.parseHex(_sdoIndexCtrl.text);
      final subIndex = DriverAddressDebugService.parseHex(_sdoSubIndexCtrl.text);
      final size = DriverAddressDebugService.parseInt(_sdoSizeCtrl.text);
      final value = await _service.readSdo(
        axis: axis,
        index: index,
        subIndex: subIndex,
        dataSize: size,
      );
      setState(() => _sdoReadDataCtrl.text = value);
    }, okMsg: '读取 SDO 成功');
  }

  Future<void> _writeSdo() async {
    await _run(() async {
      final axis = DriverAddressDebugService.parseInt(_sdoAxisCtrl.text);
      final index = DriverAddressDebugService.parseHex(_sdoIndexCtrl.text);
      final subIndex = DriverAddressDebugService.parseHex(_sdoSubIndexCtrl.text);
      final size = DriverAddressDebugService.parseInt(_sdoSizeCtrl.text);
      final data = DriverAddressDebugService.parseInt(_sdoWriteDataCtrl.text);
      await _service.writeSdo(
        axis: axis,
        index: index,
        subIndex: subIndex,
        dataSize: size,
        data: data,
      );
    }, okMsg: '写入 SDO 成功');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverUiStyle.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverTitleBar(
            title: '地址参数',
            titleAlignLeft: true,
            showBackLabel: true,
            onBack: () => Navigator.of(context).pop(),
          ),
          if (_busy)
            const LinearProgressIndicator(
              color: LpRobotColors.primary,
              backgroundColor: Color(0x22FF7E1A),
            ),
          Expanded(
            child: IgnorePointer(
              ignoring: _busy,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _sectionCard(
                        title: '参数控制',
                        child: _controlSection(),
                      ),
                    ),
                    const SizedBox(height: _cardGap),
                    Expanded(
                      child: _sectionCard(
                        title: '总线参数',
                        child: _busSection(),
                      ),
                    ),
                    const SizedBox(height: _cardGap),
                    Expanded(
                      child: _sectionCard(
                        title: 'SDO参数',
                        child: _sdoSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: const BoxDecoration(
                color: _ribbon,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: _leftFlex,
          child: _labeledField('当前轴号', _axisCtrl, expand: true),
        ),
        const SizedBox(width: _sideGap),
        Expanded(
          flex: _rightFlex,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pairRow(
                addrCtrl: _readAddrCtrl,
                valueCtrl: _readValueCtrl,
                readOnlyValue: true,
                actionLabel: '读取',
                onAction: _readDriverParam,
                readStyle: true,
              ),
              const SizedBox(height: _rowGap),
              _pairRow(
                addrCtrl: _writeAddrCtrl,
                valueCtrl: _writeValueCtrl,
                actionLabel: '写入',
                onAction: _writeDriverParam,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _busSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 与参数控制左侧同 flex，地址框与轴号同宽同列。
        Expanded(
          flex: _leftFlex,
          child: _labeledField('当前地址', _busAddrCtrl, expand: true),
        ),
        const SizedBox(width: _sideGap),
        Expanded(
          flex: _rightFlex,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pairRow(
                valueCtrl: _busReadCtrl,
                readOnlyValue: true,
                actionLabel: '读取',
                onAction: _readBusData,
                readStyle: true,
              ),
              const SizedBox(height: _rowGap),
              _pairRow(
                valueCtrl: _busWriteCtrl,
                actionLabel: '写入',
                onAction: _writeBusData,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sdoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _sdoRow(
          leftLabel: '轴号',
          leftCtrl: _sdoAxisCtrl,
          midLabel: 'index',
          midCtrl: _sdoIndexCtrl,
          midHex: true,
          dataCtrl: _sdoReadDataCtrl,
          dataReadOnly: true,
          actionLabel: '读取',
          onAction: _readSdo,
          readStyle: true,
        ),
        const SizedBox(height: _rowGap),
        _sdoRow(
          leftLabel: 'size',
          leftCtrl: _sdoSizeCtrl,
          midLabel: 'subindex',
          midCtrl: _sdoSubIndexCtrl,
          midHex: true,
          dataCtrl: _sdoWriteDataCtrl,
          actionLabel: '写入',
          onAction: _writeSdo,
        ),
      ],
    );
  }

  /// 地址列 + 当前值列 1:1；总线无地址时用空列占位，保证「当前值」与上方对齐。
  Widget _pairRow({
    TextEditingController? addrCtrl,
    required TextEditingController valueCtrl,
    required String actionLabel,
    required VoidCallback onAction,
    bool readOnlyValue = false,
    bool readStyle = false,
  }) {
    final fill = readStyle ? _readFill : null;
    return Row(
      children: [
        Expanded(
          child: addrCtrl == null
              ? const SizedBox.shrink()
              : _labeledField(
                  '当前地址',
                  addrCtrl,
                  expand: true,
                  fill: fill,
                ),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            '当前值',
            valueCtrl,
            expand: true,
            readOnly: readOnlyValue,
            fill: fill,
          ),
        ),
        const SizedBox(width: 12),
        _actionBtn(actionLabel, onAction),
      ],
    );
  }

  Widget _sdoRow({
    required String leftLabel,
    required TextEditingController leftCtrl,
    required String midLabel,
    required TextEditingController midCtrl,
    required TextEditingController dataCtrl,
    required String actionLabel,
    required VoidCallback onAction,
    bool midHex = false,
    bool dataReadOnly = false,
    bool readStyle = false,
  }) {
    final fill = readStyle ? _readFill : null;
    return Row(
      children: [
        Expanded(
          child: _labeledField(
            leftLabel,
            leftCtrl,
            expand: true,
            labelWidth: _sdoLabelW,
            fill: fill,
          ),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            midLabel,
            midCtrl,
            hex: midHex,
            expand: true,
            labelWidth: _sdoLabelW,
            fill: fill,
          ),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            'data',
            dataCtrl,
            expand: true,
            labelWidth: _sdoLabelW,
            readOnly: dataReadOnly,
            fill: fill,
          ),
        ),
        const SizedBox(width: 12),
        _actionBtn(actionLabel, onAction),
      ],
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    bool hex = false,
    bool readOnly = false,
    bool expand = false,
    double labelWidth = _labelW,
    Color? fill,
  }) {
    final field = SizedBox(
      height: _inputH,
      child: _inputBox(
        controller: controller,
        hex: hex,
        readOnly: readOnly,
        fill: fill,
      ),
    );
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: DriverUiStyle.controlLabelStyle.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        if (expand) Expanded(child: field) else field,
      ],
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    bool hex = false,
    bool readOnly = false,
    Color? fill,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      textAlign: TextAlign.center,
      style: DriverUiStyle.fieldTextStyle.copyWith(fontSize: 14),
      keyboardType: hex ? TextInputType.text : TextInputType.number,
      inputFormatters: readOnly
          ? null
          : hex
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]*'))]
              : [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fill ?? (readOnly ? _readFill : Colors.white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: LpRobotColors.primary, width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: LpRobotColors.primary, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: LpRobotColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: LpRobotColors.primary.withValues(alpha: 0.55),
            width: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: _btnW,
      height: _inputH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9A45), Color(0xFFFF7E1A)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
