import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_paths.dart';

/// 主页左右切图键：保持 143×157 比例，不拉伸；可叠中文标签。
class HomeCutIconButton extends StatefulWidget {
  const HomeCutIconButton({
    super.key,
    required this.configOffName,
    required this.configOnName,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.label,
    this.forceOn = false,
    this.overlay,
  });

  final String configOffName;
  final String configOnName;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;
  final String? label;
  final bool forceOn;
  final Widget? overlay;

  /// 切图原始比例。
  static const aspect = 143 / 157;

  @override
  State<HomeCutIconButton> createState() => _HomeCutIconButtonState();
}

class _HomeCutIconButtonState extends State<HomeCutIconButton> {
  late final Future<({File? off, File? on})> _filesFuture;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFiles();
  }

  Future<({File? off, File? on})> _loadFiles() async {
    final off = await RobotPaths.findMainNavImageFile(widget.configOffName);
    final on = await RobotPaths.findMainNavImageFile(widget.configOnName);
    return (off: off, on: on);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    // forceOn（如运行中启动键）保持彩色，不变灰。
    return Opacity(
      opacity: (enabled || widget.forceOn) ? 1 : 0.42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: enabled
              ? (v) => setState(() => _pressed = v)
              : null,
          child: FutureBuilder<({File? off, File? on})>(
            future: _filesFuture,
            builder: (context, snapshot) {
              final useOn = widget.forceOn || _pressed;
              final files = snapshot.data;
              final file = useOn
                  ? (files?.on ?? files?.off)
                  : files?.off;
              final asset = useOn ? widget.assetOn : widget.assetOff;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final maxH = constraints.maxHeight;
                  var w = maxW;
                  var h = w / HomeCutIconButton.aspect;
                  if (h > maxH) {
                    h = maxH;
                    w = h * HomeCutIconButton.aspect;
                  }

                  return Center(
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(file, asset),
                          if (widget.overlay != null) widget.overlay!,
                          if (widget.label != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: h * 0.08,
                              child: Text(
                                widget.label!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: (h * 0.13).clamp(11.0, 16.0),
                                  fontWeight: FontWeight.w700,
                                  color: LpRobotColors.primary,
                                  height: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImage(File? file, String asset) {
    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          asset,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) => const ColoredBox(
        color: Color(0xFFFFF0E4),
      ),
    );
  }
}
