import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';

/// Windows/Linux 下 [WebViewWidget] 为原生浮层，Flutter Stack 遮罩盖不住。
/// 加载/保存进度期间需调用 [setBlocklyWebViewVisible] 隐藏原生 WebView。
Future<void> setBlocklyWebViewVisible(
  WebViewController controller,
  bool visible,
) async {
  if (!Platform.isWindows && !Platform.isLinux) return;

  try {
    final platform = controller.platform;
    if (platform is WindowsPlatformWebViewController) {
      await platform.controller.setVisibility(visible);
    }
  } catch (e, st) {
    debugPrint('setBlocklyWebViewVisible failed: $e\n$st');
  }
}

/// 挂载 [WebViewWidget] 后 WinWebView 会 _resume() 重新显示，需在每帧同步 visible。
class LpBlocklyWebViewHost extends StatefulWidget {
  const LpBlocklyWebViewHost({
    super.key,
    required this.controller,
    required this.visible,
  });

  final WebViewController controller;
  final bool visible;

  @override
  State<LpBlocklyWebViewHost> createState() => _LpBlocklyWebViewHostState();
}

class _LpBlocklyWebViewHostState extends State<LpBlocklyWebViewHost> {
  @override
  void initState() {
    super.initState();
    _applyVisibility();
  }

  @override
  void didUpdateWidget(LpBlocklyWebViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _applyVisibility();
    }
  }

  void _applyVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await setBlocklyWebViewVisible(widget.controller, widget.visible);
      // WinWebViewWidget.initState 内 _resume() 可能在首帧后再显示，再压一次
      if (!widget.visible && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          await setBlocklyWebViewVisible(widget.controller, false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: widget.controller);
  }
}
