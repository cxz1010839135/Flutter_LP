import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/robot_paths.dart';
import '../../control/widgets/control_image_tile.dart';

/// 主页左侧导航键：优先 `config/imgs`，否则内置 assets；贴图已含图标与文案。
class HomeNavButton extends StatefulWidget {
  const HomeNavButton({
    super.key,
    required this.configOffName,
    required this.configOnName,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
    this.borderRadius = 14,
  });

  final String configOffName;
  final String configOnName;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<HomeNavButton> createState() => _HomeNavButtonState();
}

class _HomeNavButtonState extends State<HomeNavButton> {
  late final Future<({File? off, File? on})> _filesFuture;

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
    return FutureBuilder<({File? off, File? on})>(
      future: _filesFuture,
      builder: (context, snapshot) {
        final files = snapshot.data;
        final tile = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: _NavImageTile(
            offFile: files?.off,
            onFile: files?.on,
            assetOff: widget.assetOff,
            assetOn: widget.assetOn,
            onTap: widget.onTap,
          ),
        );
        if (widget.onTap != null) return tile;
        return Opacity(opacity: 0.42, child: tile);
      },
    );
  }
}

class _NavImageTile extends StatefulWidget {
  const _NavImageTile({
    required this.offFile,
    required this.onFile,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
  });

  final File? offFile;
  final File? onFile;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;

  @override
  State<_NavImageTile> createState() => _NavImageTileState();
}

class _NavImageTileState extends State<_NavImageTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.offFile == null &&
        widget.onFile == null &&
        widget.onTap != null) {
      return ControlImageTile(
        assetOff: widget.assetOff,
        assetOn: widget.assetOn,
        selected: false,
        fit: BoxFit.fill,
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
      );
    }

    final useOn = _pressed && widget.onTap != null;
    final asset = useOn ? widget.assetOn : widget.assetOff;
    final file = useOn ? (widget.onFile ?? widget.offFile) : widget.offFile;

    Widget image;
    if (file != null) {
      image = Image.file(
        file,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          asset,
          fit: BoxFit.fill,
          gaplessPlayback: true,
        ),
      );
    } else {
      image = Image.asset(
        asset,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged:
            widget.onTap != null ? (v) => setState(() => _pressed = v) : null,
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          child: Center(child: image),
        ),
      ),
    );
  }
}
