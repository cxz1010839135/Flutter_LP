import 'dart:io';

import '../lib/features/config_file/driver_params_dps_codec.dart';

void main() {
  for (final path in [
    r'files/downloads/192.168.1.14/Backup_/home/llmachine/Axis4/para/RobotType/440/driverparams.dps',
    r'files/downloads/192.168.1.14/Backup_/home/llmachine/Axis4/para/RobotType/XR940S180L5/driverparams.dps',
  ]) {
    print('=== $path ===');
    final raw = File(path).readAsStringSync();
    final parsed = DriverParamsDpsCodec.parse(raw);
    print('axisCount: ${parsed.axisCount}, rows: ${parsed.rows.length}');
    final layout = parsed.layout!;
    final back = DriverParamsDpsCodec.serialize(parsed.rows, layout);
    final reparsed = DriverParamsDpsCodec.parse(back);
    final same = parsed.rows.length == reparsed.rows.length &&
        parsed.axisCount == reparsed.axisCount;
    print('roundtrip ok: $same');
    print('');
  }
}
