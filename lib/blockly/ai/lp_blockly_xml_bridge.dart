import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lp_blockly_ai_controls_if_plan.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_motion_plan.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_toolbox_registry.dart';

/// GCode 校验结果。
class LpBlocklyGCodeVerifyResult {
  const LpBlocklyGCodeVerifyResult({
    required this.ok,
    this.message,
    this.preview,
  });

  final bool ok;
  final String? message;
  final String? preview;
}

/// 工作区顶层块摘要。
class LpBlocklyTopBlockInfo {
  const LpBlocklyTopBlockInfo({
    required this.id,
    required this.type,
    required this.text,
  });

  final String id;
  final String type;
  final String text;
}

/// JS getWorkspaceOverviewForAi 返回结果。
class LpBlocklyWorkspaceOverview {
  const LpBlocklyWorkspaceOverview({
    required this.ok,
    this.message,
    this.blockCount = 0,
    this.topBlockCount = 0,
    this.topBlocks = const [],
  });

  final bool ok;
  final String? message;
  final int blockCount;
  final int topBlockCount;
  final List<LpBlocklyTopBlockInfo> topBlocks;

  String toPromptJson({int maxTop = 12}) {
    if (!ok) return '{"ok":false,"message":"${message ?? "unknown"}"}';
    final tops = topBlocks.take(maxTop).map((b) => {
          'id': b.id,
          'type': b.type,
          'text': b.text,
        }).toList();
    return jsonEncode({
      'ok': true,
      'blockCount': blockCount,
      'topBlockCount': topBlockCount,
      'topBlocks': tops,
    });
  }
}

/// 按 id 移除块的结果。
class LpBlocklyRemoveBlocksResult {
  const LpBlocklyRemoveBlocksResult({
    required this.ok,
    this.removed = 0,
    this.message,
  });

  final bool ok;
  final int removed;
  final String? message;
}

/// 简单 JS 布尔结果。
class LpBlocklySimpleJsResult {
  const LpBlocklySimpleJsResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// Toolbox 扫描结果。
class LpBlocklyToolboxScanResult {
  const LpBlocklyToolboxScanResult({
    required this.ok,
    this.message,
    this.entries = const [],
  });

  final bool ok;
  final String? message;
  final List<LpBlocklyToolboxEntry> entries;
}

/// 通过 WebView 复用 Blockly 既有 API 导出/载入 XML（不修改 Blockly 源码）。
class LpBlocklyXmlBridge {
  LpBlocklyXmlBridge(this.controller);

  final WebViewController controller;

  Future<String> exportWorkspaceXml() async {
    const js = '''
(function () {
  try {
    if (window.Code && typeof Code.generateXml === 'function') {
      return Code.generateXml();
    }
  } catch (e) {
    console.error('export xml failed', e);
  }
  return '';
})()
''';
    final raw = await controller.runJavaScriptReturningResult(js);
    return _coerceJsString(raw);
  }

  Future<bool> applyXml(
    String xml, {
    required LpBlocklyAiApplyMode applyMode,
    String? userPrompt,
  }) async {
    var fixed = xml;
    if (userPrompt != null && userPrompt.trim().isNotEmpty) {
      fixed = LpBlocklyAiIntentBuilder.repairXmlFromPrompt(fixed, userPrompt);
    } else {
      fixed = LpBlocklyAiControlsIfPlan.repairXml(
        LpBlocklyAiMotionPlan.repairXml(xml),
      );
    }
    final payload = jsonEncode(fixed);
    final fn = applyMode == LpBlocklyAiApplyMode.replace
        ? 'Code.replaceBlocksfromXml'
        : 'Code.appendBlocksfromXml';
    final js = '''
(function () {
  try {
    if (!window.Code || typeof $fn !== 'function') {
      return false;
    }
    return $fn($payload) === true;
  } catch (e) {
    console.error('apply xml failed', e);
    return false;
  }
})()
''';
    final raw = await controller.runJavaScriptReturningResult(js);
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final text = raw.toString().toLowerCase();
    return text == 'true';
  }

  /// 工作区概览（顶层块 id/type/文本），供 Agent 上下文使用。
  Future<LpBlocklyWorkspaceOverview> getWorkspaceOverview() async {
    const js = '''
(function () {
  try {
    if (window.Code && typeof Code.getWorkspaceOverviewForAi === 'function') {
      return Code.getWorkspaceOverviewForAi();
    }
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
  return JSON.stringify({ ok: false, message: '概览接口不可用' });
})()
''';
    try {
      final raw = await controller.runJavaScriptReturningResult(js);
      final map = _coerceJsMap(raw);
      if (map['ok'] != true) {
        return LpBlocklyWorkspaceOverview(
          ok: false,
          message: map['message']?.toString() ?? '读取失败',
        );
      }
      final tops = <LpBlocklyTopBlockInfo>[];
      final rawTops = map['topBlocks'];
      if (rawTops is List) {
        for (final item in rawTops) {
          if (item is! Map) continue;
          final m = item.map((k, v) => MapEntry(k.toString(), v));
          tops.add(LpBlocklyTopBlockInfo(
            id: m['id']?.toString() ?? '',
            type: m['type']?.toString() ?? '',
            text: m['text']?.toString() ?? '',
          ));
        }
      }
      return LpBlocklyWorkspaceOverview(
        ok: true,
        blockCount: (map['blockCount'] as num?)?.toInt() ?? 0,
        topBlockCount: (map['topBlockCount'] as num?)?.toInt() ?? tops.length,
        topBlocks: tops,
      );
    } catch (e) {
      return LpBlocklyWorkspaceOverview(ok: false, message: '$e');
    }
  }

  /// 扫描 toolbox 可用块类型。
  Future<LpBlocklyToolboxScanResult> getToolboxBlockTypes() async {
    const js = '''
(function () {
  try {
    if (window.Code && typeof Code.aiGetToolboxBlockTypes === 'function') {
      return Code.aiGetToolboxBlockTypes();
    }
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
  return JSON.stringify({ ok: false, message: 'toolbox 扫描接口不可用' });
})()
''';
    try {
      final raw = await controller.runJavaScriptReturningResult(js);
      final map = _coerceJsMap(raw);
      if (map['ok'] != true) {
        return LpBlocklyToolboxScanResult(
          ok: false,
          message: map['message']?.toString(),
        );
      }
      final entries = <LpBlocklyToolboxEntry>[];
      final types = map['types'];
      if (types is List) {
        for (final item in types) {
          if (item is! Map) continue;
          final m = item.map((k, v) => MapEntry(k.toString(), v));
          final type = m['type']?.toString();
          if (type == null || type.isEmpty) continue;
          entries.add(LpBlocklyToolboxEntry(
            type: type,
            category: m['category']?.toString() ?? '其他',
          ));
        }
      }
      return LpBlocklyToolboxScanResult(ok: true, entries: entries);
    } catch (e) {
      return LpBlocklyToolboxScanResult(ok: false, message: '$e');
    }
  }

  /// 清空工作区（Tool：clear_workspace）。
  Future<LpBlocklySimpleJsResult> clearWorkspace() async {
    const js = '''
(function () {
  try {
    if (window.Code && typeof Code.aiClearWorkspace === 'function') {
      return Code.aiClearWorkspace();
    }
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
  return JSON.stringify({ ok: false, message: '清空接口不可用' });
})()
''';
    try {
      final raw = await controller.runJavaScriptReturningResult(js);
      final map = _coerceJsMap(raw);
      return LpBlocklySimpleJsResult(
        ok: map['ok'] == true,
        message: map['message']?.toString(),
      );
    } catch (e) {
      return LpBlocklySimpleJsResult(ok: false, message: '$e');
    }
  }

  /// 移除所有顶层 ai_ 前缀块（修正模式清理，含散架残留）。
  Future<LpBlocklyRemoveBlocksResult> removeAllAiTopBlocks() async {
    return _invokeRemoveBlocks('Code.aiRemoveTopAiBlocks', null);
  }

  /// 移除画布上指定 id 的块（仅用于「替换上次 AI 结果」）。
  Future<LpBlocklyRemoveBlocksResult> removeBlocksByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const LpBlocklyRemoveBlocksResult(ok: true);
    }
    final primary = await _invokeRemoveBlocks('Code.aiRemoveBlocksByIds', ids);
    if (primary.ok && primary.removed > 0) return primary;
    // 指定 id 未命中：尝试移除画布上仍存在的 ai_ 顶层块。
    final fallback = await _invokeRemoveBlocks('Code.aiRemoveTopAiBlocks', null);
    if (fallback.ok && fallback.removed > 0) return fallback;
    if (!primary.ok) return primary;
    // 画布上已无目标块（用户可能已手动删除）→ 允许继续写入。
    return const LpBlocklyRemoveBlocksResult(
      ok: true,
      removed: 0,
      message: '画布上无待移除的 AI 块',
    );
  }

  Future<LpBlocklyRemoveBlocksResult> _invokeRemoveBlocks(
    String fn,
    List<String>? ids,
  ) async {
    final payload = ids != null ? jsonEncode(ids) : 'null';
    final js = '''
(function () {
  try {
    if (window.Code && typeof $fn === 'function') {
      return $fn($payload);
    }
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
  return JSON.stringify({ ok: false, message: '移除块接口不可用' });
})()
''';
    try {
      final raw = await controller.runJavaScriptReturningResult(js);
      final map = _coerceJsMap(raw);
      return LpBlocklyRemoveBlocksResult(
        ok: map['ok'] == true,
        removed: (map['removed'] as num?)?.toInt() ?? 0,
        message: map['message']?.toString(),
      );
    } catch (e) {
      return LpBlocklyRemoveBlocksResult(ok: false, message: '$e');
    }
  }

  /// 编译并校验当前工作区 GCode（对应 aily 的编译验证步骤）。
  Future<LpBlocklyGCodeVerifyResult> verifyGCode({int previewMaxChars = 400}) async {
    const js = '''
(function () {
  try {
    if (!window.Code) return JSON.stringify({ ok: false, message: 'Blockly 未就绪' });
    if (typeof Code.checkWorkspaceGCode === 'function') {
      var ok = Code.checkWorkspaceGCode() === true;
      var preview = '';
      if (typeof Code.generateGCode === 'function') {
        preview = Code.generateGCode().replace(/^\\s*\\n/gm, '');
      }
      return JSON.stringify({ ok: ok, preview: preview, message: ok ? '' : '工作区存在编译错误' });
    }
    if (typeof Code.generateGCode === 'function') {
      var text = Code.generateGCode();
      return JSON.stringify({ ok: true, preview: text, message: '' });
    }
    return JSON.stringify({ ok: false, message: 'GCode 接口不可用' });
  } catch (e) {
    return JSON.stringify({ ok: false, message: String(e) });
  }
})()
''';
    try {
      final raw = await controller.runJavaScriptReturningResult(js);
      final map = _coerceJsMap(raw);
      final ok = map['ok'] == true;
      var preview = map['preview']?.toString() ?? '';
      if (preview.length > previewMaxChars) {
        preview = '${preview.substring(0, previewMaxChars)}…';
      }
      return LpBlocklyGCodeVerifyResult(
        ok: ok,
        message: map['message']?.toString(),
        preview: preview.isEmpty ? null : preview,
      );
    } catch (e) {
      return LpBlocklyGCodeVerifyResult(ok: false, message: '$e');
    }
  }

  Map<String, dynamic> _coerceJsMap(Object? raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    final text = _coerceJsString(raw);
    if (text.isNotEmpty) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return {'ok': false, 'message': '无法解析校验结果'};
  }

  String _coerceJsString(Object? raw) {
    if (raw == null) return '';
    if (raw is String) {
      if (raw.length >= 2 &&
          ((raw.startsWith('"') && raw.endsWith('"')) ||
              (raw.startsWith("'") && raw.endsWith("'")))) {
        try {
          return jsonDecode(raw) as String;
        } catch (_) {
          return raw.substring(1, raw.length - 1);
        }
      }
      return raw;
    }
    debugPrint('Blockly XML bridge unexpected type: ${raw.runtimeType}');
    return raw.toString();
  }
}
