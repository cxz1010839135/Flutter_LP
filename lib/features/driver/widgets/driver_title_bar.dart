import 'package:flutter/material.dart';

import '../../../app/lp_app_assets.dart';
import '../../../app/lp_robot_colors.dart';
import '../driver_ui_style.dart';

/// 驱动器/内页顶栏：neiye-topbg 背景，左空 / 中标题 / 右返回（与主页三区分栏一致）。
class DriverTitleBar extends StatelessWidget {
  const DriverTitleBar({
    super.key,
    required this.title,
    this.onBack,
  });

  static const double height = 48;

  /// 与主页右侧返回区同比例。
  static const double trailingWidthFactor = 0.1147;

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
            final trailingW =
                (w * trailingWidthFactor).clamp(120.0, 168.0);
            // 左侧占位与右侧同宽，保证中间标题视觉居中；内容暂空。
            final leadingW = trailingW;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: leadingW),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: DriverUiStyle.pageLabelStyle.copyWith(
                        fontSize: 18,
                        color: LpRobotColors.textDark,
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
