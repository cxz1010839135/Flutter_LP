import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../lp_app_assets.dart';
import '../../core/robot_paths.dart';

/// 从 `config/imgs` 或内置资源加载领鹏 Logo（透明底图标，对齐 Android）。
class LpBrandLogo extends StatelessWidget {
  const LpBrandLogo({
    super.key,
    this.height = 72,
    this.maxWidth = 320,
    this.fileNames,
    this.bundledOnly = false,
  });

  final double height;
  final double maxWidth;

  /// 默认优先 `ic_launcher.png`（与打包图标一致）。
  final List<String>? fileNames;

  /// 连接页等浅底场景：始终使用内置图标，避免旧版橙底方块素材。
  final bool bundledOnly;

  static const _defaultCandidates = [
    'ic_launcher.png',
    'app_icon.png',
    'logo_color.png',
  ];

  @override
  Widget build(BuildContext context) {
    if (bundledOnly) {
      return _bundledAsset();
    }

    return FutureBuilder<File?>(
      future: RobotPaths.findBrandLogoFile(
        candidates: fileNames ?? _defaultCandidates,
      ),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            height: height,
            width: maxWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _bundledAsset(),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: height,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _bundledAsset();
      },
    );
  }

  Widget _bundledAsset() {
    return Image.asset(
      LpAppAssets.brandAppIcon,
      height: height,
      width: maxWidth,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _textFallback(),
    );
  }

  Widget _textFallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.precision_manufacturing,
          size: height * 0.6,
          color: LpRobotColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          '领鹏智能',
          style: TextStyle(
            fontSize: height * 0.28,
            fontWeight: FontWeight.bold,
            color: LpRobotColors.primary,
          ),
        ),
      ],
    );
  }
}
