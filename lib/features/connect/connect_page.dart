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
  bool _connecting = false;
  String? _connectStatus;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingMessage());
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
      LpStatusLog.instance.log(
        sync == null
            ? '已连接 $baseUrl'
            : '已连接 $baseUrl，已同步 main.xml / main.rp4',
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
    return Scaffold(
      backgroundColor: LpRobotColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LpBrandLogo(height: 80, maxWidth: 360),
                  const SizedBox(height: 16),
                  Text(
                    AppInfo.displayTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LpRobotColors.label,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: '控制器 IP',
                      hintText: _defaultIp,
                    ),
                    keyboardType: TextInputType.number,
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
