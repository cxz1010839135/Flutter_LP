import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_append_strategy.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_config.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_flow_vars.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_intent_builder.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_protected_blocks.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_request_router.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_service.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_motion_plan.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_ai_structure_parser.dart';
import 'package:flutter_application_1/blockly/ai/lp_blockly_xml_bridge.dart';

void main() {
  test('追加模式多轮生成默认纯新增，不误走修正', () {
    final intent = LpBlocklyAiAppendStrategy.resolveIntent(
      userPrompt: '帮我写个流程 机械手先走到P1点打开真空1 走到p2',
      conversationHistory: const [
        LpBlocklyAiChatTurn(role: 'user', content: '你好'),
        LpBlocklyAiChatTurn(role: 'assistant', content: '你好'),
      ],
      lastAiTopBlockIds: const ['ai_if_old'],
      hasWorkspaceContent: true,
    );
    expect(intent, LpBlocklyAiAppendIntent.addNew);
  });

  test('再帮我写个流程走纯追加，不修正上一轮', () {
    final intent = LpBlocklyAiAppendStrategy.resolveIntent(
      userPrompt: '再帮我写个流程 启动信号M99 去P3开真空再去P4',
      conversationHistory: const [
        LpBlocklyAiChatTurn(role: 'user', content: '帮我写个流程去P1开真空去P2'),
        LpBlocklyAiChatTurn(role: 'assistant', content: '已生成'),
      ],
      lastAiTopBlockIds: const ['ai_proc_old'],
      hasWorkspaceContent: true,
    );
    expect(intent, LpBlocklyAiAppendIntent.addNew);
    expect(
      LpBlocklyAiAppendStrategy.idsToReplace(
        config: const LpBlocklyAiConfig(),
        intent: intent,
        lastAiTopBlockIds: const ['ai_proc_old'],
      ),
      isEmpty,
    );
  });

  test('追加纯新增时错开坐标并避免重名', () {
    final plan = <String, dynamic>{
      'blocks': [
        {
          'type': 'procedures_defnoreturn',
          'id': 'ai_proc_new',
          'x': 80,
          'y': 80,
          'fields': {'NAME': 'S10自动流程-P1P2'},
        },
      ],
    };
    LpBlocklyAiStructureParser.prepareAppendPlacement(
      plan,
      existingTopBlocks: const [
        LpBlocklyTopBlockInfo(
          id: 'ai_proc_old',
          type: 'procedures_defnoreturn',
          text: '至 S10自动流程-P1P2',
          x: 80,
          y: 100,
        ),
      ],
    );
    final block = plan['blocks']![0] as Map;
    expect(block['fields']['NAME'], 'S10自动流程-P1P2-2');
    expect(block['y'] as int, greaterThan(100));
  });

  test('仅 ai_ 顶层块可被替换，单块非 ai 不替换', () {
    final ids = LpBlocklyAiAppendStrategy.fallbackIdsFromTopBlocks(
      const [
        LpBlocklyTopBlockInfo(
          id: 'proc_main',
          type: 'procedures_defnoreturn',
          text: 'S10自动流程',
        ),
      ],
      intent: LpBlocklyAiAppendIntent.modifyPrevious,
    );
    expect(ids, isEmpty);
  });

  test('真空取放流程生成完整 DO0 链', () {
    const flowVars = LpBlocklyFlowVarsState(
      vars: [
        LpBlocklyFlowVar(
          id: 'step_S10',
          symbol: 'S10',
          kind: 'step',
          meaning: '步序',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'reg_M16',
          symbol: 'M16',
          kind: 'register',
          meaning: '自动使能',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'reg_D9000',
          symbol: 'D9000',
          kind: 'register',
          meaning: '运动完成',
          confirmed: true,
        ),
      ],
    );

    final plan = LpBlocklyAiIntentBuilder.tryBuildVacuumPickPlacePlan(
      '帮我写个流程 机械手先走到P1点打开真空1 确认真空1打开并且机械手完全停止 机械手走到p2',
      flowVars: flowVars,
    );
    expect(plan, isNotNull);

    final err = LpBlocklyAiStructureParser.validatePlan(plan!);
    expect(err, isNull);

    final xml = LpBlocklyAiStructureParser.toXml(plan);
    expect(xml, isNotNull);

    String readParaFrom(String source, String blockId, String op) {
      final block =
          LpBlocklyAiMotionPlan.extractMotionBlockXmlById(source, blockId) ?? '';
      for (var i = 0; i < 8; i++) {
        if (!block.contains('<field name="OP$i">$op</field>')) continue;
        final m = RegExp(
          r'<value name="PARA' +
              i.toString() +
              r'"[\s\S]*?<field name="NUM">([^<]*)</field>',
        ).firstMatch(block);
        return m?.group(1) ?? '';
      }
      return '';
    }

    final motionIds = RegExp(
      r'<block type="motion_moveptp_point" id="(ai_door_p[12]_[^"]+)"',
    ).allMatches(xml!).map((m) => m.group(1)!).toList();
    expect(motionIds.length, 2);
    final p1Id = motionIds.firstWhere((id) => id.contains('ai_door_p1'));
    final p2Id = motionIds.firstWhere((id) => id.contains('ai_door_p2'));
    expect(readParaFrom(xml, p1Id, 'AvoidPoint'), '1');
    expect(readParaFrom(xml, p2Id, 'AvoidPoint'), '2');
    expect(xml, contains('procedures_defnoreturn'));
    expect(xml, contains('S10自动流程-'));
    expect(xml, contains('motion_moveptp_point'));
    expect(xml, contains('Variable_Name">M</field>'));
    expect(
      RegExp(r'<block type="controls_if"').allMatches(xml).length,
      greaterThanOrEqualTo(4),
    );

    final repaired = LpBlocklyAiIntentBuilder.repairXmlFromPrompt(
      xml,
      '帮我写个流程 机械手先走到P1点打开真空1 确认真空1打开并且机械手完全停止 机械手走到p2',
    );
    expect(readParaFrom(repaired, p1Id, 'AvoidPoint'), '1');
    expect(readParaFrom(repaired, p1Id, 'HeightAvoid'), '10');
    expect(readParaFrom(repaired, p1Id, 'MaxSpeed'), '2500');
    expect(readParaFrom(repaired, p2Id, 'AvoidPoint'), '2');
    expect(readParaFrom(repaired, p2Id, 'HeightAvoid'), '10');
    expect(readParaFrom(repaired, p2Id, 'MaxSpeed'), '2500');
  });

  test('按动作顺序：M99门控 P1→等完成→开真空→延时1s→P2→等完成→关真空', () {
    const flowVars = LpBlocklyFlowVarsState(
      vars: [
        LpBlocklyFlowVar(
          id: 'step_S10',
          symbol: 'S10',
          kind: 'step',
          meaning: '步序',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'reg_D9000',
          symbol: 'D9000',
          kind: 'register',
          meaning: '运动完成',
          confirmed: true,
        ),
      ],
    );

    const prompt = '帮我写个流程 启动信号是M99 当我启动信号等于1的时候 我所有流程才能启动 '
        '然后机械手先去P1 等待动作完成 打开真空1 然后 等待1s 然后机械手去P2 '
        '等待机械手完成 关闭真空1';

    final plan = LpBlocklyAiIntentBuilder.tryBuildVacuumPickPlacePlan(
      prompt,
      flowVars: flowVars,
    );
    expect(plan, isNotNull);
    expect(LpBlocklyAiStructureParser.validatePlan(plan!), isNull);

    final xml = LpBlocklyAiStructureParser.toXml(plan)!;
    expect(xml, contains('id="ai_door_p1_'));
    expect(xml, contains('id="ai_door_p2_'));
    expect(xml, contains('开真空1'));
    expect(xml, contains('关真空1'));
    expect(xml, contains('延时 1000ms'));
    // 启动信号 M99 应出现在条件里
    expect(xml, contains('<field name="NUM">99</field>'));
    // 关真空写 0
    expect(xml, contains('id="ai_m_vac_off_1_'));
    // Blockly 定时器写法：步内持续 T0=1000，再嵌套判断 T0 成立跳步
    expect(xml, contains('Variable_Name">T</field>'));
    expect(xml, contains('id="ai_if_t_done_'));
    expect(xml, contains('thread_get_bitT'));
    expect(xml, contains('ACTIVE_Data">TUP</field>'));
    expect(xml, isNot(contains('ai_cmp_t_')));
    expect(xml, contains('<field name="NUM">1000</field>'));

    final vacOff = RegExp(
      r'id="ai_m_vac_off_1_[^"]+"[\s\S]*?Variable_Value"[\s\S]*?<field name="NUM">([^<]*)</field>',
    ).firstMatch(xml);
    expect(vacOff?.group(1), '0');

    // 步数：入口 + 去P1 + 等完成 + 开真空 + 延时 + 去P2 + 等完成 + 关真空 = 8
    expect(
      RegExp(r'<block type="controls_if"').allMatches(xml).length,
      greaterThanOrEqualTo(8),
    );
  });

  test('IO 映射顶层块不可被替换列表选中', () {
    final ids = LpBlocklyAiAppendStrategy.fallbackIdsFromTopBlocks(
      const [
        LpBlocklyTopBlockInfo(
          id: 'ai_io_proc_0',
          type: 'procedures_defnoreturn',
          text: '本体输入IO',
        ),
        LpBlocklyTopBlockInfo(
          id: 'ai_io_proc_1',
          type: 'procedures_defnoreturn',
          text: '本体输出IO',
        ),
        LpBlocklyTopBlockInfo(
          id: 'ai_proc_flow',
          type: 'procedures_defnoreturn',
          text: 'S10自动流程-取放盘',
        ),
      ],
      intent: LpBlocklyAiAppendIntent.modifyPrevious,
    );
    expect(ids, ['ai_proc_flow']);
    expect(LpBlocklyAiProtectedBlocks.isProtectedTopBlockId('ai_io_proc_0'), isTrue);
  });

  test('默认配置追加模式不自动替换上一轮', () {
    const config = LpBlocklyAiConfig();
    expect(config.replacePreviousIfOnAppend, isFalse);
    expect(
      LpBlocklyAiAppendStrategy.shouldReplacePrevious(
        config: config,
        intent: LpBlocklyAiAppendIntent.addNew,
      ),
      isFalse,
    );
  });

  test('写流程话术不误判为登记变量', () {
    final kind = LpBlocklyAiRequestRouter.classify(
      prompt: '写个流程 等待自动启动信号M10，机械手运动到p1，打开真空1，'
          '等待机械手动作完成并且判断真空打开，机械手运动到p19 再去到p2',
    );
    expect(kind, LpBlocklyAiRequestKind.generate);

    final vars = LpBlocklyFlowVarsParser.parse(
      '写个流程 等待自动启动信号M10，机械手运动到p1，打开真空1',
    );
    expect(vars.kind, LpBlocklyFlowVarsIntentKind.none);
  });

  test('多点真空流程按顺序生成 P1→P19→P2', () {
    const flowVars = LpBlocklyFlowVarsState(
      vars: [
        LpBlocklyFlowVar(
          id: 'step_S10',
          symbol: 'S10',
          kind: 'step',
          meaning: '步序',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'reg_M800',
          symbol: 'M800',
          kind: 'register',
          meaning: '自动使能',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'reg_D9000',
          symbol: 'D9000',
          kind: 'register',
          meaning: '运动完成',
          confirmed: true,
        ),
      ],
    );

    final plan = LpBlocklyAiIntentBuilder.tryBuildVacuumPickPlacePlan(
      '写个流程 等待自动启动信号M10，机械手运动到p1，打开真空1，'
      '等待机械手动作完成并且判断真空打开，机械手运动到p19 等待机械手运动完成再去到p2',
      flowVars: flowVars,
    );
    expect(plan, isNotNull);
    expect(LpBlocklyAiStructureParser.validatePlan(plan!), isNull);

    final xml = LpBlocklyAiStructureParser.toXml(plan)!;
    expect(xml, contains('id="ai_door_p1_'));
    expect(xml, contains('id="ai_door_p19_'));
    expect(xml, contains('id="ai_door_p2_'));
    // 入口用话术启动信号 M10
    expect(xml, contains('Variable_Name">M</field>'));
    expect(
      RegExp(r'<block type="controls_if"').allMatches(xml).length,
      greaterThanOrEqualTo(6),
    );

    final p1 = LpBlocklyAiMotionPlan.extractMotionBlockXmlById(
      xml,
      RegExp(r'ai_door_p1_\d+').firstMatch(xml)!.group(0)!,
    )!;
    final p19 = LpBlocklyAiMotionPlan.extractMotionBlockXmlById(
      xml,
      RegExp(r'ai_door_p19_\d+').firstMatch(xml)!.group(0)!,
    )!;
    final p2 = LpBlocklyAiMotionPlan.extractMotionBlockXmlById(
      xml,
      RegExp(r'ai_door_p2_\d+').firstMatch(xml)!.group(0)!,
    )!;
    expect(p1, contains('<field name="NUM">1</field>'));
    expect(p19, contains('<field name="NUM">19</field>'));
    expect(p2, contains('<field name="NUM">2</field>'));
  });

  test('带顺序提示词的真空话术不回退固定两点模板', () {
    const flowVars = LpBlocklyFlowVarsState(
      vars: [
        LpBlocklyFlowVar(
          id: 'step_S10',
          symbol: 'S10',
          kind: 'step',
          meaning: '步序',
          confirmed: true,
        ),
      ],
    );

    final plan = LpBlocklyAiIntentBuilder.tryBuildVacuumPickPlacePlan(
      '帮我写个流程 启动信号M99 先去P1 然后开真空1 再去P2 最后关闭真空1',
      flowVars: flowVars,
    );
    expect(plan, isNotNull);

    final xml = LpBlocklyAiStructureParser.toXml(plan!)!;
    expect(xml, contains('关真空1'));
    expect(xml, isNot(contains('取放盘流程')));
    expect(xml, contains('S10自动流程-P1P2'));
  });

  test('仅待确认点位不阻塞流程生成', () {
    const state = LpBlocklyFlowVarsState(
      vars: [
        LpBlocklyFlowVar(
          id: 'reg_M800',
          symbol: 'M800',
          kind: 'register',
          meaning: '自动使能',
          confirmed: true,
        ),
        LpBlocklyFlowVar(
          id: 'point_P1',
          symbol: 'P1',
          kind: 'point',
          meaning: '取料点',
          confirmed: false,
        ),
      ],
    );
    expect(
      LpBlocklyFlowVarsParser.shouldGateGenerate(
        prompt: '写个流程走到P1打开真空再走P2',
        state: state,
      ),
      isFalse,
    );
  });
}
