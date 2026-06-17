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
  });

  static const double height = 44;
  static const double _sideWidth = 44;

  final String title;
  final VoidCallback? onBack;

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
            Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: _sideWidth,
                child: onBack != null
                    ? Center(
                        child: LpImagePressButton(
                          assetOff: LpAppAssets.backUnpressed,
                          assetOn: LpAppAssets.backPressed,
                          onTap: onBack!,
                          semanticLabel: '返回',
                          size: 36,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
