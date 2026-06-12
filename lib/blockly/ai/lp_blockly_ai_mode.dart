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
