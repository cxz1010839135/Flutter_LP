/// Blockly AI 推理模式。
enum LpBlocklyAiMode {
  /// 联网：OpenAI 兼容 API（DeepSeek / OpenAI 等）。
  online,

  /// 本地：Ollama 等本地服务。
  local,
}

/// 生成结果写入画布的方式。
enum LpBlocklyAiApplyMode {
  /// 清空后载入 AI XML。
  replace,

  /// 保留现有块，追加 AI XML。
  append,
}

/// AI 生成输出格式。
enum LpBlocklyAiGenerationMode {
  /// 结构化 JSON 计划（推荐，参考 aily-blockly Tool 输出）。
  structured,

  /// 直接生成 Blockly XML。
  xml,
}
