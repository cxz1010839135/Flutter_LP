import 'dart:io';

import 'package:path/path.dart' as p;

import '../../network/http_manager.dart';
import '../files/robot_file_transfer.dart';
import 'config_file_codec.dart';
import 'config_file_defs.dart';
import 'driver_params_dps_codec.dart';

enum ConfigFileUploadMode {
  /// 单文件配置保存：对齐 Android，直接 multipart 覆盖，不先删目录。
  singleFile,
  /// 一键恢复等场景：先删再传，避免固件追加副本。
  replaceBeforeUpload,
}

class ConfigFileLoadResult {
  const ConfigFileLoadResult({
    required this.exists,
    this.rows = const [],
    this.raw = '',
  });

  final bool exists;
  final List<ConfigFileRow> rows;
  final String raw;
}

/// 驱控配置文件读写（对齐 Android [ConfigFileActivity] 网络 + 本地上传）。
class ConfigFileService {
  ConfigFileService._();

  static final ConfigFileService instance = ConfigFileService._();

  Future<ConfigFileLoadResult> load(ConfigFileStepDef step) async {
    final raw = await HttpManager.instance.getFile(step.remotePath);
    if (ConfigFileCodec.isFileNotExists(raw)) {
      return const ConfigFileLoadResult(exists: false);
    }
    final rows = ConfigFileCodec.parse(step, raw);
    return ConfigFileLoadResult(exists: true, rows: rows, raw: raw);
  }

  Future<void> save(ConfigFileStepDef step, List<ConfigFileRow> rows) async {
    final content = ConfigFileCodec.serialize(step, rows);
    await _uploadContent(
      step.remotePath,
      content,
      mode: ConfigFileUploadMode.singleFile,
    );
  }

  Future<void> createDefault(ConfigFileStepDef step) async {
    final rows = ConfigFileCodec.createDefaultRows(step);
    final content = ConfigFileCodec.serialize(step, rows);
    await _uploadContent(
      step.remotePath,
      content,
      mode: ConfigFileUploadMode.singleFile,
    );
  }

  Future<void> applyEtherCat(List<ConfigFileRow> rows) async {
    final buf = StringBuffer();
    for (final row in rows) {
      if (row.values.isEmpty || row.values.first.trim().isEmpty) continue;
      buf.writeln(row.values.first.trim());
    }
    final res = await HttpManager.instance.createEtherCAT(
      configType: buf.toString().isEmpty ? ' ' : buf.toString(),
    );
    res.ensureOk();
  }

  Future<String> loadDriverParamsRaw(String robotModel) async {
    final path = configRobotTypePath(robotModel, 'driverparams.dps');
    return HttpManager.instance.getFile(path);
  }

  Future<DriverParamsParseResult> loadDriverParams(String robotModel) async {
    final raw = await loadDriverParamsRaw(robotModel);
    return DriverParamsDpsCodec.parse(raw);
  }

  Future<void> saveDriverParams(
    String robotModel,
    List<DriverParamsRow> rows,
    DriverParamsFileLayout layout,
  ) async {
    final content = DriverParamsDpsCodec.serialize(rows, layout);
    final path = configRobotTypePath(robotModel, 'driverparams.dps');
    await _uploadContent(
      path,
      content,
      mode: ConfigFileUploadMode.singleFile,
      chmodAfterUpload: false,
    );
  }

  Future<void> saveDriverParamsRaw(String robotModel, String content) async {
    final path = configRobotTypePath(robotModel, 'driverparams.dps');
    await _uploadContent(
      path,
      content,
      mode: ConfigFileUploadMode.singleFile,
    );
  }

  Future<void> _uploadContent(
    String remotePath,
    String content, {
    ConfigFileUploadMode mode = ConfigFileUploadMode.replaceBeforeUpload,
    bool chmodAfterUpload = true,
  }) async {
    final slash = remotePath.lastIndexOf('/');
    if (slash < 0) {
      throw Exception('无效路径：$remotePath');
    }
    final tagPath = remotePath.substring(0, slash + 1);
    final fileName = remotePath.substring(slash + 1);

    final File localFile;
    if (mode == ConfigFileUploadMode.singleFile) {
      final tempDir = Directory.systemTemp.createTempSync('lp_config_upload_');
      localFile = File(p.join(tempDir.path, fileName));
      await localFile.writeAsString(content, flush: true);
    } else {
      final session = await RobotFileTransfer.downloadSessionRoot();
      var relative =
          remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      localFile = File(
        p.join(session.path, relative.replaceAll('/', p.separator)),
      );
      await localFile.parent.create(recursive: true);
      await localFile.writeAsString(content, flush: true);
    }

    if (mode == ConfigFileUploadMode.replaceBeforeUpload) {
      try {
        await HttpManager.instance.robotDeleteFileDir(remotePath);
      } catch (_) {}
    }

    await HttpManager.instance.postFileWithTagForRestore(localFile, tagPath);

    if (chmodAfterUpload) {
      try {
        await HttpManager.instance.robotChmodFile(remotePath);
      } catch (_) {}
    }
  }
}
