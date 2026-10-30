import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_path_layout.dart';
import '../../core/robot_point_library.dart';
import '../../network/http_manager.dart';
import '../files/robot_file_transfer.dart';

/// 点位库文件（`.rpt4`）保存/导入。
///
/// - **保存**：下载驱控当前点位库文件 [RobotPathLayout.robotPointLibFile]，
///   以自定义文件名（默认后缀 `.rpt4`）上传到 `/home/llmachine/`。
/// - **导入**：从内存卡（驱控目录）或本地目录选 `.rpt4`，覆盖驱控当前
///   点位库文件并调 `refreshPointLibrary` 重载，点位表格随之刷新。
///
/// 保存只复制文件不改当前点库；导入会替换当前点库。
/// 说明：原方案曾存 `/home/llmachine/pointHome/` 并"仅存文件不启用"，但
/// 固件不随上传自动建目录（2026-10-26 用户实测），且用户实测后要求
/// 导入即刷新点位（2026-10-26），遂改为上述语义。
class PointLibraryFileIo {
  PointLibraryFileIo._();

  /// 校验并规范自定义文件名：去空白、过滤非法字符、确保 `.rpt4` 后缀。
  /// 校验失败抛 [FormatException]。
  static String normalizeName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const FormatException('名称不能为空');
    }
    const illegal = r'\/:*?"<>|';
    if (name.split('').any(illegal.contains)) {
      throw const FormatException('名称不能包含 \\ / : * ? " < > |');
    }
    if (!name.toLowerCase().endsWith(RobotPathLayout.pointLibExtension)) {
      return '$name${RobotPathLayout.pointLibExtension}';
    }
    return name;
  }

  /// 保存目录内现有 `.rpt4` 文件。
  ///
  /// 目录不可访问等错误向上抛。
  static Future<List<RemoteFileEntry>> listSavedPointFiles() async {
    final entries = await RobotFileTransfer.listRemote(
      RobotPathLayout.robotPointFileDir,
    );
    return entries
        .where((e) => !e.isDir && isPointLibFile(e.name))
        .toList(growable: false);
  }

  /// 保存目录内是否已有同名文件。
  static Future<bool> hasSavedPointFile(String fileName) async {
    final files = await listSavedPointFiles();
    return files.any((e) => e.name == fileName);
  }

  /// 保存当前点位库到 `/home/llmachine/<fileName>`，返回目标完整路径。
  static Future<String> saveCurrentPointLibrary(
    String fileName, {
    void Function(String message)? onStatus,
  }) async {
    onStatus?.call('读取驱控点位库文件 ${RobotPathLayout.robotPointLibFile}');
    final bytes = await HttpManager.instance.downloadRobotFileBytes(
      RobotPathLayout.robotPointLibFile,
    );
    if (bytes.isEmpty) {
      throw Exception(
        '驱控点位库文件为空或不存在：${RobotPathLayout.robotPointLibFile}',
      );
    }
    final temp = await _writeRelayTemp(bytes, fileName);
    try {
      await _uploadToPointStore(temp, onStatus: onStatus);
      return '${RobotPathLayout.robotPointFileTagPath}$fileName';
    } finally {
      await _deleteRelayTemp(temp);
    }
  }

  /// 把所选 `.rpt4` 导入为驱控**当前点位库**：
  ///
  /// 1. 取得文件内容（内存卡来源先下载，本地来源直接读）；
  /// 2. 覆盖驱控 `para/rbt_Point.rpt4`（走恢复通道，不做目录列表校验——
  ///    覆盖已存在文件时列表校验无法区分新旧内容），回读校验确认覆盖；
  /// 3. 调 `refreshPointLibrary`（机会性，带回点库数据才视为生效）；未生效
  ///    时逐点 upsert 驱控内存点库（updatePoint 失败则 addPoint 新建再写入），
  ///    并删除内存中多余点位——updatePoint 非 upsert、refreshPointLibrary
  ///    不重载内存均为 2026-10-26 真机证实；
  /// 4. 刷新 [RobotPointLibrary]：固件响应带点库数据时优先采用，
  ///    否则本地解析刚写入的文件内容（`.rpt4` 为 UTF-8 文本 CSV，
  ///    每行 `P{index},{j1}…{jN},{label}`，2026-10-26 真机样本核实）。
  ///
  /// [remoteEntry] 与 [localFile] 二选一。
  static Future<PointImportResult> importAsCurrentPointLibrary({
    RemoteFileEntry? remoteEntry,
    File? localFile,
    void Function(String message)? onStatus,
  }) async {
    final total = Stopwatch()..start();

    // 1. 取得文件内容（内存卡来源先下载，本地来源直接读）。
    final List<int> bytes;
    if (remoteEntry != null) {
      final size = remoteEntry.size;
      if (size != null && size > RemoteFileEntry.maxDownloadBytes) {
        throw Exception('文件超过 200MB，已跳过');
      }
      final sw = Stopwatch()..start();
      onStatus?.call('读取 ${remoteEntry.fullPath}');
      bytes = await HttpManager.instance.downloadRobotFileBytes(
        remoteEntry.fullPath,
      );
      sw.stop();
      onStatus?.call('读取完成（${_fmt(sw.elapsed)}，${bytes.length} 字节）');
    } else if (localFile != null) {
      if (!await localFile.exists()) {
        throw Exception('文件不存在：${localFile.path}');
      }
      final sw = Stopwatch()..start();
      onStatus?.call('读取 ${localFile.path}');
      bytes = await localFile.readAsBytes();
      sw.stop();
      onStatus?.call('读取完成（${_fmt(sw.elapsed)}，${bytes.length} 字节）');
    } else {
      throw ArgumentError('缺少导入来源');
    }
    if (bytes.isEmpty) {
      throw Exception('文件内容为空');
    }

    // 2. 覆盖驱控 para/rbt_Point.rpt4（走恢复通道，不做目录列表校验——
    //    覆盖已存在文件时列表校验无法区分新旧内容）。
    // 上传 filename 取 basename，中转文件必须命名为 rbt_Point.rpt4。
    final temp = await _writeRelayTemp(bytes, 'rbt_Point.rpt4');
    var uploadVerified = false;
    try {
      final sw = Stopwatch()..start();
      onStatus?.call('写入驱控当前点位库 ${RobotPathLayout.robotPointLibFile}');
      await HttpManager.instance.postFileWithTagForRestore(
        temp,
        RobotPathLayout.robotPointLibTagPath,
        onAttempt: onStatus,
      );
      sw.stop();
      onStatus?.call('写入完成（${_fmt(sw.elapsed)}）');

      // 上传后立即下载回读，确认文件内容真的被覆盖（固件对覆盖上传可能返回空 body，
      // 不能仅凭应答判断成功）。
      onStatus?.call('校验写入内容…');
      final swVerify = Stopwatch()..start();
      try {
        final written = await HttpManager.instance.downloadRobotFileBytes(
          RobotPathLayout.robotPointLibFile,
        );
        uploadVerified = _bytesEqual(written, bytes);
        swVerify.stop();
        onStatus?.call(
          uploadVerified
              ? '校验通过（${_fmt(swVerify.elapsed)}，内容一致）'
              : '校验未通过（${_fmt(swVerify.elapsed)}，驱控文件与导入内容不一致）',
        );
      } catch (e) {
        swVerify.stop();
        onStatus?.call('校验失败（${_fmt(swVerify.elapsed)}）：$e');
      }
    } finally {
      await _deleteRelayTemp(temp);
    }

    if (!uploadVerified) {
      // 文件未被覆盖，中止导入，避免误导用户。
      throw Exception(
        '驱控 ${RobotPathLayout.robotPointLibFile} 未被覆盖（上传后回读内容不一致）。\n'
        '请确认该目录可写，或通过文件管理页手动上传后重启控制器。',
      );
    }

    // 3. 调 refreshPointLibrary 让驱控从已写入的文件重载点库（机会性信号：
    //    部分固件版本支持）。本机实测 8s/20s 超时均等不到应答、45s 内也只回
    //    空 body 且内存点库并未重载（2026-10-26 多轮日志），故用默认 8s 短
    //    超时不卡导入；内存点库真正更新靠下方逐点写入。
    final imported = parsePointLibBytes(bytes);
    if (imported.isEmpty) {
      throw const FormatException('文件中没有可识别的点位（P 开头数据行）');
    }

    // 导入前的内存点库快照（连接时加载），用于识别要删除的多余点位。
    final existingByIndex = <int, RobotPoint>{
      for (final p in RobotPointLibrary.instance.points) p.index: p,
    };

    onStatus?.call('刷新点库…');
    final swRefresh = Stopwatch()..start();
    Map<String, dynamic>? responseRoot;
    Object? refreshError;
    // 固件实测对该命令可能返回空 body（2026-10-26 日志 FormatException），
    // 对齐 robotChmod 的处理：空 body / 非 JSON 视为已应答；JSON 则校验 result。
    // 只有带回点库数据的应答才视为「刷新已生效」（空 body 已证实不重载内存）。
    var refreshAppliedLibrary = false;
    try {
      final body = await HttpManager.instance.refreshPointLibRaw();
      swRefresh.stop();
      onStatus?.call('刷新已应答（${_fmt(swRefresh.elapsed)}）');
      final trimmed = body.trim();
      if (trimmed.isNotEmpty) {
        final json = RobotApiResponse.tryParse(trimmed);
        json?.ensureOk();
        if (json != null) {
          responseRoot = json.root;
          refreshAppliedLibrary = _hasPointData(json.root);
        }
      }
    } catch (e) {
      swRefresh.stop();
      refreshError = e;
      onStatus?.call('刷新未应答（${_fmt(swRefresh.elapsed)}），改为逐点写入');
    }

    // 3b. 逐点 upsert——唯一被证实能更新驱控内存点库的路径（2026-10-26 真机：
    //     updatePoint 仅对内存中已存在的点位生效，3/11 成功、失败全是不存在
    //     的点位，约 30ms 即被拒）。refresh 未带回点库数据时始终执行：
    //     - 已存在：updatePoint(refresh=true) 一步写入；
    //     - 不存在：addPoint 新建（关节值为 0）→ updatePoint 写入关节值；
    //     - 内存中多余点位（不在导入文件内）逐个 deletePoint，对齐「覆盖」语义。
    final upsertFailures = <int>[];
    final deleteFailures = <int>[];
    final errorDetails = <String>{};
    var createdCount = 0;
    if (!refreshAppliedLibrary) {
      onStatus?.call('逐点写入驱控内存点库（${imported.length} 个）…');
      final swFallback = Stopwatch()..start();
      for (final p in imported) {
        final describe = p.label.isEmpty ? 'P${p.index}' : p.label;
        var ok = false;
        try {
          final res = await HttpManager.instance.updatePoint(
            pointIndex: p.index,
            label: p.label,
            describe: describe,
            joints: p.joints,
            refresh: true,
          );
          res.ensureOk();
          responseRoot = _latestLibraryRoot(responseRoot, res.root);
          ok = true;
        } catch (e) {
          // updatePoint 对不存在的点位会被拒（非 upsert，真机证实）：
          // 先 addPoint 新建，再 updatePoint 写入关节值。
          try {
            final add = await HttpManager.instance.addPoint(
              pointIndex: p.index,
              label: p.label,
              describe: describe,
            );
            add.ensureOk();
            final res2 = await HttpManager.instance.updatePoint(
              pointIndex: p.index,
              label: p.label,
              describe: describe,
              joints: p.joints,
              refresh: true,
            );
            res2.ensureOk();
            responseRoot = _latestLibraryRoot(responseRoot, res2.root);
            createdCount++;
            ok = true;
          } catch (e2) {
            errorDetails.add('P${p.index}: $e；$e2');
          }
        }
        if (!ok) upsertFailures.add(p.index);
      }

      // 删除内存中多余点位（不在导入文件内的）。
      final importedIndices = <int>{for (final p in imported) p.index};
      final extras = existingByIndex.values
          .where((p) => !importedIndices.contains(p.index))
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (extras.isNotEmpty) {
        onStatus?.call(
          '删除多余点位（${extras.length} 个：'
          '${extras.map((p) => 'P${p.index}').join(',')}）…',
        );
        for (final p in extras) {
          try {
            final res = await HttpManager.instance.deletePoint(
              pointIndex: p.index,
              label: p.label,
              describe: p.label.isEmpty ? 'P${p.index}' : p.label,
              joints: p.joints,
            );
            res.ensureOk();
            responseRoot = _latestLibraryRoot(responseRoot, res.root);
          } catch (e) {
            deleteFailures.add(p.index);
            errorDetails.add('删除P${p.index}: $e');
          }
        }
      }
      swFallback.stop();
      if (upsertFailures.isEmpty && deleteFailures.isEmpty) {
        refreshError = null;
        onStatus?.call(
          '逐点写入完成（${_fmt(swFallback.elapsed)}，'
          '${imported.length} 个点位，其中新建 $createdCount 个）',
        );
      } else {
        onStatus?.call(
          '逐点写入完成（${_fmt(swFallback.elapsed)}，'
          '${imported.length - upsertFailures.length}/${imported.length} 成功'
          '${upsertFailures.isEmpty ? '' : '，失败：${upsertFailures.join(',')}'}'
          '${deleteFailures.isEmpty ? '' : '；删除失败：${deleteFailures.join(',')}'}）',
        );
      }
    }
    final refreshed =
        refreshAppliedLibrary ||
        (upsertFailures.isEmpty && deleteFailures.isEmpty);

    // 4. 表格刷新：固件返回点库数据时优先采用（驱控真实状态）；否则本地
    //    解析刚写入的文件内容。
    if (responseRoot != null && _hasPointData(responseRoot)) {
      RobotPointLibrary.instance.applyFromResponseRoot(responseRoot);
    } else {
      RobotPointLibrary.instance.applyImported(imported);
    }

    total.stop();
    onStatus?.call('导入总耗时 ${_fmt(total.elapsed)}');

    return PointImportResult(
      target: RobotPathLayout.robotPointLibFile,
      refreshed: refreshed,
      uploadVerified: uploadVerified,
      responseRoot: responseRoot,
      refreshError: refreshError,
      upsertFailures: upsertFailures,
      deleteFailures: deleteFailures,
      errorDetail: errorDetails.isEmpty
          ? null
          : errorDetails.length <= 3
              ? errorDetails.join('；')
              : '${errorDetails.take(3).join('；')} 等 ${errorDetails.length} 种错误',
    );
  }

  /// 响应根中是否带点库数据（data 为 List，或为含 pointlibrary/points 的 Map）。
  static bool _hasPointData(Map<String, dynamic> root) {
    final data = root[RobotApiConstants.data];
    return data is List ||
        (data is Map &&
            (data[RobotApiConstants.pointLibrary] != null ||
                data['points'] != null));
  }

  /// 候选响应带点库数据时替换当前记录（保留最后一次带数据的响应）。
  static Map<String, dynamic>? _latestLibraryRoot(
    Map<String, dynamic>? current,
    Map<String, dynamic> candidate,
  ) => _hasPointData(candidate) ? candidate : current;

  /// 逐字节比较两个字节数组是否相等（用于回读校验）。
  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 把 [Duration] 格式化为人类可读的耗时（如 1.234s、890ms）。
  static String _fmt(Duration d) {
    if (d.inMilliseconds < 1000) {
      return '${d.inMilliseconds}ms';
    }
    final secs = d.inMilliseconds / 1000;
    return '${secs.toStringAsFixed(2)}s';
  }

  /// 解析 `.rpt4` 点库文件内容（UTF-8 文本，CRLF/LF 行）。
  ///
  /// 格式（对齐真机备份样本）：每行 `P{index},{j1},…,{jN},{label}`，
  /// 末字段为名称（可为空），中间全部为关节值；行内至少含 `P{index},`。
  static List<RobotPoint> parsePointLibBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final points = <RobotPoint>[];
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 2) continue;

      final head = parts[0].trim();
      final indexText = (head.startsWith('P') || head.startsWith('p'))
          ? head.substring(1)
          : head;
      final index = int.tryParse(indexText.trim());
      if (index == null) continue;

      // 有名称字段（≥3 段）时末段为名称，其余为关节；仅 2 段视为无名称。
      final label = parts.length >= 3 ? parts.last.trim() : '';
      final jointEnd = parts.length >= 3 ? parts.length - 1 : parts.length;
      final joints = <double>[];
      for (var i = 1; i < jointEnd; i++) {
        joints.add(double.tryParse(parts[i].trim()) ?? 0);
      }
      points.add(RobotPoint(index: index, label: label, joints: joints));
    }
    return points;
  }

  /// 是否 `.rpt4` 点位库文件（不区分大小写）。
  static bool isPointLibFile(String name) => name
      .toLowerCase()
      .endsWith(RobotPathLayout.pointLibExtension);

  /// 远程中转临时文件：放在 `files/downloads/{host}/_point_tmp_<ts>/` 下，
  /// 文件名保持目标名（上传 filename 取 basename），完成后整个临时目录删除。
  static Future<File> _writeRelayTemp(List<int> bytes, String fileName) async {
    final root = await RobotFileTransfer.downloadSessionRoot();
    final dir = Directory(
      p.join(root.path, '_point_tmp_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> _deleteRelayTemp(File file) async {
    try {
      final parent = file.parent;
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> _uploadToPointStore(
    File file, {
    void Function(String message)? onStatus,
  }) async {
    await HttpManager.instance.postFileWithTag(
      file,
      RobotPathLayout.robotPointFileTagPath,
      verifyOnDevice: () => _verifyInStoreDir(p.basename(file.path)),
      onAttempt: onStatus,
    );
  }

  /// 上传后轮询保存目录，确认文件已落盘。
  static Future<bool> _verifyInStoreDir(String fileName) async {
    for (var i = 0; i < 5; i++) {
      if (i > 0) {
        await Future<void>.delayed(Duration(milliseconds: 250 + i * 150));
      }
      try {
        final entries = await RobotFileTransfer.listRemote(
          RobotPathLayout.robotPointFileDir,
        );
        if (entries.any(
          (e) => !e.isDir && e.name == fileName,
        )) {
          return true;
        }
      } catch (_) {
        // 列表偶发失败时继续重试。
      }
    }
    return false;
  }
}

/// 一次「导入为当前点位库」的结果。
class PointImportResult {
  const PointImportResult({
    required this.target,
    required this.refreshed,
    required this.uploadVerified,
    this.responseRoot,
    this.refreshError,
    this.upsertFailures = const [],
    this.deleteFailures = const [],
    this.errorDetail,
  });

  /// 被覆盖的驱控点位库文件路径。
  final String target;

  /// 驱控内存点库是否已确认为导入内容（refresh 生效或逐点写入全部成功）。
  final bool refreshed;

  /// 上传后回读校验是否通过（`para/rbt_Point.rpt4` 内容与导入文件一致）。
  final bool uploadVerified;

  /// 固件返回 JSON 时的响应根（可能不含点库数据；为 null 表示空 body）。
  final Map<String, dynamic>? responseRoot;

  /// 刷新命令未应答的原因（逐点写入全部成功时已无意义，为 null）。
  final Object? refreshError;

  /// 逐点写入仍失败的点位编号（addPoint+updatePoint 两步后仍失败）。
  final List<int> upsertFailures;

  /// 多余点位删除失败的点位编号。
  final List<int> deleteFailures;

  /// 失败原因摘要（去重，最多 3 条，用于日志定位）。
  final String? errorDetail;
}
