import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_config.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_llm.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_pipeline.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_service.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_tool_executor.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_tool_loop.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_xml_bridge.dart';

void main() {
  test('coercePlan 支持 blocks / plan 包装 / JSON 字符串', () {
    expect(
      lpBlocklyAiCoercePlan({
        'blocks': [
          {'type': 'math_variable', 'id': 'a'},
        ],
      })?['blocks'],
      isNotEmpty,
    );
    expect(
      lpBlocklyAiCoercePlan({
        'plan': {
          'blocks': [
            {'type': 'math_variable', 'id': 'a'},
          ],
        },
      })?['blocks'],
      isNotEmpty,
    );
    expect(
      lpBlocklyAiCoercePlan(
        '{"blocks":[{"type":"math_variable","id":"a"}]}',
      )?['blocks'],
      isNotEmpty,
    );
  });

  test('解析 OpenAI tool_calls', () {
    final parsed = LpBlocklyAiLlmCodec.parseOpenAiMessage({
      'content': '',
      'tool_calls': [
        {
          'id': 'call_1',
          'type': 'function',
          'function': {
            'name': 'apply_plan',
            'arguments': '{"blocks":[{"type":"math_variable","id":"a"}]}',
          },
        },
      ],
    });
    expect(parsed.hasToolCalls, isTrue);
    expect(parsed.toolCalls.single.name, 'apply_plan');
    expect(lpBlocklyAiCoercePlan(parsed.toolCalls.single.argumentsJson), isNotNull);
  });

  test('Tool Loop 在 GCode 失败后再次 apply_plan', () async {
    final planJson =
        '{"blocks":[{"type":"math_variable","id":"ai_assign_1","x":80,"y":80,'
        '"fields":{"Variable_Name":"D"},'
        '"inputs":{'
        '"Variable_Idx":{"shadow":{"type":"math_number","fields":{"NUM":"400"}}},'
        '"Variable_Value":{"shadow":{"type":"math_number","fields":{"NUM":"4"}}}'
        '}}]}';
    final service = _ScriptedService([
      LpBlocklyAiLlmCompletion(
        toolCalls: [
          LpBlocklyAiToolCall(
            id: 'c1',
            name: 'apply_plan',
            argumentsJson: planJson,
          ),
        ],
      ),
      LpBlocklyAiLlmCompletion(
        toolCalls: [
          LpBlocklyAiToolCall(
            id: 'c2',
            name: 'apply_plan',
            argumentsJson: planJson,
          ),
        ],
      ),
    ]);
    var applyCount = 0;
    var verifyCount = 0;
    final loop = LpBlocklyAiToolLoop(
      service: service,
      onEvent: (_) {},
    );
    final result = await loop.run(
      userPrompt: 'D400=4',
      config: const LpBlocklyAiConfig(maxRetries: 2),
      conversationHistory: const [],
      systemPrompt: 'test',
      getWorkspaceOverview: () async => '{"ok":true}',
      getToolboxCatalog: () async => 'catalog',
      applyPlan: (plan) async {
        applyCount++;
        expect(plan['blocks'], isNotEmpty);
        return const LpBlocklyAiToolStepResult(success: true, message: '已载入');
      },
      verifyGCode: () async {
        verifyCount++;
        if (verifyCount == 1) {
          return const LpBlocklyGCodeVerifyResult(ok: false, message: '缺连接');
        }
        return const LpBlocklyGCodeVerifyResult(ok: true, preview: 'G90');
      },
    );
    expect(result.success, isTrue);
    expect(applyCount, 2);
    expect(verifyCount, 2);
    expect(result.stage, LpBlocklyAiPipelineStage.apply);
  });
}

class _ScriptedService implements LpBlocklyAiService {
  _ScriptedService(this.replies);

  final List<LpBlocklyAiLlmCompletion> replies;
  var _i = 0;

  @override
  Future<String> complete({
    required LpBlocklyAiConfig config,
    required String systemPrompt,
    required String userMessage,
    List<LpBlocklyAiChatTurn> history = const [],
  }) async {
    return '';
  }

  @override
  Future<LpBlocklyAiLlmCompletion> completeTurn({
    required LpBlocklyAiConfig config,
    required List<LpBlocklyAiLlmTurn> messages,
    List<Map<String, dynamic>> tools = const [],
  }) async {
    if (_i >= replies.length) {
      return const LpBlocklyAiLlmCompletion(content: 'done');
    }
    return replies[_i++];
  }
}
