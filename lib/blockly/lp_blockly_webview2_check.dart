import 'dart:io';

/// Windows 上 WebView2 运行时可用性提示（Blockly 依赖 WebView2）。
abstract final class LpBlocklyWebView2Check {
  static const String downloadUrl =
      'https://go.microsoft.com/fwlink/p/?LinkId=2124703';

  static const String installHint =
      '本机未检测到 Microsoft WebView2 运行时。\n'
      '请下载安装 Evergreen 引导程序后重启应用：\n'
      '$downloadUrl';

  /// 在注册表、环境变量和运行时目录中探测 WebView2。
  ///
  /// 注意：Microsoft Edge 浏览器不等于 WebView2 Runtime，不能用
  /// `msedge.exe` 作为已安装依据，否则全新电脑会被误判。
  static Future<bool> isRuntimeLikelyInstalled() async {
    if (!Platform.isWindows) return true;

    final fixedRuntime = Platform.environment[
        'WEBVIEW2_BROWSER_EXECUTABLE_FOLDER'];
    if (fixedRuntime != null &&
        fixedRuntime.trim().isNotEmpty &&
        await _containsRuntimeExecutable(Directory(fixedRuntime))) {
      return true;
    }

    const clientId = r'{F3017226-FE2A-4295-8BDF-00B3D39F16CB}';
    final keys = <String>[
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\' + clientId,
      r'HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\' + clientId,
      r'HKCU\SOFTWARE\Microsoft\EdgeUpdate\Clients\' + clientId,
    ];

    for (final key in keys) {
      try {
        final result = await Process.run(
          'reg',
          ['query', key, '/v', 'pv'],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          final out = '${result.stdout}';
          final version = RegExp(
            r'\bpv\s+REG_SZ\s+([0-9]+(?:\.[0-9]+){2,3})',
            caseSensitive: false,
          ).firstMatch(out)?.group(1);
          if (version != null && version != '0.0.0.0') {
            return true;
          }
        }
      } catch (_) {
        // ignore
      }
    }

    final localAppData = Platform.environment['LOCALAPPDATA'];
    final programFilesX86 = Platform.environment['ProgramFiles(x86)'];
    final programFiles = Platform.environment['ProgramFiles'];
    for (final root in [
      if (programFilesX86 != null)
        '$programFilesX86\\Microsoft\\EdgeWebView\\Application',
      if (programFiles != null)
        '$programFiles\\Microsoft\\EdgeWebView\\Application',
      if (localAppData != null)
        '$localAppData\\Microsoft\\EdgeWebView\\Application',
    ]) {
      if (await _containsRuntimeExecutable(Directory(root))) return true;
    }

    return false;
  }

  static Future<bool> _containsRuntimeExecutable(Directory root) async {
    if (!await root.exists()) return false;
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('msedgewebview2.exe')) {
          return true;
        }
        if (entity is Directory) {
          final executable = File(
            '${entity.path}${Platform.pathSeparator}msedgewebview2.exe',
          );
          if (await executable.exists()) return true;
        }
      }
    } catch (_) {
      // 无权读取系统目录时继续使用其他探测方式。
    }
    return false;
  }

  /// 打开微软 WebView2 Evergreen 下载页。
  static Future<void> openInstallPage() async {
    if (!Platform.isWindows) return;
    await Process.start(
      'explorer.exe',
      [downloadUrl],
      mode: ProcessStartMode.detached,
    );
  }
}
