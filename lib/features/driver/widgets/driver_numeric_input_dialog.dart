import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_ui_style.dart';

/// 安卓工控平板：用弹窗数字键盘代替系统 IME，避免 adjustPan 把整页顶上去。
///
/// 输入框为只读 TextField，支持点按定位光标、按光标位置插入/删除。
/// 所有数值框均支持小数点输入。
Future<String?> showDriverNumericInputDialog({
  required BuildContext context,
  required String initialValue,
  String title = '输入数值',
  bool signed = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _DriverNumericInputDialog(
      title: title,
      initialValue: initialValue,
      signed: signed,
    ),
  );
}

class _DriverNumericInputDialog extends StatefulWidget {
  const _DriverNumericInputDialog({
    required this.title,
    required this.initialValue,
    required this.signed,
  });

  final String title;
  final String initialValue;
  final bool signed;

  @override
  State<_DriverNumericInputDialog> createState() =>
      _DriverNumericInputDialogState();
}

class _DriverNumericInputDialogState extends State<_DriverNumericInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = widget.initialValue.trim();
    _controller = TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(TextEditingValue value) {
    _controller.value = value;
    setState(() {});
  }

  void _insert(String ch) {
    final v = _controller.value;
    final text = v.text;
    final sel = v.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (ch == '.') {
      // 选区之外已含小数点则忽略。
      final outside = text.replaceRange(start, end, '');
      if (outside.contains('.')) return;
    }

    final newText = text.replaceRange(start, end, ch);
    _commit(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + ch.length),
      ),
    );
  }

  void _backspace() {
    final v = _controller.value;
    final text = v.text;
    final sel = v.selection;
    if (sel.isValid && !sel.isCollapsed) {
      final newText = text.replaceRange(sel.start, sel.end, '');
      _commit(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start),
        ),
      );
      return;
    }
    final cursor = sel.isValid ? sel.start : text.length;
    if (cursor <= 0) return;
    final newText = text.replaceRange(cursor - 1, cursor, '');
    _commit(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor - 1),
      ),
    );
  }

  void _clear() {
    _commit(
      const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
  }

  void _toggleSign() {
    final text = _controller.text;
    final hasMinus = text.startsWith('-');
    final newText = hasMinus ? text.substring(1) : '-$text';
    _commit(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  void _onKey(String k) {
    switch (k) {
      case '⌫':
        _backspace();
        break;
      case 'C':
        _clear();
        break;
      case '-':
        _toggleSign();
        break;
      default:
        _insert(k);
    }
  }

  bool _isValid() {
    final t = _controller.text.trim();
    if (t.isEmpty || t == '-' || t == '.' || t == '-.') return false;
    return double.tryParse(t) != null;
  }

  @override
  Widget build(BuildContext context) {
    final row1 = ['7', '8', '9', '⌫'];
    final row2 = ['4', '5', '6', 'C'];
    final row3 = ['1', '2', '3', if (widget.signed) '-' else ''];
    const row4 = ['0', '.', '', ''];

    List<Widget> rowWidgets(List<String> labels) {
      final cells = <Widget>[];
      for (var i = 0; i < 4; i++) {
        final k = i < labels.length ? labels[i] : '';
        cells.add(
          Expanded(
            child: k.isEmpty
                ? const SizedBox.shrink()
                : Padding(padding: const EdgeInsets.all(4), child: _keyBtn(k)),
          ),
        );
      }
      return [Row(children: cells)];
    }

    return AlertDialog(
      title: Text(widget.title, style: DriverUiStyle.labelStyle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: DriverUiStyle.valueBoxDecoration(emphasize: true),
              child: TextField(
                controller: _controller,
                readOnly: true,
                showCursor: true,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: DriverUiStyle.fieldTextStyle.copyWith(fontSize: 22),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...rowWidgets(row1),
            ...rowWidgets(row2),
            ...rowWidgets(row3),
            ...rowWidgets(row4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isValid()
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          style: FilledButton.styleFrom(backgroundColor: LpRobotColors.primary),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _keyBtn(String label) {
    final isWide = label.length > 1;
    return SizedBox(
      height: 44,
      child: Material(
        color: const Color(0xFFF5EDE4),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onKey(label),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DriverUiStyle.fontFamily,
                fontSize: isWide ? 15 : 20,
                fontWeight: FontWeight.w700,
                color: LpRobotColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
