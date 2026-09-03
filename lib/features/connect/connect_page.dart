import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_app_assets.dart';
import '../../app/lp_app_fonts.dart';
import '../../app/lp_robot_colors.dart';
import '../../core/app_info.dart';
import '../../core/local_app_settings.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_connection_monitor.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../network/http_manager.dart';
import '../../platform/android_wifi_network_binder.dart';
import '../../platform/local_network_info.dart';
import '../home/main_home_page.dart';

/// 连接页（切图1 login1，对齐设计稿橙色卡片）
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> with WidgetsBindingObserver {
  static const _defaultIp = LocalAppSettings.defaultIp;

  /// 设计稿卡片相对 1280×720 视口占比（约 36%×43%），纯色 #FB6401。
  static const double _cardW = 1280 * 0.3604; // ≈461
  static const double _cardH = 720 * 0.4296; // ≈309
  static const double _cardRadius = 20;
  static const Color _cardColor = Color(0xFFFB6401);

  /// 内部布局比例（相对卡片宽/高）。
  static const double _padH = 0.1387;
  static const double _btnW = 0.3367;
  static const double _btnH = 0.145;
  static const double _btnGap = 0.0491;
  /// Logo → 「控制器IP」标签间距（图示：放大 3 倍）。
  static const double _logoToForm = 0.035 * 3;
  /// 标签 → 输入框间距（图示 2 倍后再加 1 倍）。
  static const double _labelToInputGap = 0.012 * 4;
  /// 输入框 → 按钮间距（图示：放大 2 倍）。
  static const double _inputToBtnGap = 0.04 * 2;
  /// login/logo.png 原图比例，避免被压扁。
  static const double _logoAspect = 257 / 58;
  /// Logo 宽度占内容区比例（再缩小 30%）。
  static const double _logoWidthRatio = 0.68 * 0.7;
  /// 卡片内整体内容下移（相对卡片高）。
  static const double _contentOffsetY = 0.08;
  /// 输入框高度：原 0.125 再加高约 1/3。
  static const double _inputH = 0.125 * 4 / 3;
  /// 输入框 / 按钮：四圆角矩形（非胶囊）。
  static const double _fieldRadius = 10;
  static const double _ipFontSize = 22;

  final _ipController = TextEditingController();
  final _ipFocus = FocusNode();
  bool _connecting = false;
  String? _connectStatus;
  String _ipLabel = LocalNetworkInfo.ethernetLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ipFocus.addListener(_onIpFocusChanged);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _ipFocus.onKeyEvent = _onAndroidHardwareKey;
    }
    _loadSavedIp();
    _refreshNetworkLabel(requestPermission: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingMessage();
      if (mounted) _ipFocus.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNetworkLabel();
    }
  }

  Future<void> _refreshNetworkLabel({bool requestPermission = false}) async {
    final label = await LocalNetworkInfo.connectIpLabel(
      requestPermission: requestPermission,
    );
    if (!mounted || _ipLabel == label) return;
    setState(() => _ipLabel = label);
  }

  /// Android：隐藏软键盘，保留输入连接；逍遥/MEmu 等模拟器走 [onKeyEvent] 接收 PC 键盘。
  void _onIpFocusChanged() {
    if (!_ipFocus.hasFocus || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  KeyEventResult _onAndroidHardwareKey(FocusNode node, KeyEvent event) {
    if (_connecting || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onConnect();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _deleteIpSelectionOrBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _deleteIpForward();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      var handled = false;
      for (final unit in char.runes) {
        final s = String.fromCharCode(unit);
        if (RegExp(r'[0-9.]').hasMatch(s)) {
          _insertIpText(s);
          handled = true;
        }
      }
      if (handled) return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _insertIpText(String text) {
    final value = _ipController.value;
    final sel = value.selection;
    final start = sel.start >= 0 ? sel.start : value.text.length;
    final end = sel.end >= 0 ? sel.end : value.text.length;
    final next = value.text.replaceRange(start, end, text);
    _ipController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _deleteIpSelectionOrBackspace() {
    final value = _ipController.value;
    final text = value.text;
    final sel = value.selection;
    if (!sel.isCollapsed) {
      _ipController.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
      return;
    }
    final pos = sel.start >= 0 ? sel.start : text.length;
    if (pos == 0) return;
    _ipController.value = TextEditingValue(
      text: text.replaceRange(pos - 1, pos, ''),
      selection: TextSelection.collapsed(offset: pos - 1),
    );
  }

  void _deleteIpForward() {
    final value = _ipController.value;
    final text = value.text;
    final sel = value.selection;
    if (!sel.isCollapsed) {
      _ipController.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
      return;
    }
    final pos = sel.start >= 0 ? sel.start : text.length;
    if (pos >= text.length) return;
    _ipController.value = TextEditingValue(
      text: text.replaceRange(pos, pos + 1, ''),
      selection: TextSelection.collapsed(offset: pos),
    );
  }

  void _showPendingMessage() {
    final message = RobotState.instance.takePendingUiMessage();
    if (message != null && message.isNotEmpty && mounted) {
      LpStatusLog.instance.success(message, openPanel: false);
    }
  }

  Future<void> _loadSavedIp() async {
    final ip = await LocalAppSettings.loadDefaultIp();
    _ipController.text = ip;
    RobotState.instance.serverBaseUrl = 'http://$ip';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ipFocus.removeListener(_onIpFocusChanged);
    _ipFocus.dispose();
    _ipController.dispose();
    super.dispose();
  }

  bool _isValidIp(String ip) {
    final pattern = RegExp(
      r'^(([1-9]|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))\.)'
      r'(([0-9]|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))\.){2}'
      r'([0-9]|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))$',
    );
    return pattern.hasMatch(ip.trim());
  }

  Future<void> _onConnect() async {
    final ip = _ipController.text.trim();
    if (!_isValidIp(ip)) {
      _showError('请输入有效的 IP 地址');
      return;
    }

    setState(() {
      _connecting = true;
      _connectStatus = '正在连接控制器…';
    });
    final baseUrl = HttpManager.normalizeBaseUrl(ip);
    RobotState.instance.serverBaseUrl = baseUrl;
    HttpManager.instance.baseUrl = baseUrl;

    try {
      // Android：对齐老项目——先绑 Wi‑Fi（失败不阻断），再用原生 OkHttp 直连 IP
      if (defaultTargetPlatform == TargetPlatform.android) {
        if (mounted) {
          setState(() => _connectStatus = '正在连接 Wi‑Fi 通道…');
        }
        await AndroidWifiNetworkBinder.bindWifi();
      }

      final clientTag =
          '${RobotApiConstants.connectClientPrefix} V${AppInfo.version}';
      if (mounted) {
        setState(() => _connectStatus = '正在连接并同步程序…');
      }

      await HttpManager.instance.connectSyncAndApply(clientTag: clientTag);
      final syncWarning = HttpManager.instance.lastProgramSyncError;

      // 保存 IP 失败不应判定为连接失败（Android 公共目录可能不可写）
      try {
        await LocalAppSettings.saveDefaultIp(ip);
      } catch (_) {}

      if (!mounted) return;
      RobotConnectionMonitor.instance.reset();
      RobotStatePoller.instance.start();

      final sync = HttpManager.instance.lastProgramSync;
      final syncMessage = sync == null
          ? '已连接 $baseUrl'
          : sync.isFullySyncedFromRobot
              ? '已连接 $baseUrl，已同步 main.xml / main.rp4'
              : '已连接 $baseUrl（控制器程序为空）';
      LpStatusLog.instance.log(
        syncMessage,
        level: LpLogLevel.success,
        tab: LpStatusPanelTab.connection,
        openPanel: false,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainHomePage()),
      );
      if (syncWarning != null) {
        LpStatusLog.instance.warning('程序同步失败：$syncWarning');
      }
    } catch (e) {
      RobotState.instance.setConnectFailed(e.toString());
      _showError(_formatConnectError(e, ip));
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
          _connectStatus = null;
        });
      }
    }
  }

  String _formatConnectError(Object error, String ip) {
    final text = error.toString();
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (text.contains('网络不可达') ||
        text.contains('Connection refused') ||
        text.contains('Failed to connect') ||
        text.contains('ENETUNREACH')) {
      if (android) {
        return '无法访问 $ip：请先连接机器人 Wi‑Fi，再输入 IP（默认 192.168.11.11）连接；'
            '若仍失败可先关闭移动数据后重试';
      }
      return '无法访问 $ip：请确认 PC 与控制器在同一 Wi‑Fi/网段，'
          '且 Windows 防火墙未拦截本程序';
    }
    if (text.contains('连接超时') ||
        text.contains('TimeoutException') ||
        text.contains('timeout') ||
        text.contains('Timeout')) {
      if (android) {
        return '连接 $ip 超时：请确认已连机器人热点、IP 正确（常用 192.168.11.11），'
            '且控制器已开机';
      }
      return '连接 $ip 超时：请确认 IP 正确且控制器 HTTP 服务已启动';
    }
    if (text.contains('Connection closed') || text.contains('HTTP 通信异常')) {
      return '与控制器通信被中断，请重试；若仍失败请重启控制器后再连';
    }
    if (text.contains('FormatException') || text.contains('响应不是 JSON')) {
      return '控制器返回了非预期数据，请确认 IP 指向机器人控制器而非其他设备';
    }
    return '连接失败：$text';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LpRobotColors.alarm,
      ),
    );
  }

  void _openOfflineHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF5EE),
          image: DecorationImage(
            image: AssetImage(LpAppAssets.loginBg),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.3),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 48 + bottomInset),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildCard(context),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 10,
                child: Text(
                  '${AppInfo.productName}  V${AppInfo.version}',
                  textAlign: TextAlign.center,
                  style: LpAppFonts.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB0A8A0),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    const w = _cardW;
    const h = _cardH;
    final padH = w * _padH;
    final btnW = w * _btnW;
    final btnH = h * _btnH;
    final btnGap = w * _btnGap;
    final inputH = h * _inputH;
    final inputToBtn = h * _inputToBtnGap;
    final contentW = w - padH * 2;
    final contentYOffset = h * _contentOffsetY;
    final logoTop = h * 0.07 + contentYOffset;
    final logoW = contentW * _logoWidthRatio;
    final logoH = logoW / _logoAspect;
    final labelSize = (h * 0.045).clamp(12.0, 15.0);
    final labelGap = h * _labelToInputGap;

    // 自上而下：Logo → 标签 → 输入框 → 按钮（间距按图示倍数）。
    final labelTop = logoTop + logoH + h * _logoToForm;
    final inputTop = labelTop + labelSize + labelGap;
    final btnTop = inputTop + inputH + inputToBtn;

    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Stack(
          children: [
            Positioned(
              top: logoTop,
              left: padH,
              right: padH,
              child: Center(
                child: Image.asset(
                  LpAppAssets.loginLogo,
                  width: logoW,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            Positioned(
              top: labelTop,
              left: padH,
              width: contentW,
              child: Text(
                _ipLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LpAppFonts.style(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              top: inputTop,
              left: padH,
              width: contentW,
              height: inputH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_fieldRadius),
                child: ColoredBox(
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _ipController,
                      focusNode: _ipFocus,
                      autofocus: true,
                      textAlign: TextAlign.left,
                      textAlignVertical: TextAlignVertical.center,
                      style: LpAppFonts.style(
                        fontSize: _ipFontSize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFE25401),
                        height: 1.0,
                      ),
                      cursorColor: const Color(0xFFE25401),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: _defaultIp,
                        hintStyle: LpAppFonts.style(
                          fontSize: _ipFontSize,
                          fontWeight: FontWeight.w400,
                          color:
                              const Color(0xFFE25401).withValues(alpha: 0.45),
                          height: 1.0,
                        ),
                        // 少左内边距，靠左；垂直由 Align 居中。
                        contentPadding: const EdgeInsets.only(left: 10, right: 10),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      enabled: !_connecting,
                      onSubmitted: (_) => _onConnect(),
                    ),
                  ),
                ),
              ),
            ),
            if (_connectStatus != null)
              Positioned(
                top: inputTop + inputH + h * 0.008,
                left: padH,
                width: contentW,
                child: Text(
                  _connectStatus!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LpAppFonts.style(
                    fontSize: labelSize * 0.9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            Positioned(
              top: btnTop,
              left: padH,
              width: contentW,
              height: btnH,
              child: Row(
                children: [
                  SizedBox(
                    width: btnW,
                    height: btnH,
                    child: _ConnectActionButton(
                      height: btnH,
                      radius: _fieldRadius,
                      enabled: !_connecting,
                      onPressed: _onConnect,
                      child: _connecting
                          ? SizedBox(
                              width: btnH * 0.36,
                              height: btnH * 0.36,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFFFB6401),
                              ),
                            )
                          : null,
                      labelBuilder: (focused) => Text(
                        '连接',
                        style: LpAppFonts.style(
                          fontSize: (btnH * 0.34).clamp(15.0, 22.0),
                          fontWeight: FontWeight.w700,
                          color: focused
                              ? const Color(0xFFFB6401)
                              : Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: btnGap),
                  SizedBox(
                    width: btnW,
                    height: btnH,
                    child: _ConnectActionButton(
                      height: btnH,
                      radius: _fieldRadius,
                      enabled: !_connecting,
                      onPressed: _openOfflineHome,
                      labelBuilder: (focused) {
                        final color =
                            focused ? const Color(0xFFFB6401) : Colors.white;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '跳过连接',
                                style: LpAppFonts.style(
                                  fontSize: (btnH * 0.28).clamp(13.0, 18.0),
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: btnH * 0.04),
                              Text(
                                '(仅本地 Blockly)',
                                style: LpAppFonts.style(
                                  fontSize: (btnH * 0.20).clamp(10.0, 13.0),
                                  fontWeight: FontWeight.w500,
                                  color: color.withValues(
                                    alpha: focused ? 1 : 0.95,
                                  ),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 未焦点：浅色半透明；焦点 / 悬停：白底。
class _ConnectActionButton extends StatefulWidget {
  const _ConnectActionButton({
    required this.height,
    required this.radius,
    required this.enabled,
    required this.onPressed,
    required this.labelBuilder,
    this.child,
  });

  final double height;
  final double radius;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget Function(bool focused) labelBuilder;
  final Widget? child;

  @override
  State<_ConnectActionButton> createState() => _ConnectActionButtonState();
}

class _ConnectActionButtonState extends State<_ConnectActionButton> {
  final FocusNode _focusNode = FocusNode();
  bool _hovered = false;

  bool get _lit => _focusNode.hasFocus || _hovered;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final lit = _lit;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (!widget.enabled || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled
              ? () {
                  _focusNode.requestFocus();
                  widget.onPressed();
                }
              : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: widget.enabled ? 1 : 0.65,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: lit
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: borderRadius,
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: widget.height * 0.08,
                vertical: widget.height * 0.06,
              ),
              child: widget.child ?? widget.labelBuilder(lit),
            ),
          ),
        ),
      ),
    );
  }
}
