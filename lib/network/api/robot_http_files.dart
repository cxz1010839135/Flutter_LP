import 'dart:async';
import 'dart:io';

import '../../core/robot_api_constants.dart';
import '../../core/robot_path_layout.dart';
import '../../core/robot_paths.dart';
import '../robot_api_response.dart';
import 'robot_http_api_mixin.dart';

/// `config/server` 程序同步结果。
class ServerProgramSyncResult {
  const ServerProgramSyncResult({
    required this.xmlPath,
    required this.rp4Path,
    required this.xmlBytes,
    required this.rp4Bytes,
    this.robotXmlSynced = true,
    this.robotRp4Synced = true,
  });

  final String xmlPath;
  final String rp4Path;
  final int xmlBytes;
  final int rp4Bytes;

  /// 本次是否从控制器写入了 XML（`false` 表示控制器无程序，已落盘空白工程）。
  final bool robotXmlSynced;

  /// 本次是否从控制器写入了 RP4（`false` 表示控制器无程序，已落盘空白工程）。
  final bool robotRp4Synced;

  bool get isFullySyncedFromRobot => robotXmlSynced && robotRp4Synced;
}

/// 控制器无程序时写入的空白 Blockly 工程（在线编辑从空画布开始）。
const String kEmptyBlocklyServerXml =
    '<xml xmlns="http://www.w3.org/1999/xhtml"></xml>';

/// 程序文件 / 控制器文件系统（ConnectActivity、ProgramActivity、FilesActivity）。
mixin RobotHttpFilesMixin on RobotHttpApiMixin {
  /// 下载 G 代码；响应体为原始文本（非 JSON）。
  Future<String> robotGetGCodeFile({String? filename}) {
    return robotCmdRaw(
      RobotCommands.robotGetGCodeFile,
      data: filename == null ? null : {RobotApiConstants.filename: filename},
    );
  }

  /// 下载 Blockly XML；响应体为原始文本。
  Future<String> robotGetXmlFile({String? filename}) {
    return robotCmdRaw(
      RobotCommands.robotGetXmlFile,
      data: filename == null ? null : {RobotApiConstants.filename: filename},
    );
  }

  Future<String> downloadProgramFile(String filename) async {
    final res = await robotCmdRaw(
      RobotCommands.downloadProgramFile,
      data: {RobotApiConstants.filename: filename},
    );
    return res == 'error' ? '' : res;
  }

  Future<String> getProgramListFile() =>
      robotCmdRaw(RobotCommands.robotGetProgramFileList);

  Future<RobotApiResponse> robotEditCodeOnline() =>
      robotCmd(RobotCommands.robotEditOnline);

  Future<RobotApiResponse> getFileList(String dir) {
    return robotCmd(
      RobotCommands.robotGetFileList,
      data: {RobotApiConstants.dir: dir},
    );
  }

  /// 读取控制器上的文件；响应体为原始文本。
  Future<String> getFile(String fileName) {
    return robotCmdRaw(
      RobotCommands.robotGetFile,
      data: {RobotApiConstants.filename: fileName},
    );
  }

  /// 下载控制器文件（二进制，对齐 Android [HttpManager.getFile]）。
  Future<List<int>> downloadRobotFileBytes(String remotePath) {
    return apiClient.postCommandBytes(
      apiBaseUrl,
      RobotCommands.robotGetFile,
      data: {RobotApiConstants.filename: remotePath},
    );
  }

  Future<RobotApiResponse> robotDeleteFileDir(String dir) {
    return robotCmd(
      RobotCommands.robotDeleteFileDir,
      data: {RobotApiConstants.dir: dir},
    );
  }

  /// 八进制 0777 的十进制表示（固件 [robotChmod] 使用此值）。
  static const chmodMode777 = 511;

  static const _chmodIoTimeout = Duration(seconds: 90);

  /// 单文件 chmod（对齐手动 `chmod 777 <file>`）。
  Future<void> robotChmodFile(
    String filename, {
    int mode = chmodMode777,
  }) async {
    await _robotChmod(data: {RobotApiConstants.filename: filename, 'mode': mode});
  }

  /// 目录 chmod；[recursive] 为 true 时递归子项（对齐 `chmod -R 777 <dir>`）。
  Future<void> robotChmodDir(
    String dir, {
    int mode = chmodMode777,
    bool recursive = false,
  }) async {
    final data = <String, dynamic>{'dir': dir, 'mode': mode};
    if (recursive) {
      data['recursive'] = 1;
    }
    await _robotChmod(data: data);
  }

  Future<void> _robotChmod({required Map<String, dynamic> data}) async {
    final body = await apiClient.postCommand(
      apiBaseUrl,
      RobotCommands.robotChmod,
      data: data,
      ioTimeoutOverride: _chmodIoTimeout,
    );
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    RobotApiResponse.tryParse(trimmed)?.ensureOk();
  }

  /// POST octet-stream 上传单个程序文件（Android [postProgramFile]）。
  Future<String> postProgramFile(File file) async {
    if (!await file.exists()) {
      throw Exception('文件不存在：${file.path}');
    }
    final length = await file.length();
    if (length == 0) {
      throw Exception('文件为空：${file.path}');
    }
    return apiClient.postProgramFile(apiBaseUrl, file);
  }

  /// multipart 上传。
  Future<String> postFile(File file) {
    return apiClient.postMultipartFile(apiBaseUrl, file);
  }

  Future<String> postFileWithTag(
    File file,
    String tagPath, {
    required Future<bool> Function() verifyOnDevice,
    void Function(String message)? onAttempt,
  }) {
    return apiClient.postMultipartFileWithTag(
      apiBaseUrl,
      file,
      tagPath,
      verifyOnDevice: verifyOnDevice,
      onAttempt: onAttempt,
    );
  }

  /// 一键恢复上传（无列表校验，允许 Grobot 等备份文件）。
  Future<String> postFileWithTagForRestore(
    File file,
    String tagPath, {
    void Function(String message)? onAttempt,
  }) {
    return apiClient.postMultipartFileWithTagForRestore(
      apiBaseUrl,
      file,
      tagPath,
      onAttempt: onAttempt,
    );
  }

  /// 从控制器拉取 main 程序并写入 `config/server/{name}.xml`、`.rp4`。
  ///
  /// 对齐 Android ConnectActivity：连接成功后并行下载 Blockly XML 与 RP4。
  ///
  /// [allowEmptyControllerResponse] 为 `true` 时，控制器返回空内容不会抛错，
  /// 并将 `config/server/main.*` 覆写为空白工程（在线以控制器为准，不用本地缓存）。
  ///
  /// [fallbackToEmptyOnFailure] 为 `true` 时，拉取失败（如无效 HTTP 响应）同样
  /// 覆写空白工程并返回，不阻断 Blockly 进入。
  Future<ServerProgramSyncResult> syncServerProgramFromRobot({
    String name = RobotPathLayout.defaultProjectName,
    bool allowEmptyControllerResponse = false,
    bool fallbackToEmptyOnFailure = false,
  }) async {
    await RobotPaths.ensureLayout();
    final xmlFile = await RobotPaths.serverXmlFile(name);
    final rp4File = await RobotPaths.serverRp4File(name);

    try {
      final results = await Future.wait([
        robotGetXmlFile(),
        robotGetGCodeFile(),
      ]);
      final xml = _tryNormalizeProgramPayload(results[0], 'main.xml');
      final gcode = _tryNormalizeProgramPayload(results[1], 'main.rp4');

      if (!allowEmptyControllerResponse) {
        if (xml == null) {
          throw Exception('下载 main.xml 失败：控制器返回空内容');
        }
        if (gcode == null) {
          throw Exception('下载 main.rp4 失败：控制器返回空内容');
        }
      }

      await xmlFile.parent.create(recursive: true);

      var xmlBytes = 0;
      var rp4Bytes = 0;
      if (xml != null) {
        await xmlFile.writeAsString(xml);
        xmlBytes = xml.length;
      } else if (allowEmptyControllerResponse) {
        await _writeEmptyServerProgramFiles(name);
        xmlBytes = kEmptyBlocklyServerXml.length;
        rp4Bytes = 0;
      }

      if (gcode != null) {
        await rp4File.writeAsString(gcode);
        rp4Bytes = gcode.length;
      } else if (allowEmptyControllerResponse && xml != null) {
        await rp4File.writeAsString('');
      }

      return ServerProgramSyncResult(
        xmlPath: xmlFile.path,
        rp4Path: rp4File.path,
        xmlBytes: xmlBytes,
        rp4Bytes: rp4Bytes,
        robotXmlSynced: xml != null,
        robotRp4Synced: gcode != null,
      );
    } catch (e) {
      if (!fallbackToEmptyOnFailure) rethrow;
      await _writeEmptyServerProgramFiles(name);
      return ServerProgramSyncResult(
        xmlPath: xmlFile.path,
        rp4Path: rp4File.path,
        xmlBytes: kEmptyBlocklyServerXml.length,
        rp4Bytes: 0,
        robotXmlSynced: false,
        robotRp4Synced: false,
      );
    }
  }

  Future<void> _writeEmptyServerProgramFiles(String name) async {
    final xmlFile = await RobotPaths.serverXmlFile(name);
    final rp4File = await RobotPaths.serverRp4File(name);
    await xmlFile.parent.create(recursive: true);
    await xmlFile.writeAsString(kEmptyBlocklyServerXml);
    await rp4File.writeAsString('');
  }

  /// 解析控制器程序响应；空内容或 `error` 时返回 `null`。
  String? _tryNormalizeProgramPayload(String raw, String label) {
    var text = raw;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == 'error') {
      return null;
    }

    final json = RobotApiResponse.tryParse(trimmed);
    if (json != null) {
      if (!json.isOk) {
        throw Exception(
          '下载 $label 失败：${json.msg.isNotEmpty ? json.msg : 'result=${json.result}'}',
        );
      }
      final data = json.data;
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      throw Exception('下载 $label 失败：响应格式异常');
    }

    return text;
  }

  /// 上传 [config/server] 程序并通知在线编辑（ProgramActivity 逻辑）。
  Future<void> uploadServerProgram({
    String name = RobotPathLayout.defaultProjectName,
    void Function(int percent, String message)? onProgress,
  }) async {
    final xmlFile = await RobotPaths.serverXmlFile(name);
    final rp4File = await RobotPaths.serverRp4File(name);

    if (!await xmlFile.exists()) {
      throw Exception('缺少 ${xmlFile.path}');
    }
    if (!await rp4File.exists()) {
      throw Exception('缺少 ${rp4File.path}');
    }

    onProgress?.call(50, '正在上传 XML…');
    await postProgramFile(xmlFile);
    onProgress?.call(72, '正在上传 G 代码…');
    await postProgramFile(rp4File);
    // 对齐 Android ProgramActivity：rp4 上传成功即完成，robotEditOnline 后台通知不阻塞退出。
    onProgress?.call(100, '上传完成');
    unawaited(_notifyRobotEditOnlineInBackground());
  }

  /// 通知控制器进入在线编辑（失败/超时不影响退出）。
  Future<void> _notifyRobotEditOnlineInBackground() async {
    try {
      await robotEditCodeOnline().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// 兼容 Android [uploadProgramFiles] 命名。
  Future<void> uploadProgramFiles({
    String name = RobotPathLayout.defaultProjectName,
  }) =>
      uploadServerProgram(name: name);
}
