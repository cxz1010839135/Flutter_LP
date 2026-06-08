import 'package:flutter/material.dart';

import '../../core/robot_connection_monitor.dart';
import '../../core/robot_state.dart';
import '../../features/connect/connect_page.dart';
import '../lp_robot_colors.dart';
import 'lp_app_navigator.dart';

/// 全局连接中断遮罩：自动重连，可取消返回连接页。
class RobotConnectionGuard extends StatelessWidget {
  const RobotConnectionGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  void _cancelToConnectPage() {
    RobotConnectionMonitor.instance.cancelWaiting();
    lpRootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        RobotConnectionMonitor.instance,
        RobotState.instance,
      ]),
      builder: (context, _) {
        final monitor = RobotConnectionMonitor.instance;
        final show = monitor.showOverlay;

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (show) ...[
              ModalBarrier(
                color: Colors.black.withValues(alpha: 0.45),
                dismissible: false,
              ),
              Center(
                child: _ConnectionInterruptedDialog(
                  phase: monitor.phase,
                  attempt: monitor.reconnectAttempts,
                  onCancel: _cancelToConnectPage,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ConnectionInterruptedDialog extends StatefulWidget {
  const _ConnectionInterruptedDialog({
    required this.phase,
    required this.attempt,
    required this.onCancel,
  });

  final RobotLinkPhase phase;
  final int attempt;
  final VoidCallback onCancel;

  @override
  State<_ConnectionInterruptedDialog> createState() =>
      _ConnectionInterruptedDialogState();
}

class _ConnectionInterruptedDialogState
    extends State<_ConnectionInterruptedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reconnecting = widget.phase == RobotLinkPhase.reconnecting;
    final statusText = reconnecting
        ? '正在尝试重新连接（第 ${widget.attempt} 次）'
        : '与控制器通信中断，即将自动重连';

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: LpRobotColors.borderWarm.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 0.55, end: 1).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: LpRobotColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '连接中断',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: LpRobotColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: LpRobotColors.label,
                  ),
                ),
                const SizedBox(height: 16),
                if (reconnecting)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LpRobotColors.primary,
                      side: BorderSide(
                        color: LpRobotColors.primary.withValues(alpha: 0.65),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '取消，返回连接页',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '请保持网络畅通，连接恢复后将自动继续',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: LpRobotColors.label.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
