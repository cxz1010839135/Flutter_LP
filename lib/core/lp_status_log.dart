import 'package:flutter/foundation.dart';

/// 底部状态面板分类（对齐 Cursor 底部 Panel 标签）。
enum LpStatusPanelTab {
  connection('连接'),
  messages('消息'),
  output('输出');

  const LpStatusPanelTab(this.label);
  final String label;
}

enum LpLogLevel { info, success, warning, error }

class LpLogEntry {
  const LpLogEntry({
    required this.message,
    required this.time,
    required this.level,
    required this.tab,
  });

  final String message;
  final DateTime time;
  final LpLogLevel level;
  final LpStatusPanelTab tab;
}

/// 全局状态日志 + 底部面板展开/标签状态。
class LpStatusLog extends ChangeNotifier {
  LpStatusLog._();
  static final LpStatusLog instance = LpStatusLog._();

  static const int maxEntries = 80;

  final List<LpLogEntry> _entries = [];
  bool panelExpanded = false;
  LpStatusPanelTab selectedTab = LpStatusPanelTab.connection;

  List<LpLogEntry> get entries => List.unmodifiable(_entries);

  List<LpLogEntry> entriesFor(LpStatusPanelTab tab) =>
      _entries.where((e) => e.tab == tab).toList();

  void togglePanel() {
    panelExpanded = !panelExpanded;
    notifyListeners();
  }

  void openPanel({LpStatusPanelTab? tab}) {
    panelExpanded = true;
    if (tab != null) selectedTab = tab;
    notifyListeners();
  }

  void closePanel() {
    panelExpanded = false;
    notifyListeners();
  }

  void selectTab(LpStatusPanelTab tab) {
    selectedTab = tab;
    panelExpanded = true;
    notifyListeners();
  }

  void log(
    String message, {
    LpLogLevel level = LpLogLevel.info,
    LpStatusPanelTab tab = LpStatusPanelTab.messages,
    bool openPanel = false,
  }) {
    if (message.isEmpty) return;
    _entries.insert(
      0,
      LpLogEntry(
        message: message,
        time: DateTime.now(),
        level: level,
        tab: tab,
      ),
    );
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    if (openPanel) {
      panelExpanded = true;
      selectedTab = tab;
    }
    notifyListeners();
  }

  void info(String message, {bool openPanel = false}) => log(
        message,
        level: LpLogLevel.info,
        tab: LpStatusPanelTab.messages,
        openPanel: openPanel,
      );

  void success(String message, {bool openPanel = false}) => log(
        message,
        level: LpLogLevel.success,
        tab: LpStatusPanelTab.messages,
        openPanel: openPanel,
      );

  void warning(String message, {bool openPanel = false}) => log(
        message,
        level: LpLogLevel.warning,
        tab: LpStatusPanelTab.messages,
        openPanel: openPanel,
      );

  void error(String message, {bool openPanel = false}) => log(
        message,
        level: LpLogLevel.error,
        tab: LpStatusPanelTab.messages,
        openPanel: openPanel,
      );

  void clearTab(LpStatusPanelTab tab) {
    _entries.removeWhere((e) => e.tab == tab);
    notifyListeners();
  }
}
