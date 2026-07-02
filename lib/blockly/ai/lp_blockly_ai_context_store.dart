import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_paths.dart';
import 'lp_blockly_ai_message.dart';
import 'lp_blockly_ai_session.dart';

/// Blockly AI 本地上下文与会话持久化。
///
/// - [contextTextFile]：用户可编辑的长期上下文（项目约定、寄存器说明等）
/// - [sessionsIndexFile] + [sessionsDirName]：多会话历史（对齐 Cursor 历史列表）
abstract final class LpBlocklyAiContextStore {
  static const contextTextFile = 'blockly_ai_context.txt';
  static const legacySessionFile = 'blockly_ai_session.json';
  static const sessionsIndexFile = 'blockly_ai_sessions_index.json';
  static const sessionsDirName = 'blockly_ai_sessions';
  static const maxSessionMessages = 120;
  static const maxSessions = 50;

  static Future<String> _configDir() async {
    await RobotPaths.ensureLayout();
    return RobotPaths.configRootDir();
  }

  static Future<Directory> _sessionsDir() async {
    final dir = Directory(p.join(await _configDir(), sessionsDirName));
    await dir.create(recursive: true);
    return dir;
  }

  static String newSessionId() =>
      'sess_${DateTime.now().millisecondsSinceEpoch}';

  /// 读取长期上下文文本。
  static Future<String> loadContextText() async {
    try {
      final file = File(p.join(await _configDir(), contextTextFile));
      if (!await file.exists()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  /// 保存长期上下文文本。
  static Future<void> saveContextText(String text) async {
    final file = File(p.join(await _configDir(), contextTextFile));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  // --- 多会话 ---

  static Future<Map<String, dynamic>> _readIndex() async {
    try {
      final file = File(p.join(await _configDir(), sessionsIndexFile));
      if (!await file.exists()) return {};
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeIndex(Map<String, dynamic> index) async {
    final file = File(p.join(await _configDir(), sessionsIndexFile));
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(index));
  }

  static List<LpBlocklyAiSessionMeta> _parseSessionList(dynamic raw) {
    if (raw is! List) return [];
    final list = <LpBlocklyAiSessionMeta>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final meta = LpBlocklyAiSessionMeta.fromJson(
        item.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (meta.id.isNotEmpty) list.add(meta);
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// 列出所有已保存会话（按更新时间倒序）。
  static Future<List<LpBlocklyAiSessionMeta>> listSessions() async {
    final index = await _readIndex();
    return _parseSessionList(index['sessions']);
  }

  /// 当前活跃会话 id。
  static Future<String?> loadActiveSessionId() async {
    final index = await _readIndex();
    final id = index['activeSessionId'] as String?;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static Future<void> setActiveSessionId(String id) async {
    final index = await _readIndex();
    index['activeSessionId'] = id;
    await _writeIndex(index);
  }

  static List<LpBlocklyAiChatMessage> _parseMessages(dynamic raw) {
    if (raw is! List) return [];
    final messages = <LpBlocklyAiChatMessage>[];
    for (final item in raw) {
      if (item is! Map) continue;
      messages.add(
        LpBlocklyAiChatMessage.fromJson(
          item.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    }
    return messages;
  }

  /// 读取指定会话消息。
  static Future<List<LpBlocklyAiChatMessage>> loadSessionMessages(
    String sessionId,
  ) async {
    try {
      final file = File(
        p.join((await _sessionsDir()).path, '$sessionId.json'),
      );
      if (!await file.exists()) return [];
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _parseMessages(map['messages']);
    } catch (_) {
      return [];
    }
  }

  /// 保存会话消息并更新索引。
  static Future<void> saveSessionData({
    required String sessionId,
    required List<LpBlocklyAiChatMessage> messages,
    DateTime? createdAt,
  }) async {
    final toSave = <LpBlocklyAiChatMessage>[];
    for (final msg in messages) {
      if (msg.kind == LpBlocklyAiMessageKind.action &&
          msg.actionStatus == LpBlocklyAiActionStatus.running) {
        continue;
      }
      toSave.add(msg);
    }
    if (toSave.isEmpty) return;

    final trimmed = toSave.length > maxSessionMessages
        ? toSave.sublist(toSave.length - maxSessionMessages)
        : toSave;

    final now = DateTime.now();
    final title = LpBlocklyAiSessionMeta.titleFromMessages(trimmed);
    final sessionFile = File(
      p.join((await _sessionsDir()).path, '$sessionId.json'),
    );

    DateTime effectiveCreated = createdAt ?? now;
    if (await sessionFile.exists()) {
      try {
        final existing =
            jsonDecode(await sessionFile.readAsString()) as Map<String, dynamic>;
        effectiveCreated = DateTime.tryParse(
              existing['createdAt'] as String? ?? '',
            ) ??
            effectiveCreated;
      } catch (_) {}
    }

    await sessionFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'id': sessionId,
        'title': title,
        'createdAt': effectiveCreated.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'messages': trimmed.map((m) => m.toJson()).toList(),
      }),
    );

    final index = await _readIndex();
    var sessions = _parseSessionList(index['sessions']);
    final existingIndex = sessions.indexWhere((s) => s.id == sessionId);
    final meta = LpBlocklyAiSessionMeta(
      id: sessionId,
      title: title,
      createdAt: effectiveCreated,
      updatedAt: now,
      messageCount: trimmed.length,
    );
    if (existingIndex >= 0) {
      sessions[existingIndex] = meta;
    } else {
      sessions.insert(0, meta);
    }
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (sessions.length > maxSessions) {
      final removed = sessions.sublist(maxSessions);
      sessions = sessions.sublist(0, maxSessions);
      for (final old in removed) {
        await deleteSessionFile(old.id);
      }
    }
    index['sessions'] = sessions.map((s) => s.toJson()).toList();
    index['activeSessionId'] = sessionId;
    await _writeIndex(index);
  }

  static Future<void> deleteSessionFile(String sessionId) async {
    try {
      final file = File(
        p.join((await _sessionsDir()).path, '$sessionId.json'),
      );
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 删除会话及其文件。
  static Future<void> deleteSession(String sessionId) async {
    await deleteSessionFile(sessionId);
    final index = await _readIndex();
    var sessions = _parseSessionList(index['sessions']);
    sessions = sessions.where((s) => s.id != sessionId).toList();
    index['sessions'] = sessions.map((s) => s.toJson()).toList();
    if (index['activeSessionId'] == sessionId) {
      index['activeSessionId'] =
          sessions.isNotEmpty ? sessions.first.id : null;
    }
    await _writeIndex(index);
  }

  /// 将旧版单文件会话迁移为多会话格式。
  static Future<void> migrateLegacyIfNeeded() async {
    final legacyFile = File(p.join(await _configDir(), legacySessionFile));
    if (!await legacyFile.exists()) return;

    try {
      final map =
          jsonDecode(await legacyFile.readAsString()) as Map<String, dynamic>;
      final messages = _parseMessages(map['messages']);
      if (messages.isEmpty) {
        await legacyFile.delete();
        return;
      }

      final index = await _readIndex();
      final existing = _parseSessionList(index['sessions']);
      if (existing.isNotEmpty) {
        await legacyFile.delete();
        return;
      }

      final sessionId = newSessionId();
      await saveSessionData(sessionId: sessionId, messages: messages);
      await setActiveSessionId(sessionId);
      await legacyFile.delete();
    } catch (_) {}
  }

  // --- 兼容旧 API（内部转调多会话）---

  static Future<List<LpBlocklyAiChatMessage>> loadSession() async {
    await migrateLegacyIfNeeded();
    final activeId = await loadActiveSessionId();
    if (activeId == null) return [];
    return loadSessionMessages(activeId);
  }

  static Future<void> saveSession(List<LpBlocklyAiChatMessage> messages) async {
    if (messages.isEmpty) return;
    var activeId = await loadActiveSessionId();
    activeId ??= newSessionId();
    await saveSessionData(sessionId: activeId, messages: messages);
  }

  static Future<void> clearSession() async {
    final activeId = await loadActiveSessionId();
    if (activeId != null) {
      await deleteSession(activeId);
    }
  }
}
