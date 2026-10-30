import 'dart:convert';

import 'lp_blockly_ai_append_strategy.dart';
import 'lp_blockly_ai_config.dart';
import 'lp_blockly_ai_intent_builder.dart';
import 'lp_blockly_ai_llm.dart';
import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_pipeline.dart';
import 'lp_blockly_ai_prompt.dart';
import 'lp_blockly_ai_service.dart';
import 'lp_blockly_ai_structure_parser.dart';
import 'lp_blockly_ai_tool_executor.dart';
import 'lp_blockly_xml_bridge.dart';

/// Tool Loop 过程日志。
class LpBlocklyAiToolLoopEvent {
  const LpBlocklyAiToolLoopEvent({
    required this.label,
    this.done = false,
    this.failed = false,
    this.think = false,
  });

  final String label;
  final bool done;
  final bool failed;
  final bool think;
}

/// 将模型 tool 参数规范成 {blocks:[...]} 计划。
Map<String, dynamic>? lpBlocklyAiCoercePlan(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return lpBlocklyAiCoercePlan(LpBlocklyAiStructureParser.extractJson(text) ?? _tryDecodeMap(text));
  }
  if (raw is! Map) return null;
  final map = raw.map((k, v) => MapEntry(k.toString(), v));
  if (map['blocks'] is List) return map;
  if (map['plan'] != null) return lpBlocklyAiCoercePlan(map['plan']);
  if (map['arguments'] != null) return lpBlocklyAiCoercePlan(map['arguments']);
  return null;
}

Map<String, dynamic>? _tryDecodeMap(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return null;
}

/// LLM 多工具循环：apply_plan → verify_gcode，失败则把错误喂回模型再改。
class LpBlocklyAiToolLoop {
  LpBlocklyAiToolLoop({
    required LpBlocklyAiService service,
    required this.onEvent,
  }) : _service = service;

  final LpBlocklyAiService _service;
  final void Function(LpBlocklyAiToolLoopEvent event) onEvent;

  Future<LpBlocklyAiPipelineResult> run({
    required String userPrompt,
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiChatTurn> conversationHistory,
    required String systemPrompt,
    required Future<String> Function() getWorkspaceOverview,
    required Future<String> Function() getToolboxCatalog,
    required Future<LpBlocklyAiToolStepResult> Function(Map<String, dynamic> plan)
        applyPlan,
    required Future<LpBlocklyGCodeVerifyResult> Function() verifyGCode,
    bool Function()? shouldCancel,
  }) async {
    final messages = <LpBlocklyAiLlmTurn>[
      LpBlocklyAiLlmTurn(role: 'system', content: systemPrompt),
      for (final turn in conversationHistory)
        if (turn.content.trim().isNotEmpty)
          LpBlocklyAiLlmTurn(role: turn.role, content: turn.content),
      LpBlocklyAiLlmTurn(
        role: 'user',
        content: LpBlocklyAiPrompt.buildToolLoopUserMessage(userPrompt),
      ),
    ];

    Map<String, dynamic>? lastPlan;
    String? lastXml;
    var applied = false;
    var verifyOk = false;
    String? lastVerifyError;
    var applyAttempts = 0;
    final maxApply = config.maxRetries + 1;
    final maxTurns = (maxApply * 5).clamp(8, 20);

    for (var turn = 1; turn <= maxTurns; turn++) {
      if (shouldCancel?.call() == true) {
        return const LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.collectContext,
          message: '已停止',
        );
      }

      onEvent(LpBlocklyAiToolLoopEvent(label: 'LLM Tool Loop 第 $turn 轮…'));
      LpBlocklyAiLlmCompletion completion;
      try {
        completion = await _service.completeTurn(
          config: config,
          messages: messages,
          tools: LpBlocklyAiLlmCodec.openAiTools,
        );
      } on LpBlocklyAiException catch (e) {
        onEvent(LpBlocklyAiToolLoopEvent(label: e.message, failed: true));
        return LpBlocklyAiPipelineResult(
          success: false,
          stage: LpBlocklyAiPipelineStage.generate,
          message: e.message,
          parsedPlan: lastPlan,
          extractedXml: lastXml,
        );
      }
      onEvent(LpBlocklyAiToolLoopEvent(
        label: completion.hasToolCalls
            ? '模型调用 ${completion.toolCalls.map((c) => c.name).join(", ")}'
            : '模型未调工具，尝试从正文解析计划',
        done: true,
      ));

      var calls = completion.toolCalls;
      if (calls.isEmpty) {
        final fromText = lpBlocklyAiCoercePlan(completion.content);
        if (fromText != null) {
          calls = [
            LpBlocklyAiToolCall(
              id: 'fallback_apply_$turn',
              name: 'apply_plan',
              argumentsJson: jsonEncode(fromText),
            ),
          ];
        }
      }

      if (calls.isEmpty) {
        final text = completion.content.trim();
        if (applied && !verifyOk) {
          messages.add(LpBlocklyAiLlmTurn(
            role: 'user',
            content:
                'GCode 仍未通过：${lastVerifyError ?? "未知"}。请调用 apply_plan 提交修正后的完整 JSON 计划，然后 verify_gcode。',
          ));
          continue;
        }
        if (applied && verifyOk) {
          onEvent(LpBlocklyAiToolLoopEvent(
            think: true,
            label: text.isEmpty ? '工具循环完成' : text,
          ));
          break;
        }
        messages.add(LpBlocklyAiLlmTurn(
          role: 'assistant',
          content: text.isEmpty ? '（无内容）' : text,
        ));
        messages.add(const LpBlocklyAiLlmTurn(
          role: 'user',
          content: '请调用 apply_plan 提交 {blocks:[...]} JSON 计划，不要只回复说明。',
        ));
        continue;
      }

      messages.add(LpBlocklyAiLlmTurn(
        role: 'assistant',
        content: completion.content.isEmpty ? null : completion.content,
        toolCalls: calls,
      ));

      var appliedThisRound = false;
      for (final call in calls) {
        if (shouldCancel?.call() == true) {
          return const LpBlocklyAiPipelineResult(
            success: false,
            stage: LpBlocklyAiPipelineStage.collectContext,
            message: '已停止',
          );
        }
        onEvent(LpBlocklyAiToolLoopEvent(label: 'tool:${call.name} 执行中…'));
        final payload = await _executeTool(
          call: call,
          getWorkspaceOverview: getWorkspaceOverview,
          getToolboxCatalog: getToolboxCatalog,
          applyPlan: (plan) async {
            if (applyAttempts >= maxApply) {
              return const LpBlocklyAiToolStepResult(
                success: false,
                message: '已达到 apply_plan 重试上限',
              );
            }
            applyAttempts++;
            return applyPlan(plan);
          },
          verifyGCode: verifyGCode,
          onPlan: (plan, xml) {
            lastPlan = plan;
            lastXml = xml;
          },
        );
        if (call.name == 'apply_plan') {
          appliedThisRound = payload.applied;
          if (payload.applied) applied = true;
        }
        if (call.name == 'verify_gcode') {
          verifyOk = payload.verifyOk;
          lastVerifyError = payload.verifyOk ? null : payload.content;
        }
        onEvent(LpBlocklyAiToolLoopEvent(
          label: 'tool:${call.name} ${payload.content}',
          done: !payload.failed,
          failed: payload.failed,
        ));
        messages.add(LpBlocklyAiLlmTurn(
          role: 'tool',
          toolCallId: call.id,
          name: call.name,
          content: payload.content,
        ));
      }

      if (appliedThisRound &&
          !calls.any((c) => c.name == 'verify_gcode')) {
        onEvent(const LpBlocklyAiToolLoopEvent(label: 'apply 后自动校验 GCode…'));
        final verify = await verifyGCode();
        verifyOk = verify.ok;
        lastVerifyError = verify.ok ? null : (verify.message ?? '校验失败');
        final autoId = 'auto_verify_$turn';
        messages.add(LpBlocklyAiLlmTurn(
          role: 'assistant',
          toolCalls: [
            LpBlocklyAiToolCall(
              id: autoId,
              name: 'verify_gcode',
              argumentsJson: '{}',
            ),
          ],
        ));
        messages.add(LpBlocklyAiLlmTurn(
          role: 'tool',
          toolCallId: autoId,
          name: 'verify_gcode',
          content: _verifyPayload(verify),
        ));
        onEvent(LpBlocklyAiToolLoopEvent(
          label: verify.ok
              ? 'GCode 校验通过'
              : 'GCode 校验失败：${verify.message ?? ""}',
          done: verify.ok,
          failed: !verify.ok,
        ));
      }

      if (verifyOk && applied) break;
      if (applied && !verifyOk && applyAttempts >= maxApply) break;
    }

    if (applied && verifyOk) {
      return LpBlocklyAiPipelineResult(
        success: true,
        stage: LpBlocklyAiPipelineStage.apply,
        message: 'Tool Loop 已写入画布并通过 GCode 校验',
        parsedPlan: lastPlan,
        extractedXml: lastXml,
      );
    }
    if (applied && !verifyOk) {
      return LpBlocklyAiPipelineResult(
        success: false,
        stage: LpBlocklyAiPipelineStage.validate,
        message: lastVerifyError ?? 'GCode 校验未通过',
        parsedPlan: lastPlan,
        extractedXml: lastXml,
      );
    }
    return LpBlocklyAiPipelineResult(
      success: false,
      stage: LpBlocklyAiPipelineStage.generate,
      message: 'Tool Loop 未提交有效 apply_plan',
      parsedPlan: lastPlan,
      extractedXml: lastXml,
    );
  }

  Future<_ToolPayload> _executeTool({
    required LpBlocklyAiToolCall call,
    required Future<String> Function() getWorkspaceOverview,
    required Future<String> Function() getToolboxCatalog,
    required Future<LpBlocklyAiToolStepResult> Function(Map<String, dynamic> plan)
        applyPlan,
    required Future<LpBlocklyGCodeVerifyResult> Function() verifyGCode,
    required void Function(Map<String, dynamic> plan, String? xml) onPlan,
  }) async {
    try {
      switch (call.name) {
        case 'get_workspace_overview':
          return _ToolPayload(content: await getWorkspaceOverview());
        case 'get_toolbox_catalog':
          return _ToolPayload(content: await getToolboxCatalog());
        case 'apply_plan':
          final plan = lpBlocklyAiCoercePlan(call.argumentsJson);
          if (plan == null) {
            return const _ToolPayload(
              content: 'apply_plan 参数无效：需要 {blocks:[...]}',
              failed: true,
            );
          }
          final normalized = LpBlocklyAiStructureParser.normalizePlan(plan);
          final error = LpBlocklyAiStructureParser.validatePlan(normalized);
          if (error != null) {
            return _ToolPayload(content: '计划校验失败：$error', failed: true);
          }
          final xml = LpBlocklyAiStructureParser.toXml(normalized);
          final result = await applyPlan(normalized);
          if (result.success) {
            onPlan(normalized, xml);
            return _ToolPayload(
              content: result.message,
              applied: true,
            );
          }
          return _ToolPayload(content: result.message, failed: true);
        case 'verify_gcode':
          final verify = await verifyGCode();
          return _ToolPayload(
            content: _verifyPayload(verify),
            verifyOk: verify.ok,
            failed: !verify.ok,
          );
        default:
          return _ToolPayload(content: '未知工具：${call.name}', failed: true);
      }
    } catch (e) {
      return _ToolPayload(content: '工具异常：$e', failed: true);
    }
  }

  String _verifyPayload(LpBlocklyGCodeVerifyResult verify) {
    if (verify.ok) {
      final preview = verify.preview?.trim();
      if (preview != null && preview.isNotEmpty) {
        final short = preview.length > 240 ? '${preview.substring(0, 240)}…' : preview;
        return jsonEncode({'ok': true, 'preview': short});
      }
      return jsonEncode({'ok': true});
    }
    return jsonEncode({'ok': false, 'error': verify.message ?? '校验失败'});
  }
}

class _ToolPayload {
  const _ToolPayload({
    required this.content,
    this.failed = false,
    this.applied = false,
    this.verifyOk = false,
  });

  final String content;
  final bool failed;
  final bool applied;
  final bool verifyOk;
}

/// Agent 侧组装 apply 闭包（追加坐标 / 保护块）。
Future<LpBlocklyAiToolStepResult> lpBlocklyAiApplyPlanForLoop({
  required LpBlocklyAiToolExecutor executor,
  required LpBlocklyXmlBridge xmlBridge,
  required Map<String, dynamic> plan,
  required LpBlocklyAiConfig config,
  required LpBlocklyAiAppendIntent appendIntent,
  required List<String> replaceBlockIdsOnAppend,
  required String userPrompt,
}) async {
  var mutable = Map<String, dynamic>.from(jsonDecode(jsonEncode(plan)) as Map);
  LpBlocklyAiIntentBuilder.enrichPlanFromPrompt(userPrompt, mutable);
  mutable = LpBlocklyAiStructureParser.normalizePlan(mutable);
  if (config.applyMode == LpBlocklyAiApplyMode.append &&
      appendIntent == LpBlocklyAiAppendIntent.addNew) {
    final overview = await xmlBridge.getWorkspaceOverview();
    if (overview.ok) {
      LpBlocklyAiStructureParser.prepareAppendPlacement(
        mutable,
        existingTopBlocks: overview.topBlocks,
      );
    }
  }
  return executor.applyPlanWithSteps(
    plan: mutable,
    applyMode: config.applyMode,
    replaceBlockIdsOnAppend:
        appendIntent == LpBlocklyAiAppendIntent.addNew
            ? const []
            : replaceBlockIdsOnAppend,
    modifyPrevious: appendIntent == LpBlocklyAiAppendIntent.modifyPrevious,
    userPrompt: userPrompt,
    onStep: (_, {bool done = false, bool failed = false}) {},
  );
}
