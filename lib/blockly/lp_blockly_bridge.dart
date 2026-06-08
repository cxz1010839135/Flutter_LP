import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../core/robot_path_layout.dart';
import '../core/robot_paths.dart';
import '../core/robot_state.dart';
import '../network/http_manager.dart';
import 'lp_blockly_file_picker.dart';

typedef PickXmlFromList = Future<String?> Function(String browseDir);
typedef BlocklyTaskProgressCallback = void Function(int percent, String message);

/// Blockly 退出请求（来自 `bound.exit()`）。
class BlocklyExitRequest {
  const BlocklyExitRequest({
    required this.filename,
    required this.xml,
    required this.gcode,
    required this.updateProgram,
    required this.compileOk,
  });

  final String filename;
  final String xml;
  final String gcode;

  /// 对齐 Android `RobotCommand.bUpdateProgram`：语法正确且用户确认保存。
  final bool updateProgram;
  final bool compileOk;
}

/// 退出流程结果。
class BlocklyExitResult {
  const BlocklyExitResult({
    required this.shouldPop,
    this.message,
    this.isError = false,
    this.uploadFailed = false,
    this.request,
  });

  final bool shouldPop;
  final String? message;
  final bool isError;
  final bool uploadFailed;
  final BlocklyExitRequest? request;
}

/// 处理 Blockly 页面 `FlutterBlockly` 与本地文件系统的交互
class LpBlocklyBridge {
  LpBlocklyBridge({
    required this.controller,
    required this.showMessage,
    required this.onExit,
    this.onExitStarted,
    this.onTaskStarted,
    this.onTaskProgress,
    this.onJsLoadComplete,
    this.pickXmlFromList,
  });

  final WebViewController controller;
  final void Function(String message, {bool isError}) showMessage;
  final Future<void> Function(BlocklyExitResult result) onExit;
  final VoidCallback? onExitStarted;
  final VoidCallback? onTaskStarted;
  final BlocklyTaskProgressCallback? onTaskProgress;
  final VoidCallback? onJsLoadComplete;
  final PickXmlFromList? pickXmlFromList;

  bool _updateProgram = false;
  bool _compileOk = false;
  bool _exitInProgress = false;
  Future<void> _messageChain = Future<void>.value();

  void _progress(int percent, String message) {
    onTaskProgress?.call(percent.clamp(0, 100), message);
  }

  /// JS 通道并发投递时串行处理，避免 exit 与 save 竞态。
  Future<void> handleMessage(String raw) {
    _messageChain = _messageChain
        .then((_) => _handleMessageImpl(raw))
        .catchError((Object e, StackTrace st) {
      debugPrint('Blockly bridge error: $e\n$st');
    });
    return _messageChain;
  }

  Future<void> _handleMessageImpl(String raw) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      debugPrint('Blockly bridge (raw): $raw');
      return;
    }

    final type = data['type'] as String? ?? '';
    debugPrint('Blockly bridge: $data');

    switch (type) {
      case 'loadComplete':
        onJsLoadComplete?.call();
        break;
      case 'saveServerProject':
        await _saveServerProject(
          filename: (data['fileName'] ?? data['filename'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? '') as String,
          silent: true,
          skipProgress: true,
        );
        break;
      case 'saveProgram':
        await _handleSaveProgram(
          filename: (data['fileName'] ?? data['filename'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? '') as String,
        );
        break;
      case 'saveServerRp4':
        await _saveServerRp4(
          filename: (data['fileName'] ?? data['filename'] ?? 'main') as String,
          gcode: (data['gcode'] ?? data['code'] ?? '') as String,
          silent: true,
        );
        break;
      case 'saveCSharp':
        await _saveUserProject(
          filename: (data['fileName'] ?? data['filename'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? data['code'] ?? '') as String,
        );
        break;
      case 'saveFunXML':
        await _saveFunXml(
          filename: (data['filename'] ?? data['fileName'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
        );
        break;
      case 'saveXML':
        await _saveUserProject(
          filename: (data['filename'] ?? data['fileName'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? '') as String,
        );
        break;
      case 'pickAndLoadXml':
        await _pickAndLoadXml();
        break;
      case 'saveCompileResult':
        _compileOk = data['result'] == true;
        break;
      case 'updateCompileResult':
        _updateProgram = true;
        _compileOk = true;
        break;
      case 'exit':
        await _handleExit(
          filename: (data['fileName'] ?? data['filename'] ?? 'main') as String,
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? '') as String,
          updateProgram: (data['updateProgram'] as bool?) ?? _updateProgram,
          compileOk: (data['compileOk'] as bool?) ?? _compileOk,
        );
        break;
      default:
        debugPrint('Blockly bridge: unhandled type=$type');
    }
  }

  /// 工具栏保存：仅写本地 config/server/{name}.xml + .rp4，不上传控制器。
  Future<void> _handleSaveProgram({
    required String filename,
    required String xml,
    required String gcode,
  }) async {
    final name = RobotPaths.sanitizeBaseName(filename);
    if (name.isEmpty) {
      showMessage('文件名无效', isError: true);
      return;
    }

    _progress(0, '正在保存…');

    try {
      await _saveServerProject(
        filename: name,
        xml: xml,
        gcode: gcode,
        silent: true,
        progressBase: 0,
        progressSpan: 100,
      );
      _progress(100, '保存完成');
      showMessage(
        '已保存到 ${RobotPathLayout.serverDir}/$name.xml 与 $name.rp4',
      );
    } catch (e, st) {
      debugPrint('Save program failed: $e\n$st');
      _progress(100, '保存失败');
      showMessage('保存失败：$e', isError: true);
    }
  }

  /// 执行退出：写入 [RobotPathLayout.serverDir] 后返回；在线且编译通过时上传控制器。
  Future<BlocklyExitResult> performExit(BlocklyExitRequest request) async {
    final name = RobotPaths.sanitizeBaseName(
      request.filename.isEmpty ? RobotPathLayout.defaultProjectName : request.filename,
    );
    final isOnline = RobotState.instance.isConnected;
    final needUpload = isOnline && request.updateProgram && request.compileOk;

    try {
      if (request.xml.isNotEmpty || request.gcode.isNotEmpty) {
        await _saveServerProject(
          filename: name,
          xml: request.xml,
          gcode: request.gcode,
          silent: true,
          propagateError: true,
          progressBase: 0,
          progressSpan: needUpload ? 40 : 90,
        );
      }
    } catch (e, st) {
      debugPrint('Exit save failed: $e\n$st');
      _progress(100, '保存失败');
      return BlocklyExitResult(
        shouldPop: false,
        message: '保存到 ${RobotPathLayout.serverDir}/ 失败：$e',
        isError: true,
      );
    }

    if (!isOnline) {
      _progress(100, '保存完成');
      final msg = request.compileOk
          ? '已保存到 ${RobotPathLayout.serverDir}/'
          : '已退出编程';
      return BlocklyExitResult(shouldPop: true, message: msg);
    }

    if (needUpload) {
      try {
        await HttpManager.instance.uploadServerProgram(
          name: name,
          onProgress: (percent, message) {
            // 本地保存占 0–40%，上传占 40–100%。
            _progress(40 + (percent * 60 ~/ 100), message);
          },
        );
        debugPrint('Blockly exit: upload ok, should return to home');
        return BlocklyExitResult(
          shouldPop: true,
          message: '程序已上传并保存到 ${RobotPathLayout.serverDir}/',
        );
      } catch (e, st) {
        debugPrint('Upload program failed: $e\n$st');
        _progress(100, '上传失败');
        return BlocklyExitResult(
          shouldPop: false,
          message: '程序上传失败：$e',
          isError: true,
        );
      }
    }

    _progress(100, '保存完成');
    return BlocklyExitResult(
      shouldPop: true,
      message: '已保存到 ${RobotPathLayout.serverDir}/',
    );
  }

  Future<void> _handleExit({
    required String filename,
    required String xml,
    required String gcode,
    required bool updateProgram,
    required bool compileOk,
  }) async {
    if (_exitInProgress) return;
    _exitInProgress = true;

    final request = BlocklyExitRequest(
      filename: filename,
      xml: xml,
      gcode: gcode,
      updateProgram: updateProgram,
      compileOk: compileOk,
    );

    try {
      onExitStarted?.call();
      final result = await performExit(request);
      await onExit(result);
    } catch (e, st) {
      debugPrint('_handleExit failed: $e\n$st');
      await onExit(
        BlocklyExitResult(
          shouldPop: false,
          message: '退出失败：$e',
          isError: true,
        ),
      );
    } finally {
      _updateProgram = false;
      _compileOk = false;
      _exitInProgress = false;
    }
  }

  /// 控制器同步配置 → config/server
  Future<void> _saveServerProject({
    required String filename,
    required String xml,
    required String gcode,
    bool silent = false,
    bool propagateError = false,
    bool skipProgress = false,
    int progressBase = 0,
    int progressSpan = 100,
  }) async {
    try {
      final xmlFile = await RobotPaths.serverXmlFile(filename);
      final rp4File = await RobotPaths.serverRp4File(filename);

      if (!skipProgress) {
        _progress(
          progressBase + (progressSpan * 0.15).round(),
          silent ? '正在保存 XML…' : '正在写入 XML…',
        );
      }
      await xmlFile.parent.create(recursive: true);
      await xmlFile.writeAsString(xml);

      if (!skipProgress) {
        _progress(
          progressBase + (progressSpan * 0.55).round(),
          silent ? '正在保存 G 代码…' : '正在写入 G 代码…',
        );
      }
      await rp4File.writeAsString(gcode);

      if (silent) {
        if (!skipProgress) {
          _progress(
            progressBase + progressSpan,
            '本地保存完成',
          );
        }
        return;
      }

      final message =
          '已保存到 ${RobotPathLayout.serverDir}/${p.basename(xmlFile.path)} '
          '和 ${RobotPathLayout.serverDir}/${p.basename(rp4File.path)}';
      showMessage(message);
    } catch (e, st) {
      debugPrint('Save server project failed: $e\n$st');
      if (!silent) {
        showMessage('保存失败：$e', isError: true);
      }
      if (!silent || propagateError) {
        rethrow;
      }
    }
  }

  /// 用户工程 → files/projects/{name}/
  Future<void> _saveUserProject({
    required String filename,
    required String xml,
    required String gcode,
  }) async {
    try {
      final xmlFile = await RobotPaths.projectXmlFile(filename);
      await xmlFile.parent.create(recursive: true);
      await xmlFile.writeAsString(xml);
      if (gcode.isNotEmpty) {
        final rp4File = await RobotPaths.projectRp4File(filename);
        await rp4File.writeAsString(gcode);
      }
      final rel = p.posix.join(
        RobotPathLayout.projectsDir,
        RobotPaths.sanitizeBaseName(filename),
      );
      final message = '已保存到 $rel/';
      showMessage(message);
    } catch (e, st) {
      debugPrint('Save user project failed: $e\n$st');
      showMessage('工程保存失败：$e', isError: true);
    }
  }

  Future<void> _saveFunXml({
    required String filename,
    required String xml,
  }) async {
    try {
      final file = await RobotPaths.funLibXmlFile(filename);
      await file.parent.create(recursive: true);
      await file.writeAsString(xml);
      final message =
          '已保存到 ${RobotPathLayout.funLibDir}/${p.basename(file.path)}';
      showMessage(message);
    } catch (e, st) {
      debugPrint('Save FunLib XML failed: $e\n$st');
      showMessage('函数库保存失败：$e', isError: true);
    }
  }

  Future<void> _saveServerRp4({
    required String filename,
    required String gcode,
    bool silent = false,
  }) async {
    try {
      final rp4File = await RobotPaths.serverRp4File(filename);
      await rp4File.parent.create(recursive: true);
      await rp4File.writeAsString(gcode);
      if (silent) return;
      final message =
          '已保存到 ${RobotPathLayout.serverDir}/${p.basename(rp4File.path)}';
      showMessage(message);
    } catch (e, st) {
      debugPrint('Save rp4 failed: $e\n$st');
      showMessage('GCode 保存失败：$e', isError: true);
    }
  }

  Future<void> _pickAndLoadXml() async {
    try {
      final initialDir = await RobotPaths.serverDir();
      var pickedPath = await LpBlocklyFilePicker.pickXmlFile(initialDir);

      if ((pickedPath == null || pickedPath.isEmpty) &&
          pickXmlFromList != null) {
        pickedPath = await pickXmlFromList!(initialDir);
      }

      if (pickedPath == null || pickedPath.isEmpty) return;

      await _loadXmlFile(pickedPath);
    } catch (e, st) {
      debugPrint('Load XML failed: $e\n$st');
      final message = '加载失败：$e';
      showMessage(message, isError: true);
    }
  }

  Future<void> _loadXmlFile(String pickedPath) async {
    final xml = await File(pickedPath).readAsString();
    final encoded = jsonEncode(xml);
    await controller.runJavaScript(
      'if(window.Code&&Code.replaceBlocksfromXml){Code.replaceBlocksfromXml($encoded);}',
    );
    final message = '已加载：$pickedPath';
    showMessage(message);
  }
}
