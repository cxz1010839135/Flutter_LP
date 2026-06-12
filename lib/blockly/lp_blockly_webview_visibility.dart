import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_win_floating/webview_win_floating.dart';

/// 创建 Blockly 用 WebViewController（Android 使用 Virtual Display，避免缩到左上角）。
WebViewController createBlocklyWebViewController() {
  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is AndroidWebViewPlatform) {
    params = AndroidWebViewControllerCreationParams();
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params);

  if (controller.platform is AndroidWebViewController) {
    AndroidWebViewController.enableDebugging(kDebugMode);
  }

  return controller;
}

/// Android：页面就绪后触发 Blockly 重新计算布局（WebView 初次尺寸常不准）。
Future<void> notifyBlocklyWebViewResized(WebViewController controller) async {
  if (!Platform.isAndroid) return;
  try {
    await controller.runJavaScript('''
(function() {
  try {
    var meta = document.querySelector('meta[name=viewport]');
    if (meta) {
      meta.setAttribute('content',
        'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
    }
    window.dispatchEvent(new Event('resize'));
    if (window.Blockly && Blockly.svgResize) {
      Blockly.svgResize(Blockly.getMainWorkspace());
    }
  } catch (e) {
    console.warn('notifyBlocklyWebViewResized', e);
  }
})();
''');
  } catch (e, st) {
    debugPrint('notifyBlocklyWebViewResized failed: $e\n$st');
  }
}

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

/// 在 Blockly 页弹出对话框前隐藏原生 WebView，关闭后恢复显示。
Future<T?> showBlocklyAwareDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  WebViewController? webViewController,
  bool barrierDismissible = true,
}) async {
  if (webViewController != null) {
    await setBlocklyWebViewVisible(webViewController, false);
  }

  if (!context.mounted) {
    if (webViewController != null) {
      await setBlocklyWebViewVisible(webViewController, true);
    }
    return null;
  }

  try {
    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  } finally {
    if (webViewController != null) {
      await setBlocklyWebViewVisible(webViewController, true);
    }
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
      if (widget.visible && Platform.isAndroid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyBlocklyWebViewResized(widget.controller);
        });
      }
    }
  }

  void _applyVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await setBlocklyWebViewVisible(widget.controller, widget.visible);
      if (!widget.visible && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          await setBlocklyWebViewVisible(widget.controller, false);
        }
      }
    });
  }

  Widget _buildWebViewWidget() {
    if (Platform.isAndroid) {
      final platform = widget.controller.platform;
      if (platform is AndroidWebViewController) {
        return WebViewWidget.fromPlatformCreationParams(
          params: AndroidWebViewWidgetCreationParams(
            controller: platform,
            // Hybrid Composition 在 Stack/遮罩切换后易缩到左上角并露出红底。
            displayWithHybridComposition: false,
          ),
        );
      }
    }
    return WebViewWidget(controller: widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final webView = ExcludeSemantics(
      child: SizedBox.expand(child: _buildWebViewWidget()),
    );

    if (Platform.isAndroid) {
      // 保持全屏布局尺寸，加载阶段仅透明隐藏（不用 SizedBox.shrink）。
      return IgnorePointer(
        ignoring: !widget.visible,
        child: Opacity(
          opacity: widget.visible ? 1 : 0,
          child: webView,
        ),
      );
    }

    return webView;
  }
}
