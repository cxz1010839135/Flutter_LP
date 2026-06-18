import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/robot_link_kind.dart';
import '../../core/robot_pose.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_app_assets.dart';
import '../lp_robot_colors.dart';
import 'lp_image_press_button.dart';

/// 顶部位姿状态栏（对齐 Android [TopView] / layout_top.xml）。
class LpRobotPoseBar extends StatelessWidget {
  const LpRobotPoseBar({
    super.key,
    this.pageTitle,
    this.onBack,
    this.trailing,
    this.showPoseRows = true,
    this.titleBarOnly = false,
    this.titleBarLeadingBack = false,
    this.showConnectionActions = false,
    this.onDisconnect,
    this.onBackToConnect,
  });

  final String? pageTitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showPoseRows;
  /// 仅标题 + 返回（对齐 Android ConfigFileActivity，无 Logo/坐标）。
  final bool titleBarOnly;
  /// [titleBarOnly] 时：返回在左、标题靠右（对齐 Android DriverActivity）。
  final bool titleBarLeadingBack;
  final bool showConnectionActions;
  final VoidCallback? onDisconnect;
  final VoidCallback? onBackToConnect;

  static const double _barHeight = 82;
  /// 品牌区左内边距（Logo/铭牌尽量靠左，坐标区紧随其后）。
  static const double _brandInsetLeft = 8;
  /// 顶栏品牌区 : 坐标区 宽度比（对齐 Android TopView 约 5:12）。
  static const int _brandFlex = 5;
  static const int _poseFlex = 12;
  /// Logo 相对顶栏内高的占比（略小于满高，避免左上角过于抢眼）。
  static const double _logoHeightFactor = 0.62;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotState.instance,
        RobotTelemetry.instance,
      ]),
      builder: (context, _) {
        final data = _PoseBarData.from(
          state: RobotState.instance,
          telemetry: RobotTelemetry.instance,
        );

        if (showConnectionActions) {
          return _UnifiedTopBar(
            data: data,
            height: _barHeight,
            showBrand: true,
            showPoseRows: true,
            trailing: Center(
              child: _ConnectionAction(
                connected: data.connected,
                onDisconnect: onDisconnect,
                onBackToConnect: onBackToConnect,
              ),
            ),
          );
        }

        if (titleBarOnly) {
          return _PageTitleBar(
            title: pageTitle ?? '',
            onBack: onBack,
            trailing: trailing,
            leadingBack: titleBarLeadingBack,
          );
        }

        return _UnifiedTopBar(
          data: data,
          height: _barHeight,
          showBrand: true,
          showPoseRows: true,
          trailing: _SubpageTrailing(onBack: onBack, extra: trailing),
        );
      },
    );
  }
}

class _LabelValuePair {
  const _LabelValuePair({required this.label, required this.value});

  final String label;
  final String value;
}

class _PoseBarData {
  const _PoseBarData({
    required this.connected,
    required this.hasData,
    required this.subtitle,
    required this.linkKind,
    required this.worldPairs,
    required this.jointPairs,
  });

  final bool connected;
  final bool hasData;
  final String subtitle;
  final RobotLinkKind linkKind;
  final List<_LabelValuePair> worldPairs;
  final List<_LabelValuePair> jointPairs;

  factory _PoseBarData.from({
    required RobotState state,
    required RobotTelemetry telemetry,
  }) {
    final pose = telemetry.pose;
    final axisCount =
        telemetry.displayAxisCount.clamp(1, RobotPoseSnapshot.maxJoints);
    final connected = state.isConnected;

    final worldCount = RobotPoseSnapshot.topBarWorldCount(axisCount);
    final worldPairs = <_LabelValuePair>[
      for (var i = 0; i < worldCount; i++)
        _LabelValuePair(
          label: '${RobotPoseSnapshot.worldLabels[i]}:',
          value: _formatValue(
            pose.worldValues[i],
            connected: connected,
            hasData: pose.hasData,
          ),
        ),
    ];

    final jointPairs = <_LabelValuePair>[
      for (var i = 0; i < axisCount; i++)
        _LabelValuePair(
          label: 'J${i + 1}:',
          value: _formatValue(
            i < pose.joints.length ? pose.joints[i] : 0,
            connected: connected,
            hasData: pose.hasData,
          ),
        ),
    ];

    return _PoseBarData(
      connected: connected,
      hasData: pose.hasData,
      subtitle: _connectionSubtitle(state),
      linkKind: state.linkKind,
      worldPairs: worldPairs,
      jointPairs: jointPairs,
    );
  }

  static String _formatValue(
    double value, {
    required bool connected,
    required bool hasData,
  }) {
    if (!connected || !hasData) return '—';
    return value.toStringAsFixed(4);
  }

  static String _connectionSubtitle(RobotState state) {
    final sn = state.robotSerialNumber.trim();
    if (sn.isNotEmpty) return sn;
    try {
      return Uri.parse(state.serverBaseUrl).host;
    } catch (_) {
      return state.serverBaseUrl;
    }
  }
}

/// 向导/配置页顶栏：居中标题 + 右侧返回（与其他子页一致）。
class _PageTitleBar extends StatelessWidget {
  const _PageTitleBar({
    required this.title,
    required this.onBack,
    required this.trailing,
    this.leadingBack = false,
  });

  static const double height = 48;

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool leadingBack;

  @override
  Widget build(BuildContext context) {
    if (leadingBack) {
      return SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: LpRobotColors.driverTitleGradient),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  if (onBack != null)
                    LpImagePressButton(
                      assetOff: LpAppAssets.backUnpressed,
                      assetOn: LpAppAssets.backPressed,
                      onTap: onBack!,
                      semanticLabel: '返回',
                      size: 36,
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: LpRobotColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    const sideWidth = 40.0;
    return SizedBox(
      height: height,
      child: _MenuBg(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: sideWidth),
              Expanded(
                child: title.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: LpRobotColors.primary,
                        ),
                      ),
              ),
              SizedBox(
                width: sideWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _SubpageTrailing(onBack: onBack, extra: trailing),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主页/子页统一顶栏：可选 Logo 区 + 坐标 + 右侧操作区。
class _UnifiedTopBar extends StatelessWidget {
  const _UnifiedTopBar({
    required this.data,
    required this.height,
    required this.showBrand,
    required this.showPoseRows,
    required this.trailing,
  });

  final _PoseBarData data;
  final double height;
  final bool showBrand;
  final bool showPoseRows;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _MenuBg(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LpRobotPoseBar._brandInsetLeft,
            1,
            4,
            2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBrand)
                Expanded(
                  flex: LpRobotPoseBar._brandFlex,
                  child: ClipRect(
                    child: _BrandColumn(
                      subtitle: data.subtitle,
                      connected: data.connected,
                      linkKind: data.linkKind,
                    ),
                  ),
                ),
              if (showPoseRows)
                Expanded(
                  flex: showBrand ? LpRobotPoseBar._poseFlex : 1,
                  child: _PoseColumns(
                    worldPairs: data.worldPairs,
                    jointPairs: data.jointPairs,
                    live: data.connected && data.hasData,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubpageTrailing extends StatelessWidget {
  const _SubpageTrailing({required this.onBack, required this.extra});

  final VoidCallback? onBack;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ?extra,
        if (onBack != null)
          LpImagePressButton(
            assetOff: LpAppAssets.backUnpressed,
            assetOn: LpAppAssets.backPressed,
            onTap: onBack!,
            semanticLabel: '返回',
            size: 36,
          ),
      ],
    );
  }
}

class _MenuBg extends StatelessWidget {
  const _MenuBg({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(LpAppAssets.homeTopMenuBg),
          fit: BoxFit.fill,
        ),
      ),
      child: child,
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({
    required this.subtitle,
    required this.connected,
    required this.linkKind,
  });

  final String subtitle;
  final bool connected;
  final RobotLinkKind linkKind;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoHeight = (constraints.maxHeight * LpRobotPoseBar._logoHeightFactor)
            .clamp(38.0, 48.0);
        final showLinkRow = connected &&
            linkKind != RobotLinkKind.ethernet &&
            linkKind != RobotLinkKind.unknown;
        return Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: logoHeight,
                    child: Image.asset(
                      LpAppAssets.homeTopLogo,
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, e, st) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              if (showLinkRow) ...[
                const SizedBox(height: 2),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _ConnectionLinkRow(
                    linkKind: linkKind,
                    subtitle: subtitle,
                    connected: connected,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 链路行：有线显示「以太网」，无线显示 Wi‑Fi 图标 + 序列号/IP。
class _ConnectionLinkRow extends StatelessWidget {
  const _ConnectionLinkRow({
    required this.linkKind,
    required this.subtitle,
    required this.connected,
  });

  final RobotLinkKind linkKind;
  final String subtitle;
  final bool connected;

  static const _textStyle = TextStyle(
    fontSize: 11,
    color: Colors.white,
    fontWeight: FontWeight.w600,
    height: 1.05,
  );

  static const _iconSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          LpAppAssets.iconWifi,
          width: _iconSize,
          height: _iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, e, st) => Icon(
            Icons.wifi,
            size: _iconSize,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle,
          ),
        ),
      ],
    );
  }
}

class _PoseColumns extends StatefulWidget {
  const _PoseColumns({
    required this.worldPairs,
    required this.jointPairs,
    required this.live,
  });

  final List<_LabelValuePair> worldPairs;
  final List<_LabelValuePair> jointPairs;
  final bool live;

  @override
  State<_PoseColumns> createState() => _PoseColumnsState();
}

class _PoseColumnsState extends State<_PoseColumns> {
  final _scrollController = ScrollController();

  static const _cellMinWidth = 96.0;
  static const _minReadableWidth = 74.0;
  static const _baseFontSize = 16.0;
  static const _minFontSize = 14.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = math.max(
          widget.worldPairs.length,
          widget.jointPairs.length,
        );
        final contentWidth = columnCount * _cellMinWidth;
        final perColumn = columnCount > 0
            ? constraints.maxWidth / columnCount
            : constraints.maxWidth;
        final needScroll =
            contentWidth > constraints.maxWidth + 1 ||
            perColumn < _minReadableWidth;
        final fontSize = needScroll
            ? _baseFontSize
            : (perColumn / 5.2).clamp(_minFontSize, _baseFontSize);

        Widget rows({double? cellWidth}) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PoseInlineRow(
                  pairs: widget.worldPairs,
                  live: widget.live,
                  cellWidth: cellWidth,
                  fontSize: fontSize,
                ),
              ),
              Expanded(
                child: _PoseInlineRow(
                  pairs: widget.jointPairs,
                  live: widget.live,
                  cellWidth: cellWidth,
                  fontSize: fontSize,
                ),
              ),
            ],
          );
        }

        if (!needScroll) {
          return rows();
        }

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: rows(cellWidth: _cellMinWidth),
            ),
          ),
        );
      },
    );
  }
}

class _PoseInlineRow extends StatelessWidget {
  const _PoseInlineRow({
    required this.pairs,
    required this.live,
    required this.fontSize,
    this.cellWidth,
  });

  final List<_LabelValuePair> pairs;
  final bool live;
  final double fontSize;
  final double? cellWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pairs.length; i++)
          if (cellWidth != null)
            SizedBox(
              width: cellWidth,
              child: _PoseInlineCell(
                label: pairs[i].label,
                value: pairs[i].value,
                live: live,
                fontSize: fontSize,
              ),
            )
          else
            Expanded(
              child: _PoseInlineCell(
                label: pairs[i].label,
                value: pairs[i].value,
                live: live,
                fontSize: fontSize,
              ),
            ),
      ],
    );
  }
}

class _PoseInlineCell extends StatelessWidget {
  const _PoseInlineCell({
    required this.label,
    required this.value,
    required this.live,
    required this.fontSize,
  });

  final String label;
  final String value;
  final bool live;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        live ? LpRobotColors.liveValue : LpRobotColors.label;
    final labelStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: LpRobotColors.textDark,
      height: 1.05,
    );
    final valueStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      fontFamily: 'Consolas',
      color: valueColor,
      height: 1.05,
    );

    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label, style: labelStyle),
            TextSpan(text: value, style: valueStyle),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}

class _ConnectionAction extends StatelessWidget {
  const _ConnectionAction({
    required this.connected,
    required this.onDisconnect,
    required this.onBackToConnect,
  });

  final bool connected;
  final VoidCallback? onDisconnect;
  final VoidCallback? onBackToConnect;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap;
    if (connected && onDisconnect != null) {
      onTap = onDisconnect;
    } else if (!connected && onBackToConnect != null) {
      onTap = onBackToConnect;
    } else {
      onTap = null;
    }
    if (onTap == null) return const SizedBox.shrink();

    return LpImagePressButton(
      assetOff: LpAppAssets.backUnpressed,
      assetOn: LpAppAssets.backPressed,
      onTap: onTap,
      semanticLabel: connected ? '断开' : '返回连接',
      size: 36,
    );
  }
}
