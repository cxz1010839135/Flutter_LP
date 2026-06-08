import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 根 [Navigator] 键，供全局遮罩/断线弹窗导航使用。
final GlobalKey<NavigatorState> lpRootNavigatorKey =
    GlobalKey<NavigatorState>();

/// 桌面端 ESC 键触发返回（等同 Navigator 返回 / 关闭顶层对话框）。
class LpEscapeBackShortcuts extends StatelessWidget {
  const LpEscapeBackShortcuts({super.key, required this.child});

  final Widget child;

  static void _popRoute() {
    lpRootNavigatorKey.currentState?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: const {
        SingleActivator(LogicalKeyboardKey.escape): _popRoute,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
