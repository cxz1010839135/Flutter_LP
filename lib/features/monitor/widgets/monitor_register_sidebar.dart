import 'package:flutter/material.dart';

import 'monitor_plc_watch_panel.dart';

/// 监控页右侧：D/M/S/X/Y 寄存器监视（上限可配置）。
class MonitorRegisterSidebar extends StatelessWidget {
  const MonitorRegisterSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const MonitorPlcWatchPanel();
  }
}
