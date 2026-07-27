import 'package:flutter/material.dart';

import 'home_cut_icon_button.dart';

/// 主页左右侧栏统一排布（对齐标注比例）。
///
/// 基准标注：键间距 5.19%、顶 6.85%、底 18.1%。
/// [clusterScale] 在保持键/间距相对比例下整体放大半圈。
class HomeSideIconRail extends StatelessWidget {
  const HomeSideIconRail({
    super.key,
    required this.items,
  });

  final List<HomeSideIconItem> items;

  /// 标注：键与键之间约 5.19%。
  static const gapFactor = 0.0519;

  /// 标注：侧栏顶到首键约 6.85%。
  static const topFactor = 0.0685;

  /// 标注：末键到底约 18.1%。
  static const bottomFactor = 0.181;

  /// 键+间距整体放大半圈（约 1.28），顶/底同比例收紧。
  static const clusterScale = 1.28;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, '主页侧栏固定四键');

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // 键与间距同比例放大；顶/底按原比例瓜分剩余高度。
        final gap = maxH * gapFactor * clusterScale;
        var btnH = maxH * ((1 - topFactor - bottomFactor - gapFactor * 3) / 4) *
            clusterScale;
        final used = btnH * 4 + gap * 3;
        final marginBudget = (maxH - used).clamp(0.0, maxH);
        final marginBase = topFactor + bottomFactor;
        final top = marginBudget * (topFactor / marginBase);
        final bottom = marginBudget * (bottomFactor / marginBase);

        var btnW = btnH * HomeCutIconButton.aspect;
        if (btnW > maxW) {
          btnW = maxW;
          btnH = btnW / HomeCutIconButton.aspect;
        }

        return Padding(
          padding: EdgeInsets.only(top: top, bottom: bottom),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  SizedBox(
                    width: btnW,
                    height: btnH,
                    child: HomeCutIconButton(
                      configOffName: items[i].configOffName,
                      configOnName: items[i].configOnName,
                      assetOff: items[i].assetOff,
                      assetOn: items[i].assetOn,
                      label: items[i].label,
                      onTap: items[i].onTap,
                      forceOn: items[i].forceOn,
                      overlay: items[i].overlay,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeSideIconItem {
  const HomeSideIconItem({
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
  /// 强制显示按下态切图（如运行中「启动」用橙色图）。
  final bool forceOn;
  final Widget? overlay;
}
