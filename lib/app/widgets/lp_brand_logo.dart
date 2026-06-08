import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import '../../core/robot_paths.dart';

/// 从 `config/imgs` 加载领鹏公司 Logo（对齐 Android `home_top_logo` / `logo_color`）
class LpBrandLogo extends StatelessWidget {
  const LpBrandLogo({
    super.key,
    this.height = 72,
    this.maxWidth = 320,
    this.fileNames,
  });

  final double height;
  final double maxWidth;

  /// 默认优先彩色 Logo（浅灰底）；顶栏可传 `[home_top_logo.png, logo_color.png]`
  final List<String>? fileNames;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: RobotPaths.findBrandLogoFile(candidates: fileNames),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            height: height,
            width: maxWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _fallback(),
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
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.precision_manufacturing, size: height * 0.6, color: LpRobotColors.primary),
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
