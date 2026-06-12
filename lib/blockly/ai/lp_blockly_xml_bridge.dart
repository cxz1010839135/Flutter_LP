import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lp_blockly_ai_mode.dart';

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
  }) async {
    final payload = jsonEncode(xml);
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
