import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import 'lp_blockly_bridge.dart';
import 'lp_blockly_config.dart';
import 'lp_blockly_load_tracker.dart';
import 'lp_blockly_progress_overlay.dart';
import 'lp_blockly_webview_visibility.dart';
import '../app/lp_robot_colors.dart';
import '../core/robot_path_layout.dart';
import '../core/robot_paths.dart';
import '../core/robot_state.dart';
import '../network/http_manager.dart';
import '../features/connect/connect_page.dart';
import '../features/control/project_catalog.dart';
import 'ai/lp_blockly_ai_controller.dart';
import 'ai/lp_blockly_ai_panel.dart';
import 'lp_blockly_server.dart';

/// 加载 dll 目录下领鹏 Blockly 可视化编程页面
class BlocklyDemoPage extends StatefulWidget {
  const BlocklyDemoPage({super.key, this.userProjectName});

  /// 从控制页打开时，加载 `files/projects/{name}/{name}.xml`。
  final String? userProjectName;

  @override
  State<BlocklyDemoPage> createState() => _BlocklyDemoPageState();
}

class _BlocklyDemoPageState extends State<BlocklyDemoPage> {
  LpBlocklyServer? _server;
  WebViewController? _controller;
  LpBlocklyLoadTracker? _loadTracker;
  String? _error;

  /// 页面/WebView 加载中
  bool _loading = true;

  /// 保存 / 退出上传等任务进行中
  bool _taskActive = false;

  int _progressPercent = 0;
  String _progressMessage = '正在加载…';
  String? _pathHint;
  bool _userProjectInjected = false;
  LpBlocklyAiController? _aiController;
  bool _aiPanelOpen = false;
  Timer? _refreshFallbackTimer;

  @override
  void initState() {
    super.initState();
    _initBlockly();
  }

  void _setProgress(int percent, String message, {bool? taskActive}) {
    if (!mounted) return;
    setState(() {
      _progressPercent = percent.clamp(0, 100);
      _progressMessage = message;
      if (taskActive != null) {
        _taskActive = taskActive;
      }
    });
    _scheduleWebViewVisibilitySync();
  }

  void _scheduleWebViewVisibilitySync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWebViewVisibility();
    });
  }

  /// Windows 原生 WebView 浮在 Flutter 上层，进度遮罩期间必须 hide。
  Future<void> _syncWebViewVisibility() async {
    final controller = _controller;
    if (controller == null) return;
    await setBlocklyWebViewVisible(controller, !_showProgressOverlay);
  }

  void _onLoadRequestProgress(int percent, String message) {
    if (!_loading) return;
    _setProgress(percent, message);
    if (percent >= 100) {
      _refreshFallbackTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        setState(() => _loading = false);
        _scheduleWebViewVisibilitySync();
        _ensureAiController();
        if (Platform.isAndroid) {
          final c = _controller;
          if (c != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyBlocklyWebViewResized(c);
            });
          }
        }
        await _injectUserProjectIfNeeded();
      });
    }
  }

  void _ensureAiController() {
    final controller = _controller;
    if (controller == null) return;
    if (_aiController != null) return;
    _aiController = LpBlocklyAiController(webViewController: controller)
      ..loadConfig();
    if (mounted) setState(() {});
  }

  Future<void> _refreshBlockly() async {
    final url = _server?.entryUrl;
    final controller = _controller;
    if (url == null || controller == null || _loading || _taskActive) {
      return;
    }

    _refreshFallbackTimer?.cancel();
    setState(() {
      _loading = true;
      _aiPanelOpen = false;
      _progressPercent = 8;
      _progressMessage = '正在刷新…';
    });
    _loadTracker?.reset(reload: true);
    await setBlocklyWebViewVisible(controller, false);
    _scheduleWebViewVisibilitySync();

    final base = Uri.parse(url);
    final refreshUri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'r': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    await controller.loadRequest(refreshUri);

    _refreshFallbackTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_loading) return;
      debugPrint('Blockly refresh fallback: force complete');
      _loadTracker?.markJsLoadComplete();
      _loadTracker?.complete();
    });
  }

  void _toggleAiPanel() {
    if (_showProgressOverlay) {
      _showMessage('Blockly 加载中，请稍后再打开 AI 助手');
      return;
    }
    _ensureAiController();
    if (_aiController == null) {
      _showMessage('AI 助手未就绪', isError: true);
      return;
    }
    setState(() => _aiPanelOpen = !_aiPanelOpen);
    _scheduleWebViewVisibilitySync();
  }

  Future<void> _injectUserProjectIfNeeded() async {
    if (_userProjectInjected) return;
    final name = widget.userProjectName?.trim();
    if (name == null || name.isEmpty) return;

    final controller = _controller;
    if (controller == null) return;

    try {
      final xml = await ProjectCatalog.readProjectXml(name);
      if (xml == null || xml.isEmpty) {
        _showMessage('未找到工程 $name 的 XML', isError: true);
        return;
      }
      final payload = jsonEncode(xml);
      await controller.runJavaScript('''
(function() {
  try {
    if (window.Code && typeof Code.replaceBlocksfromXml === 'function') {
      Code.replaceBlocksfromXml($payload);
    }
  } catch (e) {
    console.error('load user project failed', e);
  }
})();
''');
      _userProjectInjected = true;
      _showMessage('已加载工程 $name');
    } catch (e) {
      _showMessage('加载工程失败：$e', isError: true);
    }
  }

  void _onTaskProgress(int percent, String message) {
    if (_loading) return;

    _setProgress(percent, message, taskActive: percent < 100);

    if (percent >= 100) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || _loading) return;
        setState(() => _taskActive = false);
        _scheduleWebViewVisibilitySync();
      });
    }
  }

  Future<void> _initBlockly() async {
    setState(() {
      _loading = true;
      _taskActive = false;
      _progressPercent = 0;
      _progressMessage = '正在启动本地服务…';
    });

    try {
      if (RobotState.instance.isConnected) {
        _setProgress(5, '正在从控制器读取程序…');
        final sync = await HttpManager.instance.syncServerProgramFromRobot(
          allowEmptyControllerResponse: true,
          fallbackToEmptyOnFailure: true,
        );
        if (sync.isFullySyncedFromRobot) {
          _setProgress(12, '控制器程序已同步');
        } else {
          _setProgress(12, '控制器无程序，打开空白工程');
        }
      }

      _setProgress(12, '正在准备 Blockly 资源…');
      final serverDir = await RobotPaths.serverDir();
      final xmlDir = await RobotPaths.xmlLibraryDir();
      final dllRoot = await resolveDllRoot(
        onBootstrapProgress: (percent, message) => _setProgress(percent, message),
      );
      _setProgress(15, '正在启动本地服务…');
      _loadTracker = LpBlocklyLoadTracker(onProgress: _onLoadRequestProgress);
      _loadTracker!.reset();
      final server = LpBlocklyServer(
        serveRoot: dllRoot,
        onRequestCompleted: _loadTracker!.handleRequest,
      );
      await server.start();

      final entryUrl = server.entryUrl;
      if (entryUrl == null) {
        throw StateError('Blockly 本地服务启动失败');
      }

      _setProgress(18, '正在初始化 WebView…');
      final controller = createBlocklyWebViewController();
      final bridge = LpBlocklyBridge(
        controller: controller,
        showMessage: _showMessage,
        pickXmlFromList: _pickXmlFromLibraryDir,
        onTaskProgress: _onTaskProgress,
        onTaskStarted: _onTaskStarted,
        onJsLoadComplete: () => _loadTracker?.markJsLoadComplete(),
        onExitStarted: _onExitStarted,
        onExit: _onBlocklyExit,
      );

      // Windows/Linux：必须先挂载 WebViewWidget，再调用 controller API，
      // 否则部分机器会在 setJavaScriptMode 等处永久挂起（卡在 18%）。
      if (!mounted) return;
      setState(() {
        _pathHint = _buildPathHint();
        debugPrint('Blockly server=$serverDir xml=$xmlDir');
        _server = server;
        _controller = controller;
      });
      _ensureAiController();
      _scheduleWebViewVisibilitySync();
      await _awaitWebViewPlatformReady();

      await _configureAndLoadWebView(
        controller: controller,
        bridge: bridge,
        entryUrl: entryUrl,
      );
      _scheduleWebViewVisibilitySync();
    } catch (e, st) {
      debugPrint('Blockly init failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _taskActive = false;
      });
    }
  }

  String _buildPathHint() {
    if (RobotState.instance.isConnected) {
      return '在线 | 控制器 → ${RobotPathLayout.serverDir}';
    }
    return '离线 | ${RobotPathLayout.serverDir}';
  }

  /// 等待 [WebViewWidget] 完成首帧挂载（桌面端 WebView2 依赖此步骤）。
  Future<void> _awaitWebViewPlatformReady() async {
    await WidgetsBinding.instance.endOfFrame;
    if (Platform.isWindows || Platform.isLinux) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await WidgetsBinding.instance.endOfFrame;
    } else if (Platform.isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _configureAndLoadWebView({
    required WebViewController controller,
    required LpBlocklyBridge bridge,
    required String entryUrl,
  }) async {
    const stepTimeout = Duration(seconds: 45);

    Future<void> guard(Future<void> future, String step) {
      return future.timeout(
        stepTimeout,
        onTimeout: () {
          throw TimeoutException(
            '$step 超时。请确认本机已安装 Microsoft WebView2 运行时，'
            '或稍后点击重试。',
          );
        },
      );
    }

    await guard(
      controller.setJavaScriptMode(JavaScriptMode.unrestricted),
      'WebView 配置',
    );
    await guard(
      controller.setBackgroundColor(const Color(0xFFF5F5F5)),
      'WebView 配置',
    );
    await guard(
      controller.addJavaScriptChannel(
        'FlutterBlockly',
        onMessageReceived: (message) {
          bridge.handleMessage(message.message);
        },
      ),
      'WebView 桥接',
    );
    await guard(
      controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('Blockly WebView error: ${error.description}');
          },
          onPageFinished: (_) {
            _loadTracker?.markJsLoadComplete();
            if (Platform.isAndroid) {
              final c = controller;
              Future<void>.delayed(const Duration(milliseconds: 300), () {
                notifyBlocklyWebViewResized(c);
              });
            }
          },
        ),
      ),
      'WebView 导航',
    );

    _setProgress(5, '正在打开 Blockly 页面…');
    await guard(setBlocklyWebViewVisible(controller, false), 'WebView 显示');
    await guard(
      controller.loadRequest(Uri.parse(entryUrl)),
      '加载 Blockly 页面',
    );
  }

  void _onExitStarted() {
    _onTaskStarted();
  }

  void _onTaskStarted() {
    final msg =
        RobotState.instance.isConnected ? '正在上传程序…' : '正在保存…';
    _setProgress(0, msg, taskActive: true);
  }

  Future<void> _onBlocklyExit(BlocklyExitResult result) async {
    if (!mounted) return;

    if (result.shouldPop) {
      await _returnToHome(result.message);
      return;
    }
    setState(() => _taskActive = false);
    _scheduleWebViewVisibilitySync();
    if (result.message != null) {
      _showMessage(result.message!, isError: true);
    }
  }

  /// 在线回到主页；离线回到连接页（跳过连接时主页不在栈内，需 pushAndRemoveUntil）。
  Future<void> _returnToHome(String? message) async {
    final controller = _controller;
    if (controller != null) {
      await setBlocklyWebViewVisible(controller, false);
    }
    _server?.stop();

    if (!mounted) return;
    setState(() {
      _taskActive = false;
      _loading = false;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    if (RobotState.instance.isConnected) {
      debugPrint('Blockly: pop to MainHomePage');
      Navigator.of(context).pop(message);
      return;
    }

    debugPrint('Blockly: return to ConnectPage (offline)');
    if (message != null && message.isNotEmpty) {
      RobotState.instance.setPendingUiMessage(message);
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (_) => false,
    );
  }

  Future<void> _triggerBlocklyReturn() async {
    if (_controller == null || _showProgressOverlay) return;
    await _controller!.runJavaScript(
      "if(window.Code&&typeof Code.NewDoc==='function'){Code.NewDoc();}",
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// 原生对话框不可用时，从 files/xml 列表中选择
  Future<String?> _pickXmlFromLibraryDir(String browseDir) async {
    if (!mounted) return null;

    final dir = Directory(browseDir);
    if (!await dir.exists()) return null;

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.xml') {
        files.add(entity);
      }
    }
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    if (files.isEmpty) {
      if (mounted) {
        _showMessage(
          '${RobotPathLayout.serverDir} 下还没有 xml 文件',
          isError: true,
        );
      }
      return null;
    }

    if (!mounted) return null;
    return showBlocklyAwareDialog<String>(
      context: context,
      webViewController: _controller,
      builder: (ctx) => AlertDialog(
        title: Text('从 ${RobotPathLayout.serverDir} 加载'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                browseDir,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (_, index) {
                    final file = files[index];
                    return ListTile(
                      title: Text(p.basename(file.path)),
                      onTap: () => Navigator.pop(ctx, file.path),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshFallbackTimer?.cancel();
    _aiController?.dispose();
    _loadTracker?.dispose();
    _server?.stop();
    super.dispose();
  }

  bool get _showProgressOverlay => _loading || _taskActive;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotState.instance,
      builder: (context, _) {
        return PopScope(
          canPop: !_showProgressOverlay,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _triggerBlocklyReturn();
          },
          child: Scaffold(
          backgroundColor: LpRobotColors.background,
          appBar: AppBar(
            title: const Text('领鹏智能编程'),
            backgroundColor: LpRobotColors.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: '返回',
              onPressed: _showProgressOverlay ? null : _triggerBlocklyReturn,
            ),
            actions: [
              if (_controller != null)
                IconButton(
                  icon: Icon(
                    _aiPanelOpen
                        ? Icons.auto_awesome
                        : Icons.auto_awesome_outlined,
                  ),
                  tooltip: 'AI 编程助手',
                  onPressed: _toggleAiPanel,
                ),
              if (_controller != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: (_loading || _taskActive) ? null : _refreshBlockly,
                ),
            ],
          ),
          body: _buildBody(),
        ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorPanel(
        message: _error!,
        onRetry: () {
          setState(() {
            _error = null;
            _controller = null;
          });
          _server?.stop();
          _server = null;
          _initBlockly();
        },
      );
    }

    if (_controller == null) {
      return LpBlocklyProgressOverlay(
        progress: _progressPercent,
        message: _progressMessage,
        dimmed: false,
      );
    }

    final showAiPanel =
        _aiPanelOpen && _aiController != null && !_showProgressOverlay;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Windows 原生 WebView 浮在 Flutter 上层，必须用 Row 缩小占位而非 Stack 叠加。
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LpBlocklyWebViewHost(
                  controller: _controller!,
                  visible: !_showProgressOverlay,
                ),
              ),
              if (showAiPanel)
                LpBlocklyAiPanel(
                  controller: _aiController!,
                  onClose: () {
                    setState(() => _aiPanelOpen = false);
                    _scheduleWebViewVisibilitySync();
                  },
                ),
            ],
          ),
        ),
        if (_showProgressOverlay)
          Positioned.fill(
            child: LpBlocklyProgressOverlay(
              progress: _progressPercent,
              message: _progressMessage,
              dimmed: _taskActive,
            ),
          ),
        if (_pathHint != null && !_showProgressOverlay)
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _pathHint!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  String get _troubleshootingHint {
    final lower = message.toLowerCase();
    if (message.contains('WebView') ||
        message.contains('超时') ||
        lower.contains('timeout')) {
      return 'Windows 请安装 Microsoft WebView2 运行时（Evergreen）：\n'
          'https://developer.microsoft.com/microsoft-edge/webview2/\n\n'
          '安装后重启应用再试。';
    }
    if (Platform.isAndroid) {
      if (lower.contains('cleartext') ||
          message.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
        return 'Android 禁止加载 http:// 明文页面。\n'
            '请确认 AndroidManifest 已开启 usesCleartextTraffic，'
            '并重新安装应用。';
      }
      return 'Android 需将 Blockly 打入 APK 并在首次打开时解压。\n'
          '开发/打包前请执行：dart run tool/sync_blockly_assets.dart\n'
          '然后重新 flutter run 或 打包Android安装包.bat';
    }
    return '请确认 dll 目录位于工程根目录：\n'
        '${LpBlocklyConfig.dllRelativePath}/\n'
        '配置：${RobotPathLayout.serverDir}/\n'
        '文件：${RobotPathLayout.xmlLibraryDir}/';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: LpRobotColors.alarm,
          ),
          const SizedBox(height: 16),
          Text(
            'Blockly 加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _troubleshootingHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
