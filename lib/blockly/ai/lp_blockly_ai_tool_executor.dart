import 'lp_blockly_ai_mode.dart';
import 'lp_blockly_ai_structure_parser.dart';
import 'lp_blockly_xml_bridge.dart';

/// 单步 Tool 执行结果。
class LpBlocklyAiToolStepResult {
  const LpBlocklyAiToolStepResult({
    required this.success,
    required this.message,
    this.blockType,
  });

  final bool success;
  final String message;
  final String? blockType;
}

/// Tool Call 执行器：修正模式先移除旧块，再**一次性**载入完整 XML（避免逐块追加散架）。
class LpBlocklyAiToolExecutor {
  LpBlocklyAiToolExecutor(this._bridge);

  final LpBlocklyXmlBridge _bridge;

  Future<LpBlocklyAiToolStepResult> applyPlanWithSteps({
    required Map<String, dynamic> plan,
    required LpBlocklyAiApplyMode applyMode,
    List<String> replaceBlockIdsOnAppend = const [],
    bool modifyPrevious = false,
    String? userPrompt,
    required void Function(String label, {bool done, bool failed}) onStep,
  }) async {
    final blocks = plan['blocks'];
    if (blocks is! List || blocks.isEmpty) {
      return const LpBlocklyAiToolStepResult(
        success: false,
        message: '计划中无 blocks',
      );
    }

    if (applyMode == LpBlocklyAiApplyMode.replace) {
      onStep('tool:clear_workspace 清空画布…');
      final cleared = await _bridge.clearWorkspace();
      if (!cleared.ok) {
        onStep('tool:clear_workspace 失败：${cleared.message}', failed: true);
        return LpBlocklyAiToolStepResult(
          success: false,
          message: cleared.message ?? '清空画布失败',
        );
      }
      onStep('tool:clear_workspace 完成', done: true);
    } else if (modifyPrevious || replaceBlockIdsOnAppend.isNotEmpty) {
      onStep('tool:remove_previous_ai 清理 AI 顶层块…');
      final removed = await _bridge.removeAllAiTopBlocks();
      if (!removed.ok) {
        onStep(
          'tool:remove_previous_ai 失败：${removed.message}',
          failed: true,
        );
        return LpBlocklyAiToolStepResult(
          success: false,
          message: removed.message ?? '清理 AI 块失败',
        );
      }
      final hint = removed.removed > 0
          ? '已清理 ${removed.removed} 个 AI 顶层块'
          : '画布无 AI 顶层块，继续写入';
      onStep('tool:remove_previous_ai $hint', done: true);
    }

    final topTypes = <String>[];
    for (final item in blocks) {
      if (item is Map) {
        topTypes.add(item['type']?.toString() ?? '?');
      }
    }
    onStep(
      'tool:apply_plan 载入完整程序（顶层 ${blocks.length} 块：${topTypes.join(", ")}）…',
    );

    final xml = LpBlocklyAiStructureParser.toXml(plan);
    if (xml == null) {
      onStep('tool:apply_plan 失败：JSON 转 XML 失败', failed: true);
      return const LpBlocklyAiToolStepResult(
        success: false,
        message: '完整计划转 XML 失败',
      );
    }

    final applied = await _bridge.applyXml(
      xml,
      applyMode: LpBlocklyAiApplyMode.append,
      userPrompt: userPrompt,
    );
    if (!applied) {
      onStep('tool:apply_plan 失败：载入画布失败', failed: true);
      return const LpBlocklyAiToolStepResult(
        success: false,
        message: '完整程序载入画布失败',
      );
    }

    onStep('tool:apply_plan 完成', done: true);
    return LpBlocklyAiToolStepResult(
      success: true,
      message: '已载入 ${blocks.length} 个顶层块（保持嵌套结构）',
    );
  }
}
