import 'package:flutter_application_1/platform/local_network_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalNetworkInfo.parseNetshWlanSsid', () {
    test('English connected interface returns SSID, not BSSID', () {
      const output = '''
There is 1 interface on the system:

    Name                   : Wi-Fi
    Description            : Intel(R) Wi-Fi 6 AX201 160MHz
    GUID                   : xxxxxxxx
    Physical address       : 00:11:22:33:44:55
    State                  : connected
    SSID                   : LP-Robot-AP
    BSSID                  : aa:bb:cc:dd:ee:ff
    Network type           : Infrastructure
''';
      expect(LocalNetworkInfo.parseNetshWlanSsid(output), 'LP-Robot-AP');
    });

    test('Chinese connected interface returns SSID', () {
      const output = '''
系统上有 1 个接口:

    名称                   : WLAN
    描述                   : Intel(R) Wi-Fi
    状态                   : 已连接
    SSID                   : 领鹏智能
    BSSID                  : aa:bb:cc:dd:ee:ff
''';
      expect(LocalNetworkInfo.parseNetshWlanSsid(output), '领鹏智能');
    });

    test('disconnected Wi-Fi returns null', () {
      const output = '''
    Name                   : Wi-Fi
    State                  : disconnected
    SSID                   : leftover
''';
      expect(LocalNetworkInfo.parseNetshWlanSsid(output), isNull);
    });

    test('empty or placeholder SSID returns null', () {
      expect(
        LocalNetworkInfo.parseNetshWlanSsid('''
    State                  : connected
    SSID                   : <None>
'''),
        isNull,
      );
      expect(LocalNetworkInfo.sanitizeSsid('<unknown ssid>'), isNull);
      expect(LocalNetworkInfo.sanitizeSsid('"Office-WiFi"'), 'Office-WiFi');
    });
  });

  test('ethernet fallback label', () {
    expect(LocalNetworkInfo.ethernetLabel, '控制器IP');
  });

  test('wifi label prefix', () {
    expect(LocalNetworkInfo.wifiLabel('ly-guest'), '当前连接WIFI：ly-guest');
  });
}
