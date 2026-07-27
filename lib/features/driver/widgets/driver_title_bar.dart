import 'package:flutter/material.dart';

import '../../../app/lp_app_assets.dart';
import '../../../app/lp_robot_colors.dart';
import '../../../app/widgets/lp_image_press_button.dart';

/// 驱动器页顶栏（对齐 Android activity_driver.xml / wh_file_top）。
class DriverTitleBar extends StatelessWidget {
  const DriverTitleBar({
    super.key,
    required this.title,
    this.onBack,
    this.titleAlignLeft = false,
    this.showBackLabel = false,
  });

  static const double height = 44;
  static const double _sideWidth = 44;

  final String title;
  final VoidCallback? onBack;

  /// 标题靠左（地址参数页对齐图1）。
  final bool titleAlignLeft;

  /// 右侧显示「返回」文字按钮（地址参数页对齐图1）。
  final bool showBackLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LpRobotColors.driverTitleGradient,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (titleAlignLeft)
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: LpRobotColors.primary,
                    ),
                  ),
                ),
              )
            else
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: LpRobotColors.primary,
                ),
              ),
            if (onBack != null)
              Positioned(
                right: showBackLabel ? 8 : 2,
                top: 0,
                bottom: 0,
                child: showBackLabel
                    ? Center(child: _textBackButton(onBack!))
                    : SizedBox(
                        width: _sideWidth,
                        child: Center(
                          child: LpImagePressButton(
                            assetOff: LpAppAssets.backUnpressed,
                            assetOn: LpAppAssets.backPressed,
                            onTap: onBack!,
                            semanticLabel: '返回',
                            size: 36,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textBackButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0C2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: LpRobotColors.primary.withValues(alpha: 0.45)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left,
                size: 20,
                color: LpRobotColors.primary,
              ),
              Text(
                '返回',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LpRobotColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
