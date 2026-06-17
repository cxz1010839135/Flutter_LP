import '../../network/http_manager.dart';

/// 地址/总线/SDO 调试（对齐 Android [DriverDebugActivity]）。
class DriverAddressDebugService {
  Future<String> readDriverParam({
    required int axis,
    required int addr,
  }) async {
    final res = await HttpManager.instance.driverGetParam(axis: axis, addr: addr);
    return _extractScalar(res);
  }

  Future<void> writeDriverParam({
    required int axis,
    required int addr,
    required int value,
  }) async {
    final res = await HttpManager.instance.driverSetParam(
      axis: axis,
      addr: addr,
      value: value,
    );
    res.ensureOk();
  }

  Future<String> readBusData({required int addr}) async {
    final res = await HttpManager.instance.getBusdata(addr: addr);
    return _extractScalar(res);
  }

  Future<void> writeBusData({
    required int addr,
    required int value,
  }) async {
    final res = await HttpManager.instance.setBusdata(addr: addr, value: value);
    res.ensureOk();
  }

  Future<String> readSdo({
    required int axis,
    required int index,
    required int subIndex,
    required int dataSize,
  }) async {
    final res = await HttpManager.instance.robotGetSdo(
      axis: axis,
      index: index,
      subIndex: subIndex,
      dataSize: dataSize,
    );
    res.ensureOk();
    final data = res.data;
    if (data == null) return '';
    return data.toString();
  }

  Future<void> writeSdo({
    required int axis,
    required int index,
    required int subIndex,
    required int dataSize,
    required int data,
  }) async {
    final res = await HttpManager.instance.robotSetSdo(
      axis: axis,
      index: index,
      subIndex: subIndex,
      dataSize: dataSize,
      data: data,
    );
    res.ensureOk();
  }

  /// 解析读回标量（兼容 Android 旧版 substring 与标准 JSON）。
  String _extractScalar(RobotApiResponse res) {
    if (!res.isOk) {
      throw Exception(res.msg.isNotEmpty ? res.msg : '读取失败 (result=${res.result})');
    }
    final data = res.data;
    if (data != null) return data.toString();
    for (final key in const ['value', 'data', 'addr']) {
      final v = res.root[key];
      if (v != null) return v.toString();
    }
    return '';
  }

  static int parseInt(String text, {int fallback = 0}) {
    final t = text.trim();
    if (t.isEmpty) return fallback;
    return int.tryParse(t) ?? fallback;
  }

  static int parseHex(String text, {int fallback = 0}) {
    final t = text.trim();
    if (t.isEmpty) return fallback;
    return int.tryParse(t, radix: 16) ?? fallback;
  }
}
