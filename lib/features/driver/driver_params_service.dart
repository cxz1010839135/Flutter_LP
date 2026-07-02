import '../../core/robot_telemetry.dart';
import '../files/robot_file_transfer.dart';
import '../../network/http_manager.dart';
import 'driver_params_model.dart';

/// 驱动器参数读写（对齐 Android HttpManager + DriverParamsFragment）。
class DriverParamsService {
  int get totalAxisNum {
    final t = RobotTelemetry.instance.controllerAxisCount;
    return t < 4 ? 6 : t;
  }

  int get driverAxisNum {
    final ext = RobotTelemetry.instance.extensionAxisCount;
    return totalAxisNum - ext;
  }

  bool isDriverAxis(int axis) => axis <= driverAxisNum - 1;

  Future<void> readParams(int axis, DriverParamsModel model) async {
    if (isDriverAxis(axis)) {
      final res = await HttpManager.instance.driverGetParams(axis: axis);
      res.ensureOk();
      model.applyFromDriverJson(Map<String, dynamic>.from(res.root));
      return;
    }
    final res = await HttpManager.instance.robotEshGetPara(axis: axis);
    res.ensureOk();
    final value = res.root['value'];
    if (value is List) {
      final paras = value.map((e) => DriverParamsModel.parseInt(e.toString())).toList();
      model.applyFromEshParas(paras);
    }
  }

  Future<void> writeParams(int axis, DriverParamsModel model) async {
    final dataArr = model.buildDataArr();
    if (isDriverAxis(axis)) {
      final res = await HttpManager.instance.driverSetParams(
        axis: axis,
        dataArr: dataArr,
        driverFields: model.buildDriverFields(),
      );
      res.ensureOk();
      return;
    }
    final res = await HttpManager.instance.robotEshSetPara(
      axis: axis,
      paras: dataArr,
    );
    res.ensureOk();
  }

  Future<void> writeParamsToFile(int axis, DriverParamsModel model) async {
    await writeParams(axis, model);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final res = await HttpManager.instance.driverParamsToFile();
    res.ensureOk();
  }

  Future<DriverAxisLiveStatus> pollAxisStatus(int axis) async {
    final res = await HttpManager.instance.robotTechAxisStatus(axis: axis);
    final status = DriverAxisLiveStatus();
    if (!res.isOk) return status;
    final arr = res.root['dataArr'];
    if (arr is List) status.applyFromDataArr(arr);
    return status;
  }

  Future<void> setServo(int axis, bool on) async {
    final res = await HttpManager.instance.driverSetServo(
      axis: axis,
      state: on ? 1 : 0,
    );
    res.ensureOk();
  }

  Future<void> setMotionActive(int axis, bool on) async {
    final res = await HttpManager.instance.driverSetMotionActive(
      axis: axis,
      state: on,
    );
    res.ensureOk();
  }

  Future<void> softReset() async {
    final res = await HttpManager.instance.driverReset();
    res.ensureOk();
  }

  Future<void> findPhase(int axis) async {
    final res = await HttpManager.instance.robotTechFindPhase(axis: axis);
    res.ensureOk();
  }

  Future<void> stopPhase(int axis) async {
    final res = await HttpManager.instance.robotTechStopPhase(axis: axis);
    res.ensureOk();
  }

  Future<List<RemoteFileEntry>> listSingleAxisParamFiles() {
    return RobotFileTransfer.listRemote('/home/llmachine/pid_ini_file/');
  }

  Future<List<RemoteFileEntry>> listRemoteDir(String dirKey) {
    return RobotFileTransfer.listRemote(dirKey);
  }

  Future<void> loadSingleAxisParams(int axis, String filePath, DriverParamsModel model) async {
    final res = await HttpManager.instance.robotReadSingleAxisPara(
      axis: axis,
      path: filePath,
    );
    res.ensureOk();
    final value = res.root['value'];
    if (value is List) {
      final paras = value.map((e) => DriverParamsModel.parseInt(e.toString())).toList();
      model.applyFromEshParas(paras);
    }
  }

  Future<void> saveSingleAxisParams(int axis, String filePath) async {
    final rawName = filePath.split('/').last;
    final name = rawName.toLowerCase().endsWith('.txt')
        ? rawName.substring(0, rawName.length - 4)
        : rawName;
    final res = await HttpManager.instance.robotWriteSingleAxisPara(
      axis: axis,
      name: name,
    );
    res.ensureOk();
  }

  Future<void> techMove({
    required int returnTrip,
    required int repeat,
    required int chart,
    required int chartData,
    required int chartAxis,
    required int delayMs,
    required List<int> axes,
    required List<int> positions,
    required List<int> velocities,
    required List<int> accs,
    required List<int> jerks,
  }) async {
    final res = await HttpManager.instance.robotTechMove({
      'return': returnTrip,
      'repeat': repeat,
      'chart': chart,
      'chart_data': chartData,
      'chart_axis': chartAxis,
      'delay_time': delayMs,
      'AxisValue': axes,
      'PosValue': positions,
      'VelValue': velocities,
      'AccValue': accs,
      'JerkValue': jerks,
    });
    res.ensureOk();
  }

  Future<Map<String, List<double>>> fetchWaveformData({
    required int index,
    required int len,
  }) async {
    final res = await HttpManager.instance.robotTechGetData(
      index: index,
      len: len,
    );
    res.ensureOk();
    List<double> toList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map<double>((e) => e is num ? e.toDouble() : 0)
          .toList();
    }

    return {
      'iq_ref': toList(res.root['iq_ref']),
      'iq_fbd': toList(res.root['iq_fbd']),
      'sp_ref': toList(res.root['sp_ref']),
      'sp_fbd': toList(res.root['sp_fbd']),
      'pos_err': toList(res.root['pos_err']),
    };
  }
}
