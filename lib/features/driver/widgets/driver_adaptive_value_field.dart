import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../driver_ui_style.dart';

/// 数值框：失焦后按框宽自动缩放字号（同监测区「校验计数」效果）；聚焦时可正常编辑。
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
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  void didUpdateWidget(covariant DriverAdaptiveValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focused &&
        oldWidget.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
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

    // 失焦：FittedBox 自适应显示（与校验计数一致）
    if (!_focused) {
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
            onTap: widget.enabled
                ? () {
                    setState(() => _focused = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusNode.requestFocus();
                    });
                  }
                : null,
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

    // 聚焦：可编辑；仍按宽度缩放字号，避免大数字顶出
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
