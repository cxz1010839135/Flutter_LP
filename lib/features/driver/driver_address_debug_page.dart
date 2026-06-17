import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_robot_colors.dart';
import '../../core/lp_status_log.dart';
import 'driver_address_debug_service.dart';
import 'driver_ui_style.dart';
import 'widgets/driver_title_bar.dart';

/// 地址/总线/SDO 调试（对齐 Android [DriverDebugActivity]）。
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
  final _sdoDataCtrl = TextEditingController(text: '0');

  bool _busy = false;

  static const _inputH = 34.0;
  static const _addrW = 72.0;
  static const _fieldW = 80.0;
  static const _narrowBreak = 480.0;

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
    _sdoDataCtrl.dispose();
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
      setState(() => _sdoDataCtrl.text = value);
    }, okMsg: '读取 SDO 成功');
  }

  Future<void> _writeSdo() async {
    await _run(() async {
      final axis = DriverAddressDebugService.parseInt(_sdoAxisCtrl.text);
      final index = DriverAddressDebugService.parseHex(_sdoIndexCtrl.text);
      final subIndex = DriverAddressDebugService.parseHex(_sdoSubIndexCtrl.text);
      final size = DriverAddressDebugService.parseInt(_sdoSizeCtrl.text);
      final data = DriverAddressDebugService.parseInt(_sdoDataCtrl.text);
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(
                            title: '控制参数',
                            children: [
                              _fieldRow('当前轴号', _axisCtrl),
                              _rwRow(
                                addrLabel: '当前地址',
                                addrCtrl: _readAddrCtrl,
                                valueLabel: '当前值',
                                valueCtrl: _readValueCtrl,
                                readOnlyValue: true,
                                onAction: _readDriverParam,
                                actionLabel: '读',
                              ),
                              _rwRow(
                                addrLabel: '当前地址',
                                addrCtrl: _writeAddrCtrl,
                                valueLabel: '当前值',
                                valueCtrl: _writeValueCtrl,
                                onAction: _writeDriverParam,
                                actionLabel: '写',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _section(
                            title: '总线参数',
                            children: [
                              _fieldRow('当前地址', _busAddrCtrl),
                              _rwRow(
                                valueLabel: '当前值',
                                valueCtrl: _busReadCtrl,
                                readOnlyValue: true,
                                onAction: _readBusData,
                                actionLabel: '读',
                              ),
                              _rwRow(
                                valueLabel: '当前值',
                                valueCtrl: _busWriteCtrl,
                                onAction: _writeBusData,
                                actionLabel: '写',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _section(
                            title: 'SDO参数',
                            children: [
                              _fieldRow('轴号', _sdoAxisCtrl),
                              _sdoIndexRow(),
                              _fieldRow('size', _sdoSizeCtrl),
                              _rwRow(
                                valueLabel: 'data',
                                valueCtrl: _sdoDataCtrl,
                                readOnlyValue: true,
                                onAction: _readSdo,
                                actionLabel: '读',
                              ),
                              _rwRow(
                                valueLabel: 'data',
                                valueCtrl: _sdoDataCtrl,
                                onAction: _writeSdo,
                                actionLabel: '写',
                              ),
                            ],
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
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return DecoratedBox(
      decoration: DriverUiStyle.panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: DriverUiStyle.sectionTitleStyle),
            const SizedBox(height: 10),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sdoIndexRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreak;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pairField('index', _sdoIndexCtrl, hex: true),
              const SizedBox(height: 8),
              _pairField('subindex', _sdoSubIndexCtrl, hex: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _pairField('index', _sdoIndexCtrl, hex: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pairField('subindex', _sdoSubIndexCtrl, hex: true),
            ),
          ],
        );
      },
    );
  }

  Widget _fieldRow(String label, TextEditingController controller, {bool hex = false}) {
    return _pairField(label, controller, hex: hex, fieldWidth: _fieldW);
  }

  Widget _pairField(
    String label,
    TextEditingController controller, {
    bool hex = false,
    double fieldWidth = _addrW,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: DriverUiStyle.controlLabelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: fieldWidth,
          height: _inputH,
          child: _inputBox(controller: controller, hex: hex),
        ),
      ],
    );
  }

  Widget _rwRow({
    String? addrLabel,
    TextEditingController? addrCtrl,
    bool addrHex = false,
    required String valueLabel,
    required TextEditingController valueCtrl,
    VoidCallback? onAction,
    required String actionLabel,
    bool readOnlyValue = false,
    bool valueHex = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreak;
        final addrPart = (addrLabel != null && addrCtrl != null)
            ? _pairField(addrLabel, addrCtrl, hex: addrHex)
            : null;
        final valuePart = Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                valueLabel,
                style: DriverUiStyle.controlLabelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: _inputH,
                child: _inputBox(
                  controller: valueCtrl,
                  hex: valueHex,
                  readOnly: readOnlyValue,
                  expand: true,
                ),
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(width: 8),
              _actionBtn(actionLabel, onAction),
            ],
          ],
        );

        if (narrow && addrPart != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addrPart,
              const SizedBox(height: 8),
              valuePart,
            ],
          );
        }

        if (addrPart == null) {
          return valuePart;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            addrPart,
            const SizedBox(width: 12),
            Expanded(child: valuePart),
          ],
        );
      },
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    bool hex = false,
    bool readOnly = false,
    bool expand = false,
  }) {
    final field = TextField(
      controller: controller,
      readOnly: readOnly,
      textAlign: TextAlign.center,
      style: DriverUiStyle.fieldTextStyle,
      keyboardType: hex ? TextInputType.text : TextInputType.number,
      inputFormatters: readOnly
          ? null
          : hex
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]*'))]
              : [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
      decoration: DriverUiStyle.fieldDecoration(
        compact: true,
        enabled: !readOnly,
      ),
    );
    if (expand) {
      return field;
    }
    return field;
  }

  Widget _actionBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: LpRobotColors.primary,
        side: const BorderSide(color: LpRobotColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(52, _inputH),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
