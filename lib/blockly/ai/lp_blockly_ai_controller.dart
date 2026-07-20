import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../lp_blockly_file_picker.dart';
import 'lp_blockly_ai_agent.dart';
import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_context_store.dart';
import 'lp_blockly_ai_flow_vars.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_io_table.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_pipeline.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_session.dart';
import 'lp_blockly_ai_structure_parser.dart';
import 'lp_blockly_xml_bridge.dart';

/// Blockly AI Agent 控制器（多轮对话 + Todos + 分步执行）。
class LpBlocklyAiController extends ChangeNotifier {
  LpBlocklyAiController({required WebViewController webViewController}) {
    _xmlBridge = LpBlocklyXmlBridge(webViewController);
    _pipeline = LpBlocklyAiPipeline(xmlBridge: _xmlBridge);
    _agent = LpBlocklyAiAgent(xmlBridge: _xmlBridge, pipeline: _pipeline);
    _agent.onEvent = _handleAgentEvent;
    _pipeline.onStage = (stage, message) {
      statusMessage = message;
      notifyListeners();
    };
  }

  late final LpBlocklyXmlBridge _xmlBridge;
  late final LpBlocklyAiPipeline _pipeline;
  late final LpBlocklyAiAgent _agent;

  LpBlocklyAiConfig config = const LpBlocklyAiConfig();
  bool loading = false;
  String statusMessage = '描述需求后发送，Agent 将自动完成编程任务。';
  String? lastRawResponse;
  String? lastExtractedXml;

  /// 上一轮成功载入的结构化计划（用于参数修正补丁）。
  Map<String, dynamic>? lastParsedPlan;

  /// 长期上下文（写入 config/blockly_ai_context.txt）。
  String contextText = '';

  /// 流程变量约定（写入 config/blockly_ai_flow_vars.json）。
  LpBlocklyFlowVarsState flowVars = const LpBlocklyFlowVarsState();

  /// 最近导入的 IO 表分配结果。
  LpBlocklyIoTableResult ioTable = const LpBlocklyIoTableResult();

  final List<LpBlocklyAiChatMessage> messages = [];
  List<LpBlocklyAiTodo> todos = [];

  /// 已保存的会话历史（不含当前未保存的空会话）。
  List<LpBlocklyAiSessionMeta> sessionHistory = [];

  String? _currentSessionId;

  /// 当前会话 id。
  String? get currentSessionId => _currentSessionId;

  /// 上一轮 AI 写入画布的顶层块 id（追加修正时用于替换）。
  List<String> lastAiTopBlockIds = [];

  /// 最近一次请求的追加意图（纯新增 / 修正上一轮）。
  LpBlocklyAiAppendIntent lastAppendIntent = LpBlocklyAiAppendIntent.addNew;

  /// 递增以取消进行中的 Agent 运行（对齐 Cursor Stop）。
  int _runGeneration = 0;

  bool get isBusy => loading;
  int get todosDone => todos.where((t) => t.status == LpBlocklyAiTodoStatus.done).length;

  Future<void> loadConfig() async {
    config = await LpBlocklyAiConfig.load();
    notifyListeners();
  }

  /// 加载配置、长期上下文与本地会话历史。
  Future<void> loadPersisted() async {
    config = await LpBlocklyAiConfig.load();
    contextText = await LpBlocklyAiContextStore.loadContextText();
    flowVars = await LpBlocklyFlowVarsStore.load();
    ioTable = await LpBlocklyIoTableStore.load();
    if (config.persistSession) {
      await LpBlocklyAiContextStore.migrateLegacyIfNeeded();
      sessionHistory = await LpBlocklyAiContextStore.listSessions();
      final activeId = await LpBlocklyAiContextStore.loadActiveSessionId();
      if (activeId != null &&
          sessionHistory.any((s) => s.id == activeId)) {
        _currentSessionId = activeId;
        messages
          ..clear()
          ..addAll(await LpBlocklyAiContextStore.loadSessionMessages(activeId));
        if (messages.isNotEmpty) {
          statusMessage = '已恢复对话：${LpBlocklyAiSessionMeta.titleFromMessages(messages)}';
        }
      } else {
        await _beginNewSession();
      }
    } else {
      await _beginNewSession();
    }
    notifyListeners();
  }

  Future<void> updateConfig(LpBlocklyAiConfig value) async {
    config = value;
    await config.save();
    notifyListeners();
  }

  /// 更新并保存长期上下文文本。
  Future<void> updateContextText(String text) async {
    contextText = text;
    await LpBlocklyAiContextStore.saveContextText(text);
    notifyListeners();
  }

  /// 更新并保存流程变量约定。
  Future<void> updateFlowVars(LpBlocklyFlowVarsState state) async {
    flowVars = state;
    await LpBlocklyFlowVarsStore.save(state);
    notifyListeners();
  }

  /// 弹窗选择并导入 IO 表 Excel；返回给人看的摘要。
  Future<String> importIoTableFromPicker() async {
    final last = await LpBlocklyIoTableStore.loadLastDir();
    final initial = last ??
        r'D:\Adroid_ws\LpRobt_Flutter\G代码触摸屏改造-0425';
    final path = await LpBlocklyFilePicker.pickXlsxFile(initial);
    if (path == null || path.isEmpty) {
      return '已取消选择文件';
    }
    return importIoTableFromPath(path);
  }

  /// 从指定路径导入 IO 表，合并流程变量并持久化。
  Future<String> importIoTableFromPath(String path) async {
    try {
      final result = await LpBlocklyIoTableParser.parseFile(path);
      ioTable = result;
      await LpBlocklyIoTableStore.save(result);
      await LpBlocklyIoTableStore.saveLastDir(p.dirname(path));

      final incoming = result.toFlowVars();
      if (incoming.isNotEmpty) {
        flowVars = LpBlocklyFlowVarsParser.mergeUpserts(flowVars, incoming);
        await LpBlocklyFlowVarsStore.save(flowVars);
      }

      final summary = StringBuffer()
        ..writeln('已导入 IO 表并完成地址分配。')
        ..writeln()
        ..writeln(result.toSummary())
        ..writeln()
        ..writeln(
          '已写入 ${incoming.length} 项流程变量（待确认）。'
          '回复「确认」后可写流程；或发送「从IO表生成」写入映射函数。',
        );
      statusMessage = 'IO 表已导入';
      notifyListeners();
      return summary.toString().trimRight();
    } catch (e, st) {
      debugPrint('import IO table failed: $e\n$st');
      statusMessage = 'IO 表导入失败';
      notifyListeners();
      return 'IO 表导入失败：$e';
    }
  }

  /// 按已缓存的 IO 表分配结果，生成输入/输出映射到画布。
  Future<void> generateIoMappingFromTable() async {
    if (ioTable.isEmpty || ioTable.localPoints.isEmpty) {
      messages.add(LpBlocklyAiChatMessage(
        id: 'io_${DateTime.now().millisecondsSinceEpoch}',
        kind: LpBlocklyAiMessageKind.assistant,
        content:
            '尚未导入有效 IO 表。请先在设置中「导入 IO 表 Excel」，或发送「导入IO表」。',
      ));
      statusMessage = '缺少 IO 表';
      notifyListeners();
      return;
    }
    await sendMessage('从IO表生成');
  }

  /// 停止当前 Agent 生成（Stop 按钮）。
  Future<void> stopGeneration() async {
    if (!loading) return;
    _runGeneration++;
    loading = false;
    statusMessage = '已停止';
    _finalizeStaleRunningActions(stopped: true);
    notifyListeners();
    await _persistSessionIfNeeded();
  }

  /// 新对话：保存当前会话到历史，再开启空白会话（对齐 Cursor）。
  Future<void> startNewChat() async {
    if (loading) await stopGeneration();
    await _persistCurrentSession();
    await _beginNewSession();
    todos = [];
    lastRawResponse = null;
    lastExtractedXml = null;
    lastParsedPlan = null;
    statusMessage = '描述需求后发送，Agent 将自动完成编程任务。';
    notifyListeners();
  }

  /// 打开历史会话。
  Future<void> openSession(String sessionId) async {
    if (loading || sessionId == _currentSessionId) return;
    await _persistCurrentSession();
    _currentSessionId = sessionId;
    await LpBlocklyAiContextStore.setActiveSessionId(sessionId);
    messages
      ..clear()
      ..addAll(await LpBlocklyAiContextStore.loadSessionMessages(sessionId));
    sessionHistory = await LpBlocklyAiContextStore.listSessions();
    todos = [];
    statusMessage = '已打开：${LpBlocklyAiSessionMeta.titleFromMessages(messages)}';
    notifyListeners();
  }

  /// 删除历史会话。
  Future<void> deleteSession(String sessionId) async {
    if (loading) return;
    final wasActive = sessionId == _currentSessionId;
    await LpBlocklyAiContextStore.deleteSession(sessionId);
    sessionHistory = await LpBlocklyAiContextStore.listSessions();
    if (wasActive) {
      if (sessionHistory.isNotEmpty) {
        await openSession(sessionHistory.first.id);
      } else {
        await _beginNewSession();
        messages.clear();
        todos = [];
        statusMessage = '描述需求后发送，Agent 将自动完成编程任务。';
      }
    }
    notifyListeners();
  }

  /// 兼容旧调用。
  Future<void> clearChat() => startNewChat();

  Future<void> _beginNewSession() async {
    _currentSessionId = LpBlocklyAiContextStore.newSessionId();
    if (config.persistSession) {
      await LpBlocklyAiContextStore.setActiveSessionId(_currentSessionId!);
      sessionHistory = await LpBlocklyAiContextStore.listSessions();
    }
    messages.clear();
  }

  Future<void> _persistCurrentSession() async {
    if (!config.persistSession ||
        _currentSessionId == null ||
        messages.isEmpty) {
      return;
    }
    try {
      await LpBlocklyAiContextStore.saveSessionData(
        sessionId: _currentSessionId!,
        messages: messages,
      );
      sessionHistory = await LpBlocklyAiContextStore.listSessions();
    } catch (e, st) {
      debugPrint('Blockly AI session save failed: $e\n$st');
    }
  }

  /// 构建多轮对话历史（不含当前轮 user 消息）。
  List<LpBlocklyAiChatTurn> buildConversationHistory() {
    final turns = <LpBlocklyAiChatTurn>[];
    for (final msg in messages) {
      switch (msg.kind) {
        case LpBlocklyAiMessageKind.user:
          turns.add(LpBlocklyAiChatTurn(role: 'user', content: msg.content));
        case LpBlocklyAiMessageKind.assistant:
          turns.add(LpBlocklyAiChatTurn(role: 'assistant', content: msg.content));
        case LpBlocklyAiMessageKind.think:
        case LpBlocklyAiMessageKind.action:
          break;
      }
    }

    final maxMessages = config.maxHistoryTurns * 2;
    if (turns.length <= maxMessages) return turns;
    return turns.sublist(turns.length - maxMessages);
  }

  Future<void> sendMessage(String userPrompt) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty || loading) return;

    final history = buildConversationHistory();

    final overview = await _xmlBridge.getWorkspaceOverview();
    final hasWorkspaceContent = overview.ok && overview.topBlocks.isNotEmpty;

    lastAppendIntent = LpBlocklyAiAppendStrategy.resolveIntent(
      userPrompt: prompt,
      conversationHistory: history,
      lastAiTopBlockIds: lastAiTopBlockIds,
      hasWorkspaceContent:
          hasWorkspaceContent || lastAiTopBlockIds.isNotEmpty || history.isNotEmpty,
    );
    final replaceIds = LpBlocklyAiAppendStrategy.idsToReplace(
      config: config,
      intent: lastAppendIntent,
      lastAiTopBlockIds: lastAiTopBlockIds,
      workspaceTopBlocks: overview.ok ? overview.topBlocks : const [],
    );

    messages.add(LpBlocklyAiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      kind: LpBlocklyAiMessageKind.user,
      content: prompt,
    ));

    _finalizeStaleRunningActions();

    // 导入 IO 表：本地弹窗，不走 LLM。
    if (RegExp(r'^(导入|读取|加载)?\s*IO\s*表|导入IO表Excel', caseSensitive: false)
        .hasMatch(prompt)) {
      loading = true;
      statusMessage = '正在选择 IO 表…';
      notifyListeners();
      try {
        final summary = await importIoTableFromPicker();
        messages.add(LpBlocklyAiChatMessage(
          id: 'io_${DateTime.now().millisecondsSinceEpoch}',
          kind: LpBlocklyAiMessageKind.assistant,
          content: summary,
        ));
      } finally {
        loading = false;
        await _persistSessionIfNeeded();
        notifyListeners();
      }
      return;
    }

    final runId = ++_runGeneration;
    loading = true;
    todos = [];
    statusMessage = config.applyMode == LpBlocklyAiApplyMode.append &&
            lastAppendIntent == LpBlocklyAiAppendIntent.modifyPrevious
        ? '追加模式·修正上一轮 AI 块…'
        : 'Agent 正在执行…';
    notifyListeners();

    try {
      final result = await _agent.run(
        userPrompt: prompt,
        config: config,
        service: LpBlocklyAiService.forMode(config.mode),
        conversationHistory: history,
        persistentContext: contextText,
        flowVars: flowVars,
        onFlowVarsChanged: updateFlowVars,
        ioTable: ioTable,
        replaceBlockIdsOnAppend: replaceIds,
        lastAiTopBlockIds: lastAiTopBlockIds,
        appendIntent: lastAppendIntent,
        previousPlan: lastParsedPlan,
        shouldCancel: () => runId != _runGeneration,
      );
      if (runId != _runGeneration) return;
      lastRawResponse = result.rawResponse;
      lastExtractedXml = result.extractedXml;
      statusMessage = result.message;
      if (result.success) {
        if (result.parsedPlan != null) {
          lastParsedPlan =
              jsonDecode(jsonEncode(result.parsedPlan)) as Map<String, dynamic>;
          lastAiTopBlockIds = LpBlocklyAiStructureParser.topBlockIdsFromPlan(
            result.parsedPlan,
          );
        } else if (result.extractedXml != null) {
          lastAiTopBlockIds = LpBlocklyAiStructureParser.topBlockIdsFromXml(
            result.extractedXml,
          );
          final patched = LpBlocklyAiIntentBuilder.tryResolvePatchedPlan(
            prompt: prompt,
            previousPlan: lastParsedPlan,
            history: history,
          );
          if (patched != null) {
            lastParsedPlan =
                jsonDecode(jsonEncode(patched)) as Map<String, dynamic>;
          } else if (lastParsedPlan == null) {
            for (final m in messages) {
              if (m.kind != LpBlocklyAiMessageKind.user) continue;
              final rebuilt = LpBlocklyAiIntentBuilder.tryBuildCanonicalPlan(
                m.content,
              );
              if (rebuilt != null) {
                lastParsedPlan =
                    jsonDecode(jsonEncode(rebuilt)) as Map<String, dynamic>;
                break;
              }
            }
          }
        }
      }
    } catch (e, st) {
      if (runId != _runGeneration) return;
      debugPrint('Blockly AI agent failed: $e\n$st');
      statusMessage = '执行失败：$e';
      messages.add(LpBlocklyAiChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        kind: LpBlocklyAiMessageKind.assistant,
        content: '执行失败：$e',
      ));
    } finally {
      if (runId == _runGeneration) {
        loading = false;
      }
      await _persistSessionIfNeeded();
      notifyListeners();
    }
  }

  Future<void> generate(String userPrompt) => sendMessage(userPrompt);

  void toggleThinkCollapsed(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;
    final msg = messages[index];
    if (msg.kind != LpBlocklyAiMessageKind.think) return;
    messages[index] = msg.copyWith(collapsed: !msg.collapsed);
    notifyListeners();
    unawaited(_persistSessionIfNeeded());
  }

  Future<void> _persistSessionIfNeeded() async {
    await _persistCurrentSession();
  }

  void _handleAgentEvent(LpBlocklyAiAgentEvent event) {
    if (event.todos != null) {
      todos = List.of(event.todos!);
    }
    if (event.todoId != null && event.todoStatus != null) {
      todos = todos
          .map((t) => t.id == event.todoId
              ? t.copyWith(status: event.todoStatus)
              : t)
          .toList();
    }
    if (event.message != null) {
      messages.add(event.message!);
    }
    final patch = event.messageUpdate;
    if (patch != null) {
      final index = messages.lastIndexWhere((m) => m.id == patch.messageId);
      if (index >= 0) {
        messages[index] = messages[index].copyWith(
          content: patch.content,
          actionStatus: patch.actionStatus,
        );
      }
    }
    notifyListeners();
  }

  /// 新一轮执行前，将上一轮未结束的 action 标记为已跳过，避免转圈残留。
  void _finalizeStaleRunningActions({bool stopped = false}) {
    var changed = false;
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.kind == LpBlocklyAiMessageKind.action &&
          msg.actionStatus == LpBlocklyAiActionStatus.running) {
        messages[i] = msg.copyWith(
          content: stopped
              ? '${msg.content}\n（已停止）'
              : '${msg.content}\n（已被新一轮任务取代）',
          actionStatus: LpBlocklyAiActionStatus.failed,
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
