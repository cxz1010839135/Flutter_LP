import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_robot_colors.dart';
import '../../core/lp_status_log.dart';
import 'driver_address_debug_service.dart';
import 'driver_ui_style.dart';
import 'widgets/driver_title_bar.dart';

/// 地址/总线/SDO 调试。
///
/// - 参数控制 / SDO：左右顶格，列均分瓜分，间隔收紧
/// - 总线参数：左对齐，不拉满
/// - 窗口缩放由全应用 LpUniformAppViewport 统一处理（铺满无留白）
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

  static const _labelW = 70.0;
  static const _sdoLabelW = 78.0;
  static const _btnW = 78.0;
  /// 对齐图一：约 51 高，整框可点。
  static const _inputH = 51.0;
  static const _labelGap = 8.0;
  static const _rowGap = 12.0;
  static const _colGap = 16.0;
  static const _cardPadH = 12.0;
  static const _cardPadV = 10.0;
  static const _cardPadHTight = 8.0;
  static const _cardPadVTight = 10.0;
  static const _busFieldW = 160.0;
  static const _labelFontSize = 15.0;
  static const _valueFontSize = 16.0;

  /// 读取行：图一浅橙底；写入行：白底。
  static const _readFill = Color(0xFFFFE8D7);
  static const _writeFill = Colors.white;
  static const _boxBorder = Color(0xFFFD7102);
  static const _boxRadius = 8.0;
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
              // 顶格铺满：左右底无外边距，避免米色留白。
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _sectionCard(
                      title: '参数控制',
                      child: _controlSection(),
                    ),
                  ),
                  Expanded(
                    child: _sectionCard(
                      title: '总线参数',
                      child: _busSection(),
                    ),
                  ),
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
          Expanded(child: child),
        ],
      ),
    );
  }

  /// 第1区：左右顶格，轴号 +（地址/当前值/按钮）瓜分。
  Widget _controlSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _cardPadHTight,
        _cardPadVTight,
        _cardPadHTight,
        _cardPadVTight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _labeledField('当前轴号', _axisCtrl)),
          const SizedBox(width: _colGap),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _fillPairRow(
                  addrCtrl: _readAddrCtrl,
                  valueCtrl: _readValueCtrl,
                  readOnlyValue: true,
                  actionLabel: '读取',
                  onAction: _readDriverParam,
                  isRead: true,
                ),
                const SizedBox(height: _rowGap),
                _fillPairRow(
                  addrCtrl: _writeAddrCtrl,
                  valueCtrl: _writeValueCtrl,
                  actionLabel: '写入',
                  onAction: _writeDriverParam,
                  isRead: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 第2区：左对齐，定宽紧凑，不拉满。
  Widget _busSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_cardPadH, _cardPadV, _cardPadH, _cardPadV),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _labelW + _labelGap + _busFieldW,
              child: _labeledField(
                '当前地址',
                _busAddrCtrl,
                inputWidth: _busFieldW,
              ),
            ),
            const SizedBox(width: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _compactValueRow(
                  valueCtrl: _busReadCtrl,
                  readOnlyValue: true,
                  actionLabel: '读取',
                  onAction: _readBusData,
                  isRead: true,
                ),
                const SizedBox(height: _rowGap),
                _compactValueRow(
                  valueCtrl: _busWriteCtrl,
                  actionLabel: '写入',
                  onAction: _writeBusData,
                  isRead: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 第3区：左右顶格，三列 + 按钮瓜分。
  Widget _sdoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _cardPadHTight,
        _cardPadVTight,
        _cardPadHTight,
        _cardPadVTight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _sdoFillRow(
            leftLabel: '轴号',
            leftCtrl: _sdoAxisCtrl,
            midLabel: 'index',
            midCtrl: _sdoIndexCtrl,
            midHex: true,
            dataCtrl: _sdoReadDataCtrl,
            dataReadOnly: true,
            actionLabel: '读取',
            onAction: _readSdo,
            isRead: true,
          ),
          const SizedBox(height: _rowGap),
          _sdoFillRow(
            leftLabel: 'size',
            leftCtrl: _sdoSizeCtrl,
            midLabel: 'subindex',
            midCtrl: _sdoSubIndexCtrl,
            midHex: true,
            dataCtrl: _sdoWriteDataCtrl,
            actionLabel: '写入',
            onAction: _writeSdo,
            isRead: false,
          ),
        ],
      ),
    );
  }

  Widget _fillPairRow({
    required TextEditingController addrCtrl,
    required TextEditingController valueCtrl,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isRead,
    bool readOnlyValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _labeledField('当前地址', addrCtrl, isRead: isRead),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            '当前值',
            valueCtrl,
            readOnly: readOnlyValue,
            isRead: isRead,
          ),
        ),
        const SizedBox(width: 10),
        _actionBtn(actionLabel, onAction),
      ],
    );
  }

  Widget _compactValueRow({
    required TextEditingController valueCtrl,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isRead,
    bool readOnlyValue = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _labelW + _labelGap + _busFieldW,
          child: _labeledField(
            '当前值',
            valueCtrl,
            inputWidth: _busFieldW,
            readOnly: readOnlyValue,
            isRead: isRead,
          ),
        ),
        const SizedBox(width: 10),
        _actionBtn(actionLabel, onAction),
      ],
    );
  }

  Widget _sdoFillRow({
    required String leftLabel,
    required TextEditingController leftCtrl,
    required String midLabel,
    required TextEditingController midCtrl,
    required TextEditingController dataCtrl,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isRead,
    bool midHex = false,
    bool dataReadOnly = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _labeledField(
            leftLabel,
            leftCtrl,
            labelWidth: _sdoLabelW,
            isRead: isRead,
          ),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            midLabel,
            midCtrl,
            hex: midHex,
            labelWidth: _sdoLabelW,
            isRead: isRead,
          ),
        ),
        const SizedBox(width: _colGap),
        Expanded(
          child: _labeledField(
            'data',
            dataCtrl,
            labelWidth: _sdoLabelW,
            readOnly: dataReadOnly,
            isRead: isRead,
          ),
        ),
        const SizedBox(width: 10),
        _actionBtn(actionLabel, onAction),
      ],
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    bool hex = false,
    bool readOnly = false,
    bool isRead = false,
    double labelWidth = _labelW,
    double? inputWidth,
  }) {
    final field = SizedBox(
      height: _inputH,
      width: inputWidth,
      child: _inputBox(
        controller: controller,
        hex: hex,
        readOnly: readOnly,
        isRead: isRead,
      ),
    );

    // 图一：标签与输入框垂直居中；同行底缘与按钮对齐（同高）。
    return SizedBox(
      height: _inputH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: _inputH,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                label,
                style: DriverUiStyle.controlLabelStyle.copyWith(
                  fontSize: _labelFontSize,
                  height: 1.1,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          if (inputWidth != null) field else Expanded(child: field),
        ],
      ),
    );
  }

  /// 整框可点；数字水平+垂直居中。
  Widget _inputBox({
    required TextEditingController controller,
    bool hex = false,
    bool readOnly = false,
    bool isRead = false,
  }) {
    final fill = isRead ? _readFill : _writeFill;
    final textColor = isRead ? _boxBorder : DriverUiStyle.valueInk;
    // 用对称 padding 把单行文字压到框正中（TextField 默认易偏上）。
    final vPad = ((_inputH - _valueFontSize) / 2).clamp(0.0, _inputH);
    return Material(
      color: fill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_boxRadius),
        side: const BorderSide(color: _boxBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _inputH,
        width: double.infinity,
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: textColor,
          style: DriverUiStyle.fieldTextStyle.copyWith(
            fontSize: _valueFontSize,
            height: 1.0,
            color: textColor,
          ),
          strutStyle: const StrutStyle(
            fontSize: _valueFontSize,
            height: 1.0,
            forceStrutHeight: true,
          ),
          keyboardType: hex ? TextInputType.text : TextInputType.number,
          inputFormatters: readOnly
              ? null
              : hex
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]*'))]
                  : [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            filled: true,
            fillColor: fill,
            hoverColor: fill,
            focusColor: fill,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: vPad,
            ),
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
          borderRadius: BorderRadius.circular(_boxRadius),
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
            borderRadius: BorderRadius.circular(_boxRadius),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: _labelFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
