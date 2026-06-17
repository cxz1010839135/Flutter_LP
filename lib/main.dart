import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_win_floating/webview_win_floating.dart';

import 'app/lp_robot_colors.dart';
import 'app/lp_robot_theme.dart';
import 'app/widgets/lp_app_navigator.dart';
import 'app/widgets/robot_connection_guard.dart';
import 'core/app_info.dart';
import 'core/robot_paths.dart';
import 'features/connect/connect_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  StackTrace? startupStack;
  try {
    await AppInfo.load();
    await RobotPaths.ensureLayout();
  } catch (e, st) {
    startupError = e;
    startupStack = st;
  }
  if (Platform.isWindows || Platform.isLinux) {
    WindowsWebViewPlatform.registerWith();
  }
  if (startupError != null) {
    runApp(_LpStartupErrorApp(
      error: startupError,
      stackTrace: startupStack,
    ));
    return;
  }
  runApp(const LpRobotApp());
}

/// 启动阶段路径/配置初始化失败时展示，避免白屏。
class _LpStartupErrorApp extends StatelessWidget {
  const _LpStartupErrorApp({
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: LpRobotColors.pageBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '应用初始化失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('$error'),
                if (stackTrace != null) ...[
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        '$stackTrace',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LpRobotApp extends StatelessWidget {
  const LpRobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.displayTitle,
      debugShowCheckedModeBanner: false,
      theme: lpRobotTheme(),
      navigatorKey: lpRootNavigatorKey,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return RobotConnectionGuard(
          child: LpEscapeBackShortcuts(child: child),
        );
      },
      home: const ConnectPage(),
    );
  }
}
