import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_prompt.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_xml_parser.dart';
import 'lp_blockly_xml_bridge.dart';

/// Blockly AI 生成流程编排。
class LpBlocklyAiController extends ChangeNotifier {
  LpBlocklyAiController({required WebViewController webViewController})
      : _xmlBridge = LpBlocklyXmlBridge(webViewController);

  final LpBlocklyXmlBridge _xmlBridge;

  LpBlocklyAiConfig config = const LpBlocklyAiConfig();
  bool loading = false;
  String statusMessage = '描述需求后点击生成，AI 将写入 Blockly 画布。';
  String? lastRawResponse;
  String? lastExtractedXml;

  bool get isBusy => loading;

  Future<void> loadConfig() async {
    config = await LpBlocklyAiConfig.load();
    notifyListeners();
  }

  Future<void> updateConfig(LpBlocklyAiConfig value) async {
    config = value;
    await config.save();
    notifyListeners();
  }

  Future<void> generate(String userPrompt) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty) {
      statusMessage = '请输入编程需求描述';
      notifyListeners();
      return;
    }
    if (loading) return;

    loading = true;
    statusMessage = '正在读取当前画布…';
    notifyListeners();

    try {
      String? currentXml;
      if (config.applyMode == LpBlocklyAiApplyMode.append) {
        currentXml = await _xmlBridge.exportWorkspaceXml();
      }

      final systemPrompt = LpBlocklyAiPrompt.buildSystemPrompt(
        currentWorkspaceXml: currentXml,
      );
      final service = LpBlocklyAiService.forMode(config.mode);
      var userMessage = LpBlocklyAiPrompt.buildUserMessage(prompt);

      statusMessage = config.mode == LpBlocklyAiMode.online
          ? '正在请求联网 AI…'
          : '正在请求本地 Ollama…';
      notifyListeners();

      var raw = await service.complete(
        config: config,
        systemPrompt: systemPrompt,
        userMessage: userMessage,
      );
      lastRawResponse = raw;

      var xml = LpBlocklyAiXmlParser.extract(raw);
      var validation = xml == null ? '无法从回复中提取 XML' : LpBlocklyAiXmlParser.validate(xml);

      if (validation != null) {
        statusMessage = '首次生成需修正，正在重试…';
        notifyListeners();
        userMessage = LpBlocklyAiPrompt.buildRetryMessage(
          userPrompt: prompt,
          error: validation,
          previousResponse: raw,
        );
        raw = await service.complete(
          config: config,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
        );
        lastRawResponse = raw;
        xml = LpBlocklyAiXmlParser.extract(raw);
        validation = xml == null ? '无法从回复中提取 XML' : LpBlocklyAiXmlParser.validate(xml);
      }

      if (validation != null || xml == null) {
        statusMessage = validation ?? '生成失败';
        return;
      }

      lastExtractedXml = xml;
      statusMessage = '正在载入画布…';
      notifyListeners();

      final applied = await _xmlBridge.applyXml(
        xml,
        applyMode: config.applyMode,
      );
      if (!applied) {
        statusMessage = 'XML 解析失败，请在 Blockly 中检查块类型与结构';
        return;
      }

      statusMessage = config.applyMode == LpBlocklyAiApplyMode.replace
          ? '已生成并替换画布内容'
          : '已生成并追加到画布';
    } on LpBlocklyAiException catch (e) {
      statusMessage = e.message;
    } catch (e, st) {
      debugPrint('Blockly AI generate failed: $e\n$st');
      statusMessage = '生成失败：$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
