import 'package:flutter/material.dart';

/// Cursor Agent 侧栏风格色板与排版。
abstract final class LpBlocklyAiAgentTheme {
  static const double panelWidth = 420;

  static const Color background = Color(0xFFF3F3F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color composerBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderStrong = Color(0xFFD4D4D4);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9B9B9B);
  static const Color userBubble = Color(0xFFE8F0FE);
  static const Color accent = Color(0xFF0969DA);
  static const Color thinkBg = Color(0xFF2B2B2B);
  static const Color success = Color(0xFF1A7F37);
  static const Color error = Color(0xFFCF222E);

  static const TextStyle headerTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle userText = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: textPrimary,
  );

  static const TextStyle assistantText = TextStyle(
    fontSize: 13,
    height: 1.55,
    color: textPrimary,
  );

  static const TextStyle stepText = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: textSecondary,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 11,
    color: textMuted,
  );

  static const TextStyle chipText = TextStyle(
    fontSize: 11,
    color: textSecondary,
  );
}
