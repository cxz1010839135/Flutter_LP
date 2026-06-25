import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/lp_robot_colors.dart';
import '../../app/widgets/lp_brand_logo.dart';
import '../../core/app_info.dart';
import '../../core/robot_connection_monitor.dart';
import '../../core/local_app_settings.dart';
import '../../core/lp_status_log.dart';
import '../../core/robot_state.dart';
import '../../core/robot_state_poller.dart';
import '../../network/http_manager.dart';
import '../home/main_home_page.dart';

/// 连接页（对齐 Android ConnectActivity 最小流程）
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  static const _defaultIp = LocalAppSettings.defaultIp;

  final _ipController = TextEditingController();
  final _ipFocus = FocusNode();
  bool _connecting = false;
  String? _connectStatus;

  @override
  void initState() {
    super.initState();
    _ipFocus.addListener(_onIpFocusChanged);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _ipFocus.onKeyEvent = _onAndroidHardwareKey;
    }
    _loadSavedIp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingMessage();
      if (mounted) _ipFocus.requestFocus();
    });
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
      final clientTag =
          '${RobotApiConstants.connectClientPrefix} V${AppInfo.version}';
      if (mounted) {
        setState(() => _connectStatus = '正在连接并同步程序…');
      }

      await HttpManager.instance.connectSyncAndApply(clientTag: clientTag);
      final syncWarning = HttpManager.instance.lastProgramSyncError;

      await LocalAppSettings.saveDefaultIp(ip);

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
    if (text.contains('网络不可达') || text.contains('Connection refused')) {
      return '无法访问 $ip：请确认 PC 与控制器在同一 Wi‑Fi/网段，'
          '且 Windows 防火墙未拦截本程序';
    }
    if (text.contains('连接超时') || text.contains('TimeoutException')) {
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
      backgroundColor: LpRobotColors.shellBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    bottomInset -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LpBrandLogo(height: 96, maxWidth: 380, bundledOnly: true),
                  const SizedBox(height: 14),
                  Text(
                    AppInfo.displayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: LpRobotColors.label,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _ipController,
                    focusNode: _ipFocus,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '控制器 IP',
                      hintText: _defaultIp,
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
                  const SizedBox(height: 24),
                  if (_connectStatus != null) ...[
                    Text(
                      _connectStatus!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LpRobotColors.label,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _connecting ? null : _onConnect,
                      child: _connecting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('连接'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _connecting ? null : _openOfflineHome,
                    child: const Text('跳过连接（仅本地 Blockly）'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
