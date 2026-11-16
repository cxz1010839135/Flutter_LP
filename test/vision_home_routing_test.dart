import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/robot_state.dart';
import 'package:flutter_application_1/features/connect/connect_page.dart';
import 'package:flutter_application_1/features/home/main_home_page.dart';
import 'package:flutter_application_1/features/home/vision_home_page.dart';

/// 视觉机型首页分流验证（v2.2.7）：
/// 控制器上报型号（robot.model，即主页底栏机型名）以 SJ 开头 → 视觉首页；
/// 其余型号（如 XYZ01）与离线预览（空型号）→ 原主页。
void main() {
  tearDown(() {
    // 直接复位字段，避免触发 notifyListeners / 平台通道。
    RobotState.instance
      ..isConnected = false
      ..robotModel = '';
  });

  group('RobotState.isVisionModel（SJ 前缀，暂定规则）', () {
    test('SJ01 → 视觉机型', () {
      RobotState.instance.robotModel = 'SJ01';
      expect(RobotState.instance.isVisionModel, isTrue);
    });

    test('sj02（小写）→ 视觉机型（不区分大小写）', () {
      RobotState.instance.robotModel = 'sj02';
      expect(RobotState.instance.isVisionModel, isTrue);
    });

    test('SJ-100（带连字符）→ 视觉机型', () {
      RobotState.instance.robotModel = 'SJ-100';
      expect(RobotState.instance.isVisionModel, isTrue);
    });

    test('SJ01 前后带空格 → 视觉机型（先 trim）', () {
      RobotState.instance.robotModel = ' SJ01 ';
      expect(RobotState.instance.isVisionModel, isTrue);
    });

    test('XYZ01 → 非视觉机型', () {
      RobotState.instance.robotModel = 'XYZ01';
      expect(RobotState.instance.isVisionModel, isFalse);
    });

    test('XSJ01 → 非视觉机型（SJ 必须在开头）', () {
      RobotState.instance.robotModel = 'XSJ01';
      expect(RobotState.instance.isVisionModel, isFalse);
    });

    test('空型号（离线预览）→ 非视觉机型', () {
      RobotState.instance.robotModel = '';
      expect(RobotState.instance.isVisionModel, isFalse);
    });
  });

  group('buildHomePageByModel 连接后首页分流', () {
    test('SJ01 → VisionHomePage', () {
      RobotState.instance
        ..isConnected = true
        ..robotModel = 'SJ01';
      final Widget page = buildHomePageByModel();
      expect(page.runtimeType, VisionHomePage);
    });

    test('XYZ01 → MainHomePage（现有主页不变）', () {
      RobotState.instance
        ..isConnected = true
        ..robotModel = 'XYZ01';
      final Widget page = buildHomePageByModel();
      expect(page.runtimeType, MainHomePage);
    });

    test('空型号（离线预览）→ MainHomePage', () {
      RobotState.instance
        ..isConnected = false
        ..robotModel = '';
      final Widget page = buildHomePageByModel();
      expect(page.runtimeType, MainHomePage);
    });
  });
}
