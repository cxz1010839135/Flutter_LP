import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_canshu_assets.dart';
import '../driver_ui_style.dart';

/// 第二区外框：canshu-box1-bg + 斜切主 Tab + 内容区。
class DriverCanshuSection extends StatelessWidget {
  const DriverCanshuSection({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.child,
    this.tabsEnabled = true,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final Widget child;
  final bool tabsEnabled;

  static const _tabH = 30.0;
  static const _tabW = 118.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(DriverCanshuAssets.boxBg),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _tabH + 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  _CanshuMainTab(
                    label: '驱动器参数',
                    selected: tabIndex == 0,
                    width: _tabW,
                    height: _tabH,
                    assetOff: DriverCanshuAssets.tab1Off,
                    assetOn: DriverCanshuAssets.tab1On,
                    onTap: tabsEnabled ? () => onTabChanged(0) : null,
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _CanshuMainTab(
                      label: '波形观测',
                      selected: tabIndex == 1,
                      width: _tabW,
                      height: _tabH,
                      assetOff: DriverCanshuAssets.tab2Off,
                      assetOn: DriverCanshuAssets.tab2On,
                      onTap: tabsEnabled ? () => onTabChanged(1) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CanshuMainTab extends StatelessWidget {
  const _CanshuMainTab({
    required this.label,
    required this.selected,
    required this.width,
    required this.height,
    required this.assetOff,
    required this.assetOn,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double width;
  final double height;
  final String assetOff;
  final String assetOn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                selected ? assetOn : assetOff,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
              Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: DriverUiStyle.pageLabelStyle.copyWith(
                    fontSize: 14,
                    color: selected ? Colors.white : LpRobotColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 三列共用的标题条：titlebg + 左标题 + 右分页芯片。
class DriverCanshuPanelHeader extends StatelessWidget {
  const DriverCanshuPanelHeader({
    super.key,
    required this.title,
    required this.tabLabels,
    required this.tabIndex,
    required this.onTabChanged,
  });

  final String title;
  final List<String> tabLabels;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  /// 相对 1280 设计稿略加高，贴近标注行高观感。
  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            DriverCanshuAssets.titleBg,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DriverUiStyle.pageLabelStyle.copyWith(
                      fontSize: 14,
                      color: LpRobotColors.textDark,
                    ),
                  ),
                ),
                for (var i = 0; i < tabLabels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _HeaderTabChip(
                    label: tabLabels[i],
                    selected: tabIndex == i,
                    onTap: () => onTabChanged(i),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTabChip extends StatelessWidget {
  const _HeaderTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double size = 26;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFE0C2)
          : LpRobotColors.primary.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DriverUiStyle.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? LpRobotColors.primary : Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
