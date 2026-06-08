import 'dart:convert';

import '../core/robot_api_constants.dart';

/// 标准 JSON 响应：`{result, msg, data}`（Android [HttpManager.checkResponse]）。
class RobotApiResponse {
  RobotApiResponse(this.root);

  final Map<String, dynamic> root;

  int get result {
    final v = root[RobotApiConstants.result];
    if (v is num) return v.toInt();
    return 0;
  }

  String get msg => root[RobotApiConstants.msg]?.toString() ?? '';

  dynamic get data => root[RobotApiConstants.data];

  bool get isOk => result == RobotApiConstants.resultOk;

  Map<String, dynamic>? get dataMap {
    final d = data;
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  String? get dataString => data?.toString();

  static RobotApiResponse parse(String body) {
    var text = body.trim();
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      final preview = text.length > 200 ? '${text.substring(0, 200)}…' : text;
      throw FormatException('响应不是 JSON 对象：$preview');
    }
    return RobotApiResponse(Map<String, dynamic>.from(decoded));
  }

  /// 尝试解析；若 body 非 JSON（如 XML/G 代码直返）则返回 null。
  static RobotApiResponse? tryParse(String body) {
    try {
      return parse(body);
    } catch (_) {
      return null;
    }
  }

  void ensureOk() {
    if (!isOk) {
      throw Exception(msg.isNotEmpty ? msg : '请求失败 (result=$result)');
    }
  }

  /// 解析并校验 result == 1，返回 data。
  static dynamic parseOkData(String body) {
    final res = parse(body);
    res.ensureOk();
    return res.data;
  }
}
