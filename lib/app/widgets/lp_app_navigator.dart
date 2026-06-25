import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 根 [Navigator] 键，供全局遮罩/断线弹窗导航使用。
final GlobalKey<NavigatorState> lpRootNavigatorKey =
    GlobalKey<NavigatorState>();

/// 桌面端 ESC 键触发返回（等同 Navigator 返回 / 关闭顶层对话框）。
/// 移动端不包裹 [Focus]，避免抢占 TextField 焦点导致软键盘无法输入。
class LpEscapeBackShortcuts extends StatelessWidget {
  const LpEscapeBackShortcuts({super.key, required this.child});

  final Widget child;

  static void _popRoute() {
    lpRootNavigatorKey.currentState?.maybePop();
  }

  static bool get _desktopEscapeEnabled =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    if (!_desktopEscapeEnabled) return child;

    return CallbackShortcuts(
      bindings: const {
        SingleActivator(LogicalKeyboardKey.escape): _popRoute,
      },
      child: child,
    );
  }
}
