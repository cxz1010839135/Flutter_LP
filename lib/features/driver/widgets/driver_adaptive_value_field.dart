import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../driver_ui_style.dart';
import 'driver_numeric_input_dialog.dart';

/// 数值框：失焦后按框宽自动缩放字号（同监测区「校验计数」效果）。
///
/// Android：弹窗数字键盘，不唤起系统 IME（老平板 adjustPan 会把整页顶上去）。
/// Windows/其它：点击后行内 TextField 编辑。
class DriverAdaptiveValueField extends StatefulWidget {
  const DriverAdaptiveValueField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.signed = false,
    this.decimal = false,
    this.textAlign = TextAlign.center,
    this.style,
    this.decoration,
    this.minFontSize = 11,
    this.dialogTitle,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool signed;
  final bool decimal;
  final TextAlign textAlign;
  final TextStyle? style;
  final InputDecoration? decoration;
  final double minFontSize;
  final String? dialogTitle;

  static bool get _useAndroidNumericDialog =>
      !kIsWeb && Platform.isAndroid;

  @override
  State<DriverAdaptiveValueField> createState() =>
      _DriverAdaptiveValueFieldState();
}

class _DriverAdaptiveValueFieldState extends State<DriverAdaptiveValueField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  TextStyle get _baseStyle =>
      widget.style ?? DriverUiStyle.fieldTextStyle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    if (!DriverAdaptiveValueField._useAndroidNumericDialog) {
      _focusNode = FocusNode()..addListener(_onFocusChanged);
    } else {
      _focusNode = FocusNode();
    }
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  void didUpdateWidget(covariant DriverAdaptiveValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (_controller.text == widget.value) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
    if (_focused) {
      _focusNode.unfocus();
      setState(() => _focused = false);
    }
  }

  @override
  void dispose() {
    if (!DriverAdaptiveValueField._useAndroidNumericDialog) {
      _focusNode.removeListener(_onFocusChanged);
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAndroidDialog() async {
    if (!widget.enabled) return;
    final result = await showDriverNumericInputDialog(
      context: context,
      initialValue: _controller.text,
      title: widget.dialogTitle ?? '输入数值',
      signed: widget.signed,
      decimal: widget.decimal,
    );
    if (result == null || !mounted) return;
    _controller.text = result;
    widget.onChanged(result);
    setState(() {});
  }

  void _startInlineEdit() {
    setState(() => _focused = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  List<TextInputFormatter> get _formatters {
    if (widget.decimal) {
      return [
        FilteringTextInputFormatter.allow(
          RegExp(widget.signed ? r'-?\d*\.?\d*' : r'\d*\.?\d*'),
        ),
      ];
    }
    if (widget.signed) {
      return [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))];
    }
    return [FilteringTextInputFormatter.digitsOnly];
  }

  Widget _buildDisplayBox({
    required InputDecoration decoration,
    required VoidCallback? onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: decoration.fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
        border: Border.all(
          color: widget.enabled
              ? DriverUiStyle.boxBorderStrong
              : const Color(0xFFD0C4B8),
          width: DriverUiStyle.boxBorderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DriverUiStyle.boxRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _controller.text.isEmpty ? ' ' : _controller.text,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: widget.textAlign,
                  style: _baseStyle.copyWith(
                    color: widget.enabled
                        ? _baseStyle.color
                        : _baseStyle.color?.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decoration = (widget.decoration ??
            DriverUiStyle.fieldDecoration(enabled: widget.enabled))
        .copyWith(
      isDense: true,
      contentPadding:
          widget.decoration?.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );

    // Android：始终显示为可点数值框，弹窗输入，不弹系统键盘。
    if (DriverAdaptiveValueField._useAndroidNumericDialog) {
      return _buildDisplayBox(
        decoration: decoration,
        onTap: widget.enabled ? _openAndroidDialog : null,
      );
    }

    if (!_focused) {
      return _buildDisplayBox(
        decoration: decoration,
        onTap: widget.enabled ? _startInlineEdit : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 80.0;
        final fontSize = _fitFontSize(
          text: _controller.text,
          style: _baseStyle,
          maxWidth: maxW - 12,
          minFontSize: widget.minFontSize,
        );
        return TextField(
          enabled: widget.enabled,
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {});
          },
          onEditingComplete: () => _focusNode.unfocus(),
          onSubmitted: (_) => _focusNode.unfocus(),
          keyboardType: TextInputType.numberWithOptions(
            signed: widget.signed,
            decimal: widget.decimal,
          ),
          inputFormatters: _formatters,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          textAlign: widget.textAlign,
          style: _baseStyle.copyWith(fontSize: fontSize),
          decoration: decoration,
        );
      },
    );
  }

  static double _fitFontSize({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double minFontSize,
  }) {
    final base = style.fontSize ?? DriverUiStyle.labelFontSize;
    if (maxWidth <= 0) return minFontSize;
    final sample = text.isEmpty ? '0' : text;
    final painter = TextPainter(
      text: TextSpan(text: sample, style: style.copyWith(fontSize: base)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width <= maxWidth) return base;
    final scaled = base * maxWidth / painter.width;
    return scaled.clamp(minFontSize, base);
  }
}
