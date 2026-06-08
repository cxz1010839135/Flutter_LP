import 'package:flutter/material.dart';

/// 贴图按钮：按下切换 pressed/unpressed 资源。
class LpImagePressButton extends StatefulWidget {
  const LpImagePressButton({
    super.key,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.size = 28,
    this.semanticLabel,
  });

  final String assetOff;
  final String assetOn;
  final VoidCallback onTap;
  final double size;
  final String? semanticLabel;

  @override
  State<LpImagePressButton> createState() => _LpImagePressButtonState();
}

class _LpImagePressButtonState extends State<LpImagePressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _pressed ? widget.assetOn : widget.assetOff,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: image,
        ),
      ),
    );
  }
}
