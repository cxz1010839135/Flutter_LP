import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_state.dart';
import '../../../network/http_manager.dart';
import '../monitor_special_register_dialog.dart';
import '../monitor_plc_watch_storage.dart';
import '../monitor_watch_status.dart';

/// 寄存器监视（D/M/S/X/Y 分 tab，最多 30 项）。
class MonitorPlcWatchPanel extends StatefulWidget {
  const MonitorPlcWatchPanel({super.key});

  @override
  State<MonitorPlcWatchPanel> createState() => _MonitorPlcWatchPanelState();
}

class _MonitorPlcWatchPanelState extends State<MonitorPlcWatchPanel>
    with SingleTickerProviderStateMixin {
  static const _intervalOptions = [400, 500, 800, 1000, 1500];

  static const _kindTitles = {
    PlcRegisterKind.d: '数据寄存器 D',
    PlcRegisterKind.m: '线圈 M',
    PlcRegisterKind.s: '状态 S',
    PlcRegisterKind.x: '输入 X',
    PlcRegisterKind.y: '输出 Y',
  };

  List<MonitorPlcWatchEntry> _entries = [];
  bool _autoRefresh = true;
  int _intervalMs = 500;
  bool _polling = false;
  Timer? _timer;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PlcRegisterKind.values.length,
      vsync: this,
    );
    _loadConfig();
  }

  @override
  void dispose() {
    _stopPolling();
    _tabController.dispose();
    super.dispose();
  }

  List<MonitorPlcWatchEntry> _entriesOf(PlcRegisterKind kind) {
    return _entries.where((e) => e.kind == kind).toList();
  }

  Future<void> _loadConfig() async {
    final config = await MonitorPlcWatchStorage.load();
    if (!mounted) return;
    setState(() {
      _entries = List.from(config.entries);
      _autoRefresh = config.autoRefresh;
      _intervalMs = config.intervalMs;
    });
    _syncWatchStatus();
    _syncPolling();
  }

  void _syncWatchStatus() {
    MonitorWatchStatus.instance.updateFromEntries(_entries);
  }

  Future<void> _persist() async {
    await MonitorPlcWatchStorage.save(
      MonitorPlcWatchConfig(
        entries: _entries,
        autoRefresh: _autoRefresh,
        intervalMs: _intervalMs,
      ),
    );
  }

  void _syncPolling() {
    _stopPolling();
    if (!_autoRefresh || _entries.isEmpty || !RobotState.instance.isConnected) {
      return;
    }
    _timer = Timer.periodic(
      Duration(milliseconds: _intervalMs),
      (_) => _pollAll(),
    );
    unawaited(_pollAll());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollAll() async {
    if (_polling || !RobotState.instance.isConnected || _entries.isEmpty) {
      return;
    }
    _polling = true;
    try {
      final updated = <MonitorPlcWatchEntry>[];
      for (final entry in _entries) {
        updated.add(await _readEntry(entry));
      }
      if (!mounted) return;
      setState(() => _entries = updated);
      _syncWatchStatus();
    } finally {
      _polling = false;
    }
  }

  Future<MonitorPlcWatchEntry> _readEntry(MonitorPlcWatchEntry entry) async {
    try {
      final res = await switch (entry.kind) {
        PlcRegisterKind.d => HttpManager.instance.getRegD(entry.address),
        PlcRegisterKind.m => HttpManager.instance.getCoilM(entry.address),
        PlcRegisterKind.s => HttpManager.instance.getRegS(entry.address),
        PlcRegisterKind.x => HttpManager.instance.getRegX(entry.address),
        PlcRegisterKind.y => HttpManager.instance.getRegY(entry.address),
      };
      res.ensureOk();
      final raw = res.data;
      final value = raw is num
          ? raw.toInt()
          : int.tryParse(raw?.toString() ?? '') ?? 0;
      return entry.copyWith(
        previousValue: entry.currentValue ?? value,
        currentValue: value,
        error: false,
      );
    } catch (_) {
      return entry.copyWith(error: true);
    }
  }

  bool _hasEntry(PlcRegisterKind kind, int address) {
    return _entries.any((e) => e.kind == kind && e.address == address);
  }

  Future<void> _addEntry(PlcRegisterKind kind) async {
    if (_entries.length >= MonitorPlcWatchStorage.maxEntries) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已达总数上限 ${MonitorPlcWatchStorage.maxEntries} 条',
          ),
        ),
      );
      return;
    }

    final labelController = TextEditingController();
    final addrController = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('添加 ${_kindTitles[kind]}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addrController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '${kind.label} 地址',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: '别名（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      labelController.dispose();
      addrController.dispose();
      return;
    }

    final addr = int.tryParse(addrController.text.trim()) ?? 0;
    final label = labelController.text.trim();
    labelController.dispose();
    addrController.dispose();

    if (_hasEntry(kind, addr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${kind.label}$addr 已在列表中')),
      );
      return;
    }

    setState(() {
      _entries = [
        ..._entries,
        MonitorPlcWatchEntry(kind: kind, address: addr, label: label),
      ];
    });
    _syncWatchStatus();
    await _persist();
    _syncPolling();
  }

  void _removeEntry(MonitorPlcWatchEntry entry) {
    setState(() {
      _entries = _entries
          .where(
            (e) => !(e.kind == entry.kind && e.address == entry.address),
          )
          .toList();
    });
    _syncWatchStatus();
    unawaited(_persist());
    _syncPolling();
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.length;
    final maxed = total >= MonitorPlcWatchStorage.maxEntries;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            total: total,
            polling: _polling,
            autoRefresh: _autoRefresh,
            intervalMs: _intervalMs,
            intervalOptions: _intervalOptions,
            onRefresh: _entries.isEmpty ? null : _pollAll,
            onAutoRefreshChanged: (v) {
              setState(() => _autoRefresh = v);
              unawaited(_persist());
              _syncPolling();
            },
            onIntervalChanged: (ms) {
              setState(() => _intervalMs = ms);
              unawaited(_persist());
              _syncPolling();
            },
          ),
          Material(
            color: LpRobotColors.pageBackground,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: LpRobotColors.primary,
              unselectedLabelColor: LpRobotColors.label,
              indicatorColor: LpRobotColors.primary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                for (final kind in PlcRegisterKind.values)
                  Tab(
                    child: _KindTabLabel(
                      kind: kind,
                      count: _entriesOf(kind).length,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final kind in PlcRegisterKind.values)
                  _KindWatchPage(
                    kind: kind,
                    title: _kindTitles[kind]!,
                    entries: _entriesOf(kind),
                    maxed: maxed,
                    onAdd: () => _addEntry(kind),
                    onRemove: _removeEntry,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.total,
    required this.polling,
    required this.autoRefresh,
    required this.intervalMs,
    required this.intervalOptions,
    required this.onRefresh,
    required this.onAutoRefreshChanged,
    required this.onIntervalChanged,
  });

  final int total;
  final bool polling;
  final bool autoRefresh;
  final int intervalMs;
  final List<int> intervalOptions;
  final VoidCallback? onRefresh;
  final ValueChanged<bool> onAutoRefreshChanged;
  final ValueChanged<int> onIntervalChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      decoration: BoxDecoration(
        color: LpRobotColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '寄存器监视 $total/${MonitorPlcWatchStorage.maxEntries}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LpRobotColors.textDark,
                  ),
                ),
              ),
              if (polling)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                tooltip: '特殊寄存器说明',
                onPressed: () => showMonitorSpecialRegisterDialog(context),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.menu_book_outlined),
                color: LpRobotColors.primary,
              ),
              IconButton(
                tooltip: '立即刷新',
                onPressed: onRefresh,
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                color: LpRobotColors.primary,
              ),
            ],
          ),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('自动刷新', style: TextStyle(fontSize: 12)),
              Switch(
                value: autoRefresh,
                onChanged: onAutoRefreshChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              DropdownButton<int>(
                value: intervalOptions.contains(intervalMs) ? intervalMs : 500,
                isDense: true,
                style: const TextStyle(
                  fontSize: 12,
                  color: LpRobotColors.textDark,
                ),
                items: intervalOptions
                    .map(
                      (ms) => DropdownMenuItem(
                        value: ms,
                        child: Text('${ms}ms'),
                      ),
                    )
                    .toList(),
                onChanged: (ms) {
                  if (ms != null) onIntervalChanged(ms);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindTabLabel extends StatelessWidget {
  const _KindTabLabel({required this.kind, required this.count});

  final PlcRegisterKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(kind.label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: LpRobotColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KindWatchPage extends StatelessWidget {
  const _KindWatchPage({
    required this.kind,
    required this.title,
    required this.entries,
    required this.maxed,
    required this.onAdd,
    required this.onRemove,
  });

  final PlcRegisterKind kind;
  final String title;
  final List<MonitorPlcWatchEntry> entries;
  final bool maxed;
  final VoidCallback onAdd;
  final void Function(MonitorPlcWatchEntry entry) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: LpRobotColors.label,
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    '暂无 ${kind.label} 监视\n点击下方添加',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LpRobotColors.label,
                      height: 1.4,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return _WatchRow(
                      entry: e,
                      onRemove: () => onRemove(e),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: maxed ? null : onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(maxed ? '总数已满' : '添加 ${kind.label}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LpRobotColors.primary,
                side: BorderSide(
                  color: LpRobotColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({
    required this.entry,
    required this.onRemove,
  });

  final MonitorPlcWatchEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label =
        entry.label.isNotEmpty ? entry.label : entry.displayAddress;
    final valueText =
        entry.error ? '!' : entry.currentValue?.toString() ?? '—';
    final bg = entry.changed
        ? LpRobotColors.primary.withValues(alpha: 0.12)
        : LpRobotColors.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: entry.changed
              ? LpRobotColors.primary.withValues(alpha: 0.45)
              : LpRobotColors.borderWarm.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LpRobotColors.textDark,
                    ),
                  ),
                  Text(
                    entry.displayAddress,
                    style: const TextStyle(
                      fontSize: 10,
                      color: LpRobotColors.label,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: entry.error
                    ? LpRobotColors.alarm
                    : entry.changed
                        ? LpRobotColors.primary
                        : LpRobotColors.liveValue,
              ),
            ),
            if (entry.changed)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.trending_up,
                  size: 14,
                  color: LpRobotColors.primary,
                ),
              ),
            IconButton(
              onPressed: onRemove,
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '移除',
              icon: const Icon(Icons.close, color: LpRobotColors.label),
            ),
          ],
        ),
      ),
    );
  }
}
