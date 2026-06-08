import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';

/// PLC 寄存器类型（对齐 `robot_get_D` / `robot_get_M` 等）。
enum PlcRegisterKind {
  d('D'),
  m('M'),
  s('S'),
  x('X'),
  y('Y');

  const PlcRegisterKind(this.label);

  final String label;

  static PlcRegisterKind parse(String? raw) {
    final k = raw?.trim().toUpperCase();
    return switch (k) {
      'M' => PlcRegisterKind.m,
      'S' => PlcRegisterKind.s,
      'X' => PlcRegisterKind.x,
      'Y' => PlcRegisterKind.y,
      _ => PlcRegisterKind.d,
    };
  }
}

/// 单条寄存器监视（最多 [MonitorPlcWatchStorage.maxEntries] 条）。
class MonitorPlcWatchEntry {
  MonitorPlcWatchEntry({
    required this.kind,
    required this.address,
    this.label = '',
    this.currentValue,
    this.previousValue,
    this.error = false,
  });

  final PlcRegisterKind kind;
  final int address;
  final String label;
  int? currentValue;
  int? previousValue;
  bool error;

  String get displayAddress => '${kind.label}$address';

  bool get changed =>
      currentValue != null &&
      previousValue != null &&
      currentValue != previousValue;

  Map<String, dynamic> toJson() => {
        'kind': kind.label,
        'address': address,
        if (label.isNotEmpty) 'label': label,
      };

  factory MonitorPlcWatchEntry.fromJson(Map<String, dynamic> json) {
    return MonitorPlcWatchEntry(
      kind: PlcRegisterKind.parse(json['kind']?.toString()),
      address: json['address'] is int
          ? json['address'] as int
          : int.tryParse(json['address']?.toString() ?? '') ?? 0,
      label: json['label']?.toString() ?? '',
    );
  }

  MonitorPlcWatchEntry copyWith({
    PlcRegisterKind? kind,
    int? address,
    String? label,
    int? currentValue,
    int? previousValue,
    bool? error,
    bool clearValues = false,
  }) {
    return MonitorPlcWatchEntry(
      kind: kind ?? this.kind,
      address: address ?? this.address,
      label: label ?? this.label,
      currentValue: clearValues ? null : (currentValue ?? this.currentValue),
      previousValue:
          clearValues ? null : (previousValue ?? this.previousValue),
      error: error ?? this.error,
    );
  }
}

class MonitorPlcWatchConfig {
  MonitorPlcWatchConfig({
    this.entries = const [],
    this.autoRefresh = true,
    this.intervalMs = 400,
  });

  final List<MonitorPlcWatchEntry> entries;
  final bool autoRefresh;
  final int intervalMs;

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'autoRefresh': autoRefresh,
        'intervalMs': intervalMs,
      };

  factory MonitorPlcWatchConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    final list = <MonitorPlcWatchEntry>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            MonitorPlcWatchEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return MonitorPlcWatchConfig(
      entries: list,
      autoRefresh: json['autoRefresh'] != false,
      intervalMs: json['intervalMs'] is int
          ? (json['intervalMs'] as int).clamp(200, 2000)
          : 400,
    );
  }
}

/// 持久化到 `files/monitor_plc_watch.json`（兼容旧 `monitor_d_watch.json`）。
class MonitorPlcWatchStorage {
  MonitorPlcWatchStorage._();

  static const maxEntries = 30;
  static const _fileName = 'monitor_plc_watch.json';
  static const _legacyFileName = 'monitor_d_watch.json';

  static Future<File> _resolveReadFile() async {
    await RobotPaths.ensureLayout();
    final dir = await RobotPaths.filesRootDir();
    final current = File(p.join(dir, _fileName));
    if (await current.exists()) return current;
    return File(p.join(dir, _legacyFileName));
  }

  static Future<File> _writeFile() async {
    await RobotPaths.ensureLayout();
    return File(p.join(await RobotPaths.filesRootDir(), _fileName));
  }

  static Future<MonitorPlcWatchConfig> load() async {
    try {
      final file = await _resolveReadFile();
      if (!await file.exists()) {
        return MonitorPlcWatchConfig();
      }
      final text = await file.readAsString();
      if (text.trim().isEmpty) {
        return MonitorPlcWatchConfig();
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return MonitorPlcWatchConfig();
      }
      return MonitorPlcWatchConfig.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return MonitorPlcWatchConfig();
    }
  }

  static Future<void> save(MonitorPlcWatchConfig config) async {
    final entries = config.entries.take(maxEntries).toList();
    final file = await _writeFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        MonitorPlcWatchConfig(
          entries: entries,
          autoRefresh: config.autoRefresh,
          intervalMs: config.intervalMs,
        ).toJson(),
      ),
      flush: true,
    );
  }
}
