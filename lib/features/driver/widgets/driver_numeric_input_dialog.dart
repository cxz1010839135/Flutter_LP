import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_ui_style.dart';

/// 安卓工控平板：用弹窗数字键盘代替系统 IME，避免 adjustPan 把整页顶上去。
Future<String?> showDriverNumericInputDialog({
  required BuildContext context,
  required String initialValue,
  String title = '输入数值',
  bool signed = false,
  bool decimal = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _DriverNumericInputDialog(
      title: title,
      initialValue: initialValue,
      signed: signed,
      decimal: decimal,
    ),
  );
}

class _DriverNumericInputDialog extends StatefulWidget {
  const _DriverNumericInputDialog({
    required this.title,
    required this.initialValue,
    required this.signed,
    required this.decimal,
  });

  final String title;
  final String initialValue;
  final bool signed;
  final bool decimal;

  @override
  State<_DriverNumericInputDialog> createState() =>
      _DriverNumericInputDialogState();
}

class _DriverNumericInputDialogState extends State<_DriverNumericInputDialog> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.initialValue.trim();
  }

  void _append(String ch) {
    setState(() {
      if (ch == '-' && widget.signed) {
        if (_text.startsWith('-')) {
          _text = _text.substring(1);
        } else {
          _text = '-$_text';
        }
        return;
      }
      if (ch == '.' && widget.decimal) {
        if (_text.contains('.')) return;
        if (_text.isEmpty || _text == '-') {
          _text = '${_text}0.';
        } else {
          _text = '$_text.';
        }
        return;
      }
      if (ch == '⌫') {
        if (_text.isNotEmpty) {
          _text = _text.substring(0, _text.length - 1);
        }
        return;
      }
      if (ch == 'C') {
        _text = '';
        return;
      }
      _text = '$_text$ch';
    });
  }

  bool _isValid() {
    final t = _text.trim();
    if (t.isEmpty || t == '-' || t == '.' || t == '-.') return false;
    return double.tryParse(t) != null;
  }

  @override
  Widget build(BuildContext context) {
    final row1 = ['7', '8', '9', '⌫'];
    final row2 = ['4', '5', '6', 'C'];
    final row3 = [
      '1',
      '2',
      '3',
      if (widget.signed) '-' else '',
    ];
    final row4 = [
      '0',
      if (widget.decimal) '.' else '',
      '',
      '',
    ];

    List<Widget> rowWidgets(List<String> labels) {
      final cells = <Widget>[];
      for (var i = 0; i < 4; i++) {
        final k = i < labels.length ? labels[i] : '';
        cells.add(
          Expanded(
            child: k.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(4),
                    child: _keyBtn(k),
                  ),
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: DriverUiStyle.valueBoxDecoration(emphasize: true),
              alignment: Alignment.center,
              child: Text(
                _text.isEmpty ? ' ' : _text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DriverUiStyle.fieldTextStyle.copyWith(fontSize: 22),
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
              ? () => Navigator.pop(context, _text.trim())
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: LpRobotColors.primary,
          ),
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
          onTap: () => _append(label),
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
