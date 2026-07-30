import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

import '../core/robot_path_layout.dart';
import '../core/robot_paths.dart';
import '../core/robot_state.dart';
import '../network/http_manager.dart';
import 'lp_blockly_android_file_dialog.dart';
import 'lp_blockly_file_picker.dart';
import 'lp_blockly_webview_visibility.dart';

/// 非 Windows 平台下从目录列表选手 XML；取消时返回 null。
typedef PickXmlFromList = Future<String?> Function(String browseDir);

/// 安卓保存对话框：返回目录 + 文件名；取消为 null。
typedef PromptAndroidSave = Future<LpBlocklyAndroidFileChoice?> Function({
  required String title,
  required String initialDir,
  required String initialName,
});
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
    this.promptAndroidSave,
  });

  final WebViewController controller;
  final void Function(String message, {bool isError}) showMessage;
  final Future<void> Function(BlocklyExitResult result) onExit;
  final VoidCallback? onExitStarted;
  final VoidCallback? onTaskStarted;
  final BlocklyTaskProgressCallback? onTaskProgress;
  final VoidCallback? onJsLoadComplete;
  final PickXmlFromList? pickXmlFromList;
  final PromptAndroidSave? promptAndroidSave;

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
      case 'promptSaveProgram':
        await _promptAndSaveProgram(
          xml: (data['xml'] ?? '') as String,
          gcode: (data['gcode'] ?? '') as String,
          initialName:
              (data['fileName'] ?? data['filename'] ?? 'main') as String,
        );
        break;
      case 'promptSaveFunXml':
        await _promptAndSaveFunXml(
          xml: (data['xml'] ?? '') as String,
          initialName:
              (data['fileName'] ?? data['filename'] ?? 'main') as String,
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
        await _pickAndLoadXml(
          source: (data['source'] as String?) ?? 'server',
        );
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
        await _androidAwareSavedMessage(
          '${RobotPathLayout.serverDir}/$name.xml 与 $name.rp4',
          absoluteHintFiles: [
            await RobotPaths.serverXmlFile(name),
            await RobotPaths.serverRp4File(name),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Save program failed: $e\n$st');
      _progress(100, '保存失败');
      showMessage('保存失败：$e', isError: true);
    }
  }

  /// 安卓：弹 Flutter 对话框选目录/文件名后再保存工程（xml+rp4）。
  /// Windows 不走此路径（1.8.7：JS prompt → saveProgram）。
  Future<void> _promptAndSaveProgram({
    required String xml,
    required String gcode,
    required String initialName,
  }) async {
    if (!Platform.isAndroid || promptAndroidSave == null) {
      await _handleSaveProgram(
        filename: initialName,
        xml: xml,
        gcode: gcode,
      );
      return;
    }

    final choice = await promptAndroidSave!(
      title: '保存工程',
      initialDir: await RobotPaths.serverDir(),
      initialName: initialName,
    );
    if (choice == null) return;

    if (!await _confirmOverwriteIfNeeded(choice.absolutePath)) return;

    switch (choice.targetKey) {
      case 'funlib':
        await _saveFunXml(filename: choice.fileName, xml: xml);
        return;
      case 'xml':
        await _saveXmlToDirectory(
          directory: choice.directory,
          filename: choice.fileName,
          xml: xml,
          gcode: gcode,
        );
        return;
      case 'server':
        await _handleSaveProgram(
          filename: choice.fileName,
          xml: xml,
          gcode: gcode,
        );
        return;
      default:
        await _saveXmlToDirectory(
          directory: choice.directory,
          filename: choice.fileName,
          xml: xml,
          gcode: gcode,
        );
    }
  }

  /// 安卓：弹对话框保存到函数库（也可改目录）。
  Future<void> _promptAndSaveFunXml({
    required String xml,
    required String initialName,
  }) async {
    if (!Platform.isAndroid || promptAndroidSave == null) {
      await _saveFunXml(filename: initialName, xml: xml);
      return;
    }

    final choice = await promptAndroidSave!(
      title: '保存到函数库',
      initialDir: await RobotPaths.funLibDir(),
      initialName: initialName,
    );
    if (choice == null) return;
    if (!await _confirmOverwriteIfNeeded(choice.absolutePath)) return;

    if (choice.targetKey == 'funlib') {
      await _saveFunXml(filename: choice.fileName, xml: xml);
      return;
    }
    await _saveXmlToDirectory(
      directory: choice.directory,
      filename: choice.fileName,
      xml: xml,
    );
  }

  Future<bool> _confirmOverwriteIfNeeded(String absolutePath) async {
    final file = File(absolutePath);
    if (!await file.exists()) return true;
    // 无 UI 上下文时直接覆盖；页面侧对话框已让用户明确点「确定保存」。
    showMessage('将覆盖已有文件：${p.basename(absolutePath)}');
    return true;
  }

  Future<void> _saveXmlToDirectory({
    required String directory,
    required String filename,
    required String xml,
    String gcode = '',
  }) async {
    final name = RobotPaths.sanitizeBaseName(filename);
    if (name.isEmpty) {
      showMessage('文件名无效', isError: true);
      return;
    }
    try {
      final dir = Directory(directory);
      await dir.create(recursive: true);
      final xmlFile = File(p.join(directory, '$name.xml'));
      await xmlFile.writeAsString(xml);
      File? rp4File;
      if (gcode.isNotEmpty) {
        rp4File = File(p.join(directory, '$name.rp4'));
        await rp4File.writeAsString(gcode);
      }
      showMessage(
        await _androidAwareSavedMessage(
          '$directory/$name.xml',
          absoluteHintFiles: [
            xmlFile,
            if (rp4File != null) rp4File,
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Save xml to dir failed: $e\n$st');
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
      showMessage(
        await _androidAwareSavedMessage(
          '${RobotPathLayout.funLibDir}/${p.basename(file.path)}',
          absoluteHintFiles: [file],
        ),
      );
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

  Future<void> _pickAndLoadXml({String source = 'server'}) async {
    try {
      // Windows 1.8.7：始终 OpenFileDialog，默认 config/server。
      // Android：按 source 切函数库 / 控制器程序 / 工程库。
      final String initialDir;
      if (Platform.isWindows) {
        initialDir = await RobotPaths.serverDir();
      } else if (Platform.isAndroid && source == 'funlib') {
        initialDir = await RobotPaths.funLibDir();
      } else if (Platform.isAndroid && source == 'xml') {
        initialDir = await RobotPaths.xmlLibraryDir();
      } else {
        initialDir = await RobotPaths.serverDir();
      }

      final String? pickedPath;
      if (Platform.isWindows) {
        // 原生对话框会被 WebView2 挡住，先隐藏再弹出（不影响选文件逻辑）。
        await setBlocklyWebViewVisible(controller, false);
        try {
          pickedPath = await LpBlocklyFilePicker.pickXmlFile(initialDir);
        } finally {
          await setBlocklyWebViewVisible(controller, true);
        }
      } else if (pickXmlFromList != null) {
        pickedPath = await pickXmlFromList!(initialDir);
      } else {
        pickedPath = await LpBlocklyFilePicker.pickXmlFile(initialDir);
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
      'if(window.Code&&Code.appendBlocksfromXml){Code.appendBlocksfromXml($encoded);}',
    );
    final message = Platform.isAndroid
        ? '已追加导入：${p.basename(pickedPath)}\n$pickedPath'
        : '已追加导入：$pickedPath';
    showMessage(message);
  }

  /// Android 提示绝对路径（旧 APP 习惯）；其它平台保持相对目录文案。
  Future<String> _androidAwareSavedMessage(
    String relativeLabel, {
    List<File> absoluteHintFiles = const [],
  }) async {
    if (!Platform.isAndroid || absoluteHintFiles.isEmpty) {
      return '已保存到 $relativeLabel';
    }
    final abs = absoluteHintFiles.map((f) => f.path).join('\n');
    return '已保存到：\n$abs';
  }
}
