import 'config_file_defs.dart';

/// 驱控配置文件解析 / 序列化 / 默认创建（对齐 Android [ConfigFileActivity]）。
class ConfigFileCodec {
  ConfigFileCodec._();

  static const fileNotExistsJson =
      '{"msg":"file is not exists","result":5}';

  static bool isFileNotExists(String body) =>
      body.trim() == fileNotExistsJson;

  /// 驱控端「空文件」：无内容或仅空白（对齐 Android 保存单个空格）。
  static bool isWhitespaceOnlyFile(String body) => body.trim().isEmpty;

  static List<ConfigFileRow> parse(ConfigFileStepDef step, String raw) {
    if (isWhitespaceOnlyFile(raw)) return const [];
    final labels = step.buildRowLabels();
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final out = <ConfigFileRow>[];
    var labelIndex = 0;

    switch (step.format) {
      case ConfigFileFormat.csv3:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length != 3) continue;
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.singleValue:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: [line.trim()],
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.manuVmax:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.isEmpty || parts.first.trim().isEmpty) continue;
          for (final part in parts) {
            if (part.trim().isEmpty || part.trim() == ' ') continue;
            out.add(
              ConfigFileRow(
                name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
                values: [part.trim()],
              ),
            );
            labelIndex++;
          }
        }
        break;
      case ConfigFileFormat.csvPerLine:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.colonPair:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(':');
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.csv7:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length == 7) {
            out.add(
              ConfigFileRow(
                name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
                values: parts.map((e) => e.trim()).toList(),
              ),
            );
          } else if (parts.length == 5) {
            final vals = parts.map((e) => e.trim()).toList();
            while (vals.length < 7) {
              vals.add('0');
            }
            out.add(
              ConfigFileRow(
                name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
                values: vals,
              ),
            );
          }
          labelIndex++;
        }
        break;
      case ConfigFileFormat.csvCommaLine:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          for (final part in parts) {
            if (part.trim().isEmpty) continue;
            out.add(
              ConfigFileRow(
                name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
                values: [part.trim()],
              ),
            );
            labelIndex++;
          }
        }
        break;
      case ConfigFileFormat.csv5:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length != 5) continue;
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.csv2:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length != 2) continue;
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
      case ConfigFileFormat.csv8:
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length != 8) continue;
          out.add(
            ConfigFileRow(
              name: labelIndex < labels.length ? labels[labelIndex] : '条目$labelIndex',
              values: parts.map((e) => e.trim()).toList(),
            ),
          );
          labelIndex++;
        }
        break;
    }
    return out;
  }

  /// 序列化配置内容；无有效数据时返回单个空格（全步骤通用）。
  static String serialize(ConfigFileStepDef step, List<ConfigFileRow> rows) {
    if (rows.isEmpty) return emptyFilePlaceholder;

    final buf = StringBuffer();
    switch (step.format) {
      case ConfigFileFormat.csv3:
        for (final row in rows) {
          final v = _pad(row.values, 3);
          buf.writeln('${v[0]},${v[1]},${v[2]}');
        }
        break;
      case ConfigFileFormat.singleValue:
        return finalizeUploadContent(rows.first.values.first);
      case ConfigFileFormat.manuVmax:
        if (rows.length >= 2) {
          buf.write('${rows[0].values.first},${rows[1].values.first}\n');
        }
        if (rows.length > 2) {
          for (var i = 2; i < rows.length; i++) {
            buf.write(rows[i].values.first);
            if (i < rows.length - 1) buf.write(',');
          }
        }
        break;
      case ConfigFileFormat.csvPerLine:
        for (final row in rows) {
          buf.writeln(row.values.map((e) => e.trim()).join(','));
        }
        break;
      case ConfigFileFormat.colonPair:
        for (final row in rows) {
          final v = _pad(row.values, 2);
          buf.writeln('${v[0]}:${v[1]}');
        }
        break;
      case ConfigFileFormat.csv7:
        for (final row in rows) {
          final v = _pad(row.values, 7);
          buf.writeln(v.join(','));
        }
        break;
      case ConfigFileFormat.csvCommaLine:
        for (var i = 0; i < rows.length; i++) {
          buf.write(rows[i].values.first);
          if (i < rows.length - 1) buf.write(',');
        }
        break;
      case ConfigFileFormat.csv5:
        for (final row in rows) {
          final v = _pad(row.values, 5);
          buf.writeln(v.join(','));
        }
        break;
      case ConfigFileFormat.csv2:
        for (final row in rows) {
          final v = _pad(row.values, 2);
          buf.writeln('${v[0]},${v[1]}');
        }
        break;
      case ConfigFileFormat.csv8:
        for (final row in rows) {
          final v = _pad(row.values, 8);
          buf.writeln(v.join(','));
        }
        break;
    }
    return finalizeUploadContent(buf.toString());
  }

  /// 上传用占位：Android `updateParamFile` 在 length==0 时写入 `' '`。
  static const String emptyFilePlaceholder = ' ';

  /// 保证 multipart 上传非空（空白内容视为空文件）。
  static String finalizeUploadContent(String content) {
    final text = content.replaceAll('\r\n', '\n');
    if (text.trim().isEmpty) return emptyFilePlaceholder;
    return text;
  }

  static List<ConfigFileRow> createDefaultRows(ConfigFileStepDef step) {
    final labels = step.buildRowLabels();
    switch (step.index) {
      case 0:
        return [
          ConfigFileRow(name: labels[0], values: ['ttyPS3', '1', 'panel']),
          ConfigFileRow(name: labels[1], values: ['ttyPS2', '1', 'plc']),
        ];
      case 1:
        return [ConfigFileRow(name: labels[0], values: ['lplibot'])];
      case 2:
        return [
          ConfigFileRow(name: labels[0], values: ['2000']),
          ConfigFileRow(name: labels[1], values: ['2000']),
          for (var i = 2; i < 6; i++)
            ConfigFileRow(name: labels[i], values: ['50']),
        ];
      case 3:
        return [
          for (var i = 0; i < 4; i++)
            ConfigFileRow(name: labels[i], values: ['1']),
        ];
      case 4:
        return [
          ConfigFileRow(name: labels[0], values: ['lplibot', '']),
        ];
      case 5:
        return [
          for (var i = 0; i < 4; i++)
            ConfigFileRow(
              name: labels[i],
              values: ['50000', '5000000', '50000000'],
            ),
        ];
      case 6:
        return [
          ConfigFileRow(name: labels[0], values: ['0', '1', '19']),
        ];
      case 7:
        return [
          ConfigFileRow(name: labels[0], values: ['SMART_IO']),
        ];
      case 8:
        return [
          ConfigFileRow(
            name: labels[0],
            values: ['0', '0', '0', '0', '14', '0', '0'],
          ),
        ];
      case 9:
        return [ConfigFileRow(name: labels[0], values: ['0'])];
      case 10:
        return [
          ConfigFileRow(
            name: labels[0],
            values: ['0', '12', '1500', '50000', '500000'],
          ),
        ];
      case 11:
        return [
          ConfigFileRow(
            name: labels[0],
            values: ['2000', '200000', '2000000'],
          ),
        ];
      case 12:
        return [
          ConfigFileRow(name: labels[0], values: ['0', '8046']),
        ];
      case 13:
        return [ConfigFileRow(name: labels[0], values: ['4'])];
      case 14:
        return List.generate(5, (i) {
          return ConfigFileRow(
            name: labels[i],
            values: List.generate(8, (j) {
              if (i == 0) return '1000';
              if (i == 1) return '32';
              return '0';
            }),
          );
        });
      case 16:
        return [ConfigFileRow(name: labels[0], values: ['192.168.1.14'])];
      case 17:
        return [ConfigFileRow(name: labels[0], values: ['0'])];
      default:
        return [
          for (var i = 0; i < labels.length; i++)
            ConfigFileRow(
              name: labels[i],
              values: List.filled(step.editableColumnCount, ''),
            ),
        ];
    }
  }

  static List<String> _pad(List<String> values, int count) {
    final out = values.map((e) => e.trim()).toList();
    while (out.length < count) {
      out.add('');
    }
    return out.take(count).toList();
  }
}
