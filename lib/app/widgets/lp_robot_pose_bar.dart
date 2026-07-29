import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/robot_link_kind.dart';
import '../../core/robot_paths.dart';
import '../../core/robot_pose.dart';
import '../../core/robot_state.dart';
import '../../core/robot_telemetry.dart';
import '../lp_app_assets.dart';
import '../lp_app_fonts.dart';
import '../lp_robot_colors.dart';
import 'lp_image_press_button.dart';

/// 顶部位姿状态栏（对齐 Android [TopView] / layout_top.xml）。
class LpRobotPoseBar extends StatelessWidget {
  const LpRobotPoseBar({
    super.key,
    this.pageTitle,
    this.brandTitle,
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
  /// 左侧橙色区文字（有值时替代 Logo 图，如配置页显示「配置」）。
  final String? brandTitle;
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
  /// 顶栏三区宽度比（图1标注）：Logo 20.47% · 坐标 68.06% · 返回 11.47%。
  static const double _brandWidthFactor = 0.2047;
  static const double _poseWidthFactor = 0.6806;
  static const double _trailingWidthFactor = 0.1147;

  /// 整块 logo（图标+字）在橙色区内：约宽 76%、高 56%，居中。
  /// （图标注的 48% 是纯文字宽，不能直接套到含图标的整图上。）
  static const double _logoInBrandWidthFactor = 0.76;
  static const double _logoInBrandHeightFactor = 0.56;

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
            brandTitle: brandTitle,
            trailing: _ConnectionAction(
              connected: data.connected,
              onDisconnect: onDisconnect,
              onBackToConnect: onBackToConnect,
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
          showPoseRows: showPoseRows,
          brandTitle: brandTitle,
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
            // 三区：左空位 / 中标题 / 右返回（与主页分栏比例一致）。
            final trailingW =
                (constraints.maxWidth * LpRobotPoseBar._trailingWidthFactor)
                    .clamp(120.0, 168.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: trailingW),
                Expanded(
                  child: title.isEmpty
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: LpAppFonts.style(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: LpRobotColors.textDark,
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: trailingW,
                  child: onBack == null && trailing == null
                      ? const SizedBox.shrink()
                      : trailing != null
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: _SubpageTrailing(
                                onBack: onBack,
                                extra: trailing,
                              ),
                            )
                          : _NeiyePageBackButton(onTap: onBack!),
                ),
              ],
            );
          },
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
    this.brandTitle,
  });

  final _PoseBarData data;
  final double height;
  final bool showBrand;
  final bool showPoseRows;
  final Widget trailing;
  final String? brandTitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _MenuBg(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final brandW =
                showBrand ? w * LpRobotPoseBar._brandWidthFactor : 0.0;
            final trailingW = w * LpRobotPoseBar._trailingWidthFactor;
            final poseW = showPoseRows
                ? (showBrand
                    ? w * LpRobotPoseBar._poseWidthFactor
                    : (w - trailingW).clamp(0.0, w))
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBrand)
                    SizedBox(
                      width: brandW,
                      child: ClipRect(
                        child: _BrandColumn(
                          subtitle: data.subtitle,
                          connected: data.connected,
                          linkKind: data.linkKind,
                          brandTitle: brandTitle,
                        ),
                      ),
                    ),
                  if (showPoseRows)
                    SizedBox(
                      width: poseW,
                      child: ClipRect(
                        child: _PoseColumns(
                          worldPairs: data.worldPairs,
                          jointPairs: data.jointPairs,
                          live: data.connected && data.hasData,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  SizedBox(
                    width: trailingW,
                    child: trailing,
                  ),
                ],
              ),
            );
          },
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
    if (onBack == null && extra == null) return const SizedBox.shrink();

    // 与主页一致：右侧整槽使用 TOPBACK +「返回」。
    if (extra == null && onBack != null) {
      return _TopBackButton(onTap: onBack!, semanticLabel: '返回');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (extra != null) ...[
          extra!,
          const SizedBox(width: 4),
        ],
        if (onBack != null)
          Expanded(
            child: _TopBackButton(onTap: onBack!, semanticLabel: '返回'),
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
    this.brandTitle,
  });

  final String subtitle;
  final bool connected;
  final RobotLinkKind linkKind;
  final String? brandTitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final logoW = w * LpRobotPoseBar._logoInBrandWidthFactor;
        final logoH = h * LpRobotPoseBar._logoInBrandHeightFactor;
        final title = brandTitle?.trim();
        final showTitle = title != null && title.isNotEmpty;
        final showLinkRow = connected &&
            linkKind != RobotLinkKind.ethernet &&
            linkKind != RobotLinkKind.unknown;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 有 brandTitle 时显示页名；否则整块 logo 居中。
            Center(
              child: showTitle
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Text(
                          title,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (h * 0.34).clamp(16.0, 26.0),
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: logoW,
                      height: logoH,
                      child: Image.asset(
                        LpAppAssets.homeTopLogo,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, e, st) => const SizedBox.shrink(),
                      ),
                    ),
            ),
            if (showLinkRow)
              Positioned(
                left: w * 0.08,
                right: w * 0.08,
                bottom: 2,
                child: _ConnectionLinkRow(
                  linkKind: linkKind,
                  subtitle: subtitle,
                  connected: connected,
                ),
              ),
          ],
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
  final _jointScrollController = ScrollController();

  static const _cellMinWidth = 96.0;
  static const _cellGap = 2.0;
  static const _minReadableWidth = 74.0;
  static const _baseFontSize = 16.0;
  static const _minFontSize = 14.0;

  @override
  void dispose() {
    _jointScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final worldCount = widget.worldPairs.length;
        final jointCount = widget.jointPairs.length;

        // 上行 XYZWABC：固定均分，不随关节行滚动。
        final worldPerColumn =
            worldCount > 0 ? constraints.maxWidth / worldCount : constraints.maxWidth;
        final worldFontSize =
            (worldPerColumn / 5.2).clamp(_minFontSize, _baseFontSize);

        // 下行 J 轴：列多时横向拖动；上行保持不动。
        final jointGaps =
            jointCount > 1 ? (jointCount - 1) * _cellGap : 0.0;
        final jointContentWidth =
            jointCount * _cellMinWidth + jointGaps;
        final jointNeedScroll =
            jointContentWidth > constraints.maxWidth + 1 ||
            (jointCount > 0 &&
                constraints.maxWidth / jointCount < _minReadableWidth);
        final jointFontSize = jointNeedScroll
            ? _baseFontSize
            : ((jointCount > 0
                        ? constraints.maxWidth / jointCount
                        : constraints.maxWidth) /
                    5.2)
                .clamp(_minFontSize, _baseFontSize);

        final jointRow = jointNeedScroll
            ? ScrollConfiguration(
                behavior: const _PoseJointScrollBehavior(),
                child: Scrollbar(
                  controller: _jointScrollController,
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _jointScrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: SizedBox(
                      width: jointContentWidth,
                      child: _PoseInlineRow(
                        pairs: widget.jointPairs,
                        live: widget.live,
                        cellWidth: _cellMinWidth,
                        cellGap: _cellGap,
                        fontSize: jointFontSize,
                      ),
                    ),
                  ),
                ),
              )
            : _PoseInlineRow(
                pairs: widget.jointPairs,
                live: widget.live,
                cellGap: _cellGap,
                fontSize: jointFontSize,
              );

        return ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PoseInlineRow(
                  pairs: widget.worldPairs,
                  live: widget.live,
                  cellGap: _cellGap,
                  fontSize: worldFontSize,
                ),
              ),
              Expanded(child: jointRow),
            ],
          ),
        );
      },
    );
  }
}

class _PoseJointScrollBehavior extends ScrollBehavior {
  const _PoseJointScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _PoseInlineRow extends StatelessWidget {
  const _PoseInlineRow({
    required this.pairs,
    required this.live,
    required this.fontSize,
    this.cellWidth,
    this.cellGap = 2,
  });

  final List<_LabelValuePair> pairs;
  final bool live;
  final double fontSize;
  final double? cellWidth;
  final double cellGap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pairs.length; i++) ...[
          if (i > 0) SizedBox(width: cellGap),
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

  /// 切图1 top-X-BG.png 原始比例 169×48。
  static const _bgAspect = 169 / 48;

  /// 底图左侧深色标题区约占内容宽 30%（对齐切图像素分界）。
  static const _labelZoneFactor = 0.30;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        live ? LpRobotColors.liveValue : LpRobotColors.label;
    final labelStyle = LpAppFonts.style(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: LpRobotColors.textDark,
      height: 1.05,
    );
    final valueStyle = LpAppFonts.numeric(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: valueColor,
      height: 1.05,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (!maxW.isFinite || !maxH.isFinite || maxW <= 0 || maxH <= 0) {
          return const SizedBox.shrink();
        }

        // 按切图比例排格，宽高都不超出父级。
        var cellH = maxH * 0.92;
        var cellW = cellH * _bgAspect;
        if (cellW > maxW * 0.98) {
          cellW = maxW * 0.98;
          cellH = cellW / _bgAspect;
        }
        if (cellH > maxH * 0.98) {
          cellH = maxH * 0.98;
          cellW = cellH * _bgAspect;
        }

        final labelW = cellW * _labelZoneFactor;

        return Center(
          child: SizedBox(
            width: cellW,
            height: cellH,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  const _PoseAxisCellBg(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: labelW,
                        child: Align(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              // 平行四边形左边略内收，标题落在深色块内。
                              padding: EdgeInsets.only(left: cellW * 0.04),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: labelStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          // 数值靠右：左边多留空，右边给平行四边形收边。
                          padding: EdgeInsets.only(
                            left: cellW * 0.06,
                            right: cellW * 0.08,
                          ),
                          child: _HoverMarqueeValue(
                            text: value,
                            style: valueStyle,
                          ),
                        ),
                      ),
                    ],
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

/// 数值超长时默认右对齐裁切；鼠标悬停来回滚动。
class _HoverMarqueeValue extends StatefulWidget {
  const _HoverMarqueeValue({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_HoverMarqueeValue> createState() => _HoverMarqueeValueState();
}

class _HoverMarqueeValueState extends State<_HoverMarqueeValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _viewportW = 0;
  double _textW = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _HoverMarqueeValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.stop();
      _controller.value = 0;
      _textW = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startMarquee() {
    final overflow = (_textW - _viewportW).clamp(0.0, double.infinity);
    if (overflow <= 1) return;
    final seconds = (overflow / 40).clamp(1.0, 10.0);
    _controller.duration = Duration(milliseconds: (seconds * 1000).round());
    _controller.repeat(reverse: true);
  }

  void _stopMarquee() {
    _controller.stop();
    _controller.animateTo(0, duration: const Duration(milliseconds: 180));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _startMarquee(),
      onExit: (_) => _stopMarquee(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          if (!maxW.isFinite || maxW <= 0) {
            return const SizedBox.shrink();
          }

          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          _viewportW = maxW;
          _textW = painter.width;
          final overflow =
              (_textW - _viewportW).clamp(0.0, double.infinity);

          // 固定视口宽高，避免 UnconstrainedBox 把父级撑爆。
          return SizedBox(
            width: maxW,
            height: maxH.isFinite ? maxH : null,
            child: ClipRect(
              child: overflow <= 0
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: widget.style,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dx = -overflow * _controller.value;
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: dx,
                              top: 0,
                              bottom: 0,
                              width: _textW,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.text,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: widget.style,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// 坐标格底图：优先切图1 `top-X-BG.png`，再 assets。
class _PoseAxisCellBg extends StatefulWidget {
  const _PoseAxisCellBg();

  @override
  State<_PoseAxisCellBg> createState() => _PoseAxisCellBgState();
}

class _PoseAxisCellBgState extends State<_PoseAxisCellBg> {
  late final Future<File?> _fileFuture =
      RobotPaths.findMainNavImageFile('top-X-BG.png');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return Image.file(
            file,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) => _assetImage(),
          );
        }
        return _assetImage();
      },
    );
  }

  Widget _assetImage() {
    return Image.asset(
      LpAppAssets.homeTopAxisBg,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 内页（文件配置等）顶栏返回：箭头与「返回」紧挨，不影响主页/操控顶栏间距。
class _NeiyePageBackButton extends StatefulWidget {
  const _NeiyePageBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NeiyePageBackButton> createState() => _NeiyePageBackButtonState();
}

class _NeiyePageBackButtonState extends State<_NeiyePageBackButton> {
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

/// 顶栏右侧返回：TOPBACK 图标 +「返回」文案（主页/操控/点位/清零共用）。
class _TopBackButton extends StatefulWidget {
  const _TopBackButton({
    required this.onTap,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final String semanticLabel;

  /// 标注基准：图标 32.73% / 文案 59.09%；整体略左移以更协调。
  static const _iconLeftFactor = 0.22;
  static const _textLeftFactor = 0.48;
  static const _textTopFactor = 0.3564;
  static const _textBottomFactor = 0.3168;

  @override
  State<_TopBackButton> createState() => _TopBackButtonState();
}

class _TopBackButtonState extends State<_TopBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }

        final textTop = h * _TopBackButton._textTopFactor;
        final textBottom = h * _TopBackButton._textBottomFactor;
        final contentH = (h - textTop - textBottom).clamp(10.0, h);
        final iconLeft = w * _TopBackButton._iconLeftFactor;
        final textLeft = w * _TopBackButton._textLeftFactor;
        final iconSize = contentH;
        final iconTop = textTop + (contentH - iconSize) / 2;
        final fontSize = (contentH * 0.85).clamp(11.0, 18.0);

        return Semantics(
          button: true,
          label: widget.semanticLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: iconLeft,
                  top: iconTop,
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(
                    _pressed
                        ? LpAppAssets.homeTopBackPressed
                        : LpAppAssets.homeTopBack,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  left: textLeft,
                  top: textTop,
                  right: 2,
                  bottom: textBottom,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '返回',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: LpRobotColors.textDark,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return _TopBackButton(
      onTap: onTap,
      semanticLabel: connected ? '断开' : '返回连接',
    );
  }
}
