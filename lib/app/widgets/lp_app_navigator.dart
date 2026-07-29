import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 根 [Navigator] 键，供全局遮罩/断线弹窗导航使用。
final GlobalKey<NavigatorState> lpRootNavigatorKey =
    GlobalKey<NavigatorState>();

/// Blockly 编程页路由名（与 [MaterialPageRoute.settings] 一致）。
const String lpBlocklyRouteName = 'blockly_demo';

/// 当前栈顶是否为 Blockly 页。供 [MaterialApp.builder] 跳过设计稿缩放，
/// 行为对齐 v1.8.9（该版本无 UniformAppViewport）。
final ValueNotifier<bool> lpBlocklyRouteActive = ValueNotifier<bool>(false);

bool _isBlocklyRoute(Route<dynamic>? route) =>
    route?.settings.name == lpBlocklyRouteName;

/// 跟踪 Blockly 路由进出，避免 builder 里 [ModalRoute.of] 读不到栈顶路由。
class LpBlocklyRouteObserver extends NavigatorObserver {
  void _syncTop(Route<dynamic>? top) {
    final active = _isBlocklyRoute(top);
    if (lpBlocklyRouteActive.value != active) {
      lpBlocklyRouteActive.value = active;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _syncTop(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(previousRoute);
  }
}

final LpBlocklyRouteObserver lpBlocklyRouteObserver = LpBlocklyRouteObserver();

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
