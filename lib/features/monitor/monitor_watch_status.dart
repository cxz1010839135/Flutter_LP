import 'package:flutter/foundation.dart';

import 'monitor_d9000_status.dart';
import 'monitor_plc_watch_storage.dart';

/// 监控页寄存器监视 → 底部状态窗口（当前仅 D9000）。
class MonitorWatchStatus extends ChangeNotifier {
  MonitorWatchStatus._();
  static final MonitorWatchStatus instance = MonitorWatchStatus._();

  bool watchingD9000 = false;
  int? d9000Value;
  bool d9000Error = false;

  String? get d9000StatusLine {
    if (!watchingD9000) return null;
    if (d9000Error) return 'D9000：读取失败';
    if (d9000Value == null) return 'D9000：读取中…';
    return MonitorD9000Status.formatStatusLine(d9000Value!);
  }

  void updateFromEntries(List<MonitorPlcWatchEntry> entries) {
    MonitorPlcWatchEntry? d9000;
    for (final entry in entries) {
      if (entry.kind == PlcRegisterKind.d &&
          entry.address == MonitorD9000Status.address) {
        d9000 = entry;
        break;
      }
    }

    final nextWatching = d9000 != null;
    final nextValue = d9000?.currentValue;
    final nextError = d9000?.error ?? false;

    if (watchingD9000 == nextWatching &&
        d9000Value == nextValue &&
        d9000Error == nextError) {
      return;
    }

    watchingD9000 = nextWatching;
    d9000Value = nextWatching ? nextValue : null;
    d9000Error = nextWatching && nextError;
    notifyListeners();
  }
}
