import 'package:flutter/material.dart';

import '../../../app/lp_app_assets.dart';
import '../../../app/lp_robot_colors.dart';
import '../../../app/widgets/lp_robot_pose_bar.dart';
import '../driver_ui_style.dart';

/// 驱动器/内页顶栏：与主页同三区比例；标题靠第二块左侧，返回在第三块。
class DriverTitleBar extends StatelessWidget {
  const DriverTitleBar({
    super.key,
    required this.title,
    this.onBack,
  });

  static const double height = 48;

  /// 与主页右侧返回区同比例。
  static const double trailingWidthFactor = LpRobotPoseBar.trailingWidthFactor;

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(LpAppAssets.neiyeTopBg),
            fit: BoxFit.fill,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            // 与 neiye-topbg 实测一致：左橙很窄，标题贴中褐左缘。
            final leadingW = w * 0.045;
            final trailingW =
                (w * trailingWidthFactor).clamp(120.0, 168.0);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: leadingW),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: DriverUiStyle.pageLabelStyle.copyWith(
                          fontSize: 18,
                          color: LpRobotColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: trailingW,
                  child: onBack == null
                      ? const SizedBox.shrink()
                      : _NeiyeTopBackButton(onTap: onBack!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 内页顶栏右侧返回：TOPBACK +「返回」（箭头与文字紧挨）。
class _NeiyeTopBackButton extends StatefulWidget {
  const _NeiyeTopBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NeiyeTopBackButton> createState() => _NeiyeTopBackButtonState();
}

class _NeiyeTopBackButtonState extends State<_NeiyeTopBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        if (!h.isFinite || h <= 0) return const SizedBox.shrink();

        final iconSize = (h * 0.44).clamp(16.0, 22.0);
        final fontSize = (h * 0.36).clamp(13.0, 17.0);

        return Semantics(
          button: true,
          label: '返回',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _pressed
                        ? LpAppAssets.homeTopBackPressed
                        : LpAppAssets.homeTopBack,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '返回',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: DriverUiStyle.fontFamily,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: LpRobotColors.textDark,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
