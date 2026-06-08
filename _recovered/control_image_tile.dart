import 'package:flutter/material.dart';

/// 贴图按钮：导航/模式格用 [BoxFit.fill]；± 圆钮单独组件。
class ControlImageTile extends StatefulWidget {
  const ControlImageTile({
    super.key,
    required this.assetOff,
    required this.assetOn,
    required this.selected,
    this.onTap,
    this.onHighlightChanged,
    this.overlay,
    this.fit = BoxFit.fill,
  });

  final String assetOff;
  final String assetOn;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHighlightChanged;
  final Widget? overlay;
  final BoxFit fit;

  @override
  State<ControlImageTile> createState() => _ControlImageTileState();
}

class _ControlImageTileState extends State<ControlImageTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final asset = widget.selected || _pressed
        ? widget.assetOn
        : widget.assetOff;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) {
          setState(() => _pressed = v);
          widget.onHighlightChanged?.call(v);
        },
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: widget.fit,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
              if (widget.overlay != null)
                Positioned.fill(child: widget.overlay!),
            ],
          ),
        ),
      ),
    );
  }
}

/// 点动 ±：固定正方形，不随侧栏拉高（对齐 Android 50dp）。
class ControlJogImageButton extends StatefulWidget {
  const ControlJogImageButton({
    super.key,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.size = 52,
  });

  final String assetOff;
  final String assetOn;
  final VoidCallback onTap;
  final double size;

  @override
  State<ControlJogImageButton> createState() => _ControlJogImageButtonState();
}

class _ControlJogImageButtonState extends State<ControlJogImageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: Image.asset(
          _pressed ? widget.assetOn : widget.assetOff,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
