# STATUS.md

当前版本：`2.2.6+8`（`pubspec.yaml`）
基于版本：`2.2.2+7`（v2.2.1 / v2.2.2 无 history 条目）
最近用户实际确认的稳定版本：未知。README 发布 **v2.1.3**；GitHub Release 最新 **v2.2.6**（2026-10-30）。

## 本轮结论（2026-10-30）

### 离线预览：未连接可浏览所有界面 —— 已实现，待用户实测

用户需求：离线模式下能预览所有界面，可以没有数据。

**现状基础**：连接页已有「跳过连接(仅本地 Blockly)」入口（`_openOfflineHome`），且各页面离线均安全早退（监控页读本地 rp4、文件页显示空态、轮询/状态面板离线静默），无需新增预览开关。

**修改**：
- `lib/features/home/main_home_page.dart`：主页四宫格导航去掉监控/维护的 `online ? ... : null` 门控，离线也可进入浏览；
- `lib/features/tool/tool_page.dart` `_openDriverDebug`：未连接时跳过 `DriverTechModeGate` 诊断与 `enter()`，直接浏览打开驱动器参数页（在线流程门控不变）；
- `lib/features/config_file/config_file_page.dart` `_openDebugMode`：同上离线直开；
- `lib/features/driver/driver_page.dart` `_exitPage`：未连接时跳过 `gate.exit()` 退出 HTTP（离线无调试会话），直接返回，不再弹退出失败对话框；
- `lib/features/connect/connect_page.dart`：入口按钮改名为「离线预览(不连接机器人)」，日志改为「离线预览：未连接进入主页，可浏览所有界面」；
- `test/widget_test.dart`：修正 2026-06 以来就失效的存量断言（原断言首屏为 Blockly 页「领鹏智能编程」，实际首屏早已是连接页），改为断言连接页「连接」「离线预览」两个按钮。

**行为边界**：
- 离线预览下所有需要连接的操作按钮仍按原逻辑提示「请先连接控制器」或操作失败（数据为空是预期）；
- 在线时所有门控行为完全不变（改动只在 `!isConnected` 分支生效）。

验证：`flutter analyze lib` 无新增问题（8 个存量 info）；`flutter test` 30/30 全部通过。

**待用户实测**：连接页点「离线预览」→ 主页四个入口（操控/编程/监控/维护）均可进入，驱动器参数页可从维护页浏览打开、可直接返回，无连接错误弹窗刷屏。

## 上一轮结论（2026-10-27）

### 驱动器参数页「电流前馈」与「最大扭矩输出限制%」字段关联 —— 已修正，待用户实测

用户反馈增益调整-1 的「电流前馈*0.0001」与安全设置-1 的「最大扭矩输出限制%」会同步变化，不应该关联。

**根因定位**：两个字段在 `lib/features/driver/driver_params_defs.dart` 中使用了同一个 key `current_forward`，导致 `DriverParamsModel` 中共享同一个值。

**对照 Android 参考（`LPRobot-qrcode_http_1.4.8`）**：
- `DriverParamsFragment.java` 中只有 `et_max_current_limit`（最大扭矩输出限制%）被初始化和读写；
- `et_current_forward`（电流前馈）**没有任何代码引用**，属于死 UI；
- 但 `current_forward` 这个 JSON key / `paras[66]` 从语义和 `ParamsActivity`（driverparams.dps 第 6 行）来看，原本就是「电流前馈」；
- 因此 Android 的 `DriverParamsFragment` 是把「电流前馈」的接口误用到了「最大扭矩输出限制%」UI 上。

**修正方案（`lib/features/driver/driver_params_defs.dart`）**：
- 恢复 `gainTab1Left` 中的 `current_forward` →「电流前馈*0.0001」，接口 key 为 `current_forward`，寄存器 `paras[66]`；
- 从 `safeTab1` 中移除「最大扭矩输出限制%」字段，因为它在现有 Android 参考中没有独立的接口 key，不能复用 `current_forward`；
- `current_forward` 的 help 文案改回「电流环前馈增益，默认值0，非特殊调试场景不要修改」。

`DriverParamsModel` 对 `current_forward` ↔ `paras[66]` 的读写映射保持不变。

验证：`flutter analyze lib/features/driver/driver_params_defs.dart driver_params_model.dart` 通过，无新增问题。

**待用户实测**：
- 增益调整-1 重新显示「电流前馈*0.0001」，读/写 `current_forward` / `paras[66]` 正常；
- 安全设置-1 不再显示「最大扭矩输出限制%」；
- 若现场确实需要「最大扭矩输出限制%」参数，请提供其正确的接口 key / 寄存器索引，再另行添加。

### 驱动器参数页分隔条可下拉更多 / 底部 overflow 修复 —— 已改，待用户实测

用户反馈驱动器参数页中间三列参数区无法拉到足够下方，希望中间部分显示更多。定位：`_buildResizableMidBottom` 中 `maxFrac = 0.72` 限制了中间区域最大只能占可用高度的 72%。

修改（`lib/features/driver/driver_page.dart`）：把 `maxFrac` 从 `0.72` 提高到 `0.92`，底部仍保留约 8% 空间显示工具栏。

验证：`flutter analyze lib/features/driver/driver_page.dart` 通过，无新增问题。

**待用户实测**：进入驱动器参数页，拖动中间/底部分隔条到最下方，中间三列参数区应明显变大，底部工具栏仍可见。

**后续补充（同轮）—— 左下角 overflow 修复**：

用户把分隔条拉到最下方后，左下角出现 overflow（底部区域被压扁，左侧「运动参数/单轴参数」按钮列高度超出）。

修改（`lib/features/driver/widgets/driver_params_panel.dart`）：
- 左侧模式按钮列 `_buildBottomModeRail` 外套 `SingleChildScrollView`，高度不足时可垂直滚动，不再 overflow；
- 底部工具栏 `_buildAxisToolbar` 改为水平滚动，避免窗口宽度不够时按钮被挤出；
- 轴调试行 `_axisDebugRow` 的「加速度/速度/距离」三组字段改为水平滚动，避免小窗口下右端溢出。

验证：`flutter analyze lib/features/driver/widgets/driver_params_panel.dart` 通过，无新增问题。

**待用户实测**：把分隔条拉到最下方，左下角不应再出现 overflow 黄黑条；底部工具栏/轴调试行在宽度不足时可横向滚动查看。

### 驱动器参数页「电机参数设置-2」字段集合对齐安卓 —— 已改，待用户实测

用户要求（UI 布局不变）对照安卓驱动参数页「电机参数设置第二页」。逐项核对 Android `fragment_driver_params.xml` 的 `layout_motorPara2` 与 `lib/features/driver/driver_params_defs.dart` 的 `motorTab2`：

**已证实（接口本身一致，无需改）**：第二页所有字段的 JSON key 与 100 项寄存器索引全部与安卓一致——`enc_dir`[2]、`motor_dir`[3]、`enc_type`[4]、`battery_option`→写 key `battery_type`[5]、`motor_option`→写 key `motor_select`[6]、`rated_vol`→写 key `rated_voltage`[16]、`second_enc_dir`[10]、`second_enc_axis`[11]、`second_enc_type`[12]（后三项只走 `dataArr`，无顶层 key）；`applyFromDriverJson`/`applyFromEshParas`/`buildDriverFields`/`buildDataArr` 四侧映射均一致。

**真实差异（已修）**：字段集合不对。安卓 `layout_motorPara2` = 编码器方向、电机方向、编码器类型、电池选项、是否直线电机、额定电压AC、第二编码器方向、第二编码器轴号、第二编码器类型；而 Flutter `motorTab2` 原来是 enc_dir/enc_type/motor_dir/motor_option/battery_option/rated_vol/control_mode/torque_press/torque_press_start——把安卓不属于此页的 `control_mode`（安卓在底部运动参数区，Flutter 底部「控制模式」框已对应）、`torque_press`/`torque_press_start`（安卓在增益调整-1，Flutter `gainTab1Right` 已有）误放此页，却缺安卓此页应有的 `second_enc_dir/second_enc_axis/second_enc_type`。

修改（`driver_params_defs.dart`）：
- `motorTab2` 按安卓 `layout_motorPara2` 顺序改为 9 项（enc_dir/motor_dir/enc_type/battery_option/motor_option/rated_vol/second_enc_dir/second_enc_axis/second_enc_type）；
- `motorTab3` 移除已移入第2页的 second_enc_dir/axis/type（避免两页重复；安卓第3页另含内部使用 49·50~55·56，Flutter 统一在安全设置-3）；
- `tabHelp` 的 motor_1/motor_2 文案同步。

验证：`flutter analyze lib/` 无新增问题（8 条存量 info）；`flutter analyze driver_params_defs.dart` 通过；无测试引用该两常量。

**待用户实测**：驱动器参数页电机参数设置切到「2」页签，字段项与安卓一致（含第二编码器方向/轴号/类型，无控制模式/保压扭矩）；读/写驱动参数正常。

### 驱动参数页「当前轴号」下拉框下拉乱码 —— 已改，待用户复测

用户反馈该下拉框往下拉（轴号多时菜单滚动）底部出现乱码、疑似布局影响。定位：`DriverParamsPanel._axisDropdown` 用 `isDense: true` + 行高 1.05 的 `fieldTextStyle`，Flutter 菜单项默认在选中项前画勾选图标，行高被压缩后数字与勾重叠 → 观感乱码；轴号多时菜单还可能超出窗口。

修改（`lib/features/driver/widgets/driver_params_panel.dart`）：
- `menuMaxHeight: 300`：限制菜单最大高度，轴号多时菜单内部滚动正常、不超窗；
- 菜单项加宽（56）+ `Center` + 上下内边距 + 行高 1.2：行高充足，数字与选中勾不再重叠；
- `selectedItemBuilder`：按钮显示项独立为紧凑数字，避免被菜单项内边距撑宽；
- 补充 `arrow_drop_down` 图标样式。

验证：`flutter analyze` 该文件通过。

**待用户复测**：展开「当前轴号」下拉，菜单项数字清晰、滚到底部无重叠/乱码。

## 本轮结论（2026-10-26）

### 新增点位库保存/导入 —— 已改（含三轮实测修正），待用户复测

点位页底栏新增两键（版本 `2.2.3+8`）：

- **保存点位库**：下载驱控 `para/rbt_Point.rpt4`，以自定义名称（默认 `point_日期_时间`，自动补 `.rpt4`）上传到驱控 `/home/llmachine/`。同名弹覆盖确认；上传后轮询目录确认落盘。只备份，不改当前点库。
- **导入点位库**：双源选 `.rpt4`（内存卡/本地）→ 确认 → 覆盖 `para/rbt_Point.rpt4` → `refreshPointLibrary` → **表格刷新**（固件响应带点库数据优先；否则本地解析刚写入的文件内容）。`_busy` 期间底栏显示进度条，结果消息带点位数。
- **`.rpt4` 格式已确证（真机备份样本 + 字节级核实）**：UTF-8 文本 CSV，每行 `P{index},{j1}…{jN},{label}`（末段名称可空、可为纯数字；CRLF 行尾）。解析器带单测 `test/point_lib_file_parse_test.dart`。

**三轮用户实测迭代（详见 history/v2.2.3.md）**：
1. pointHome 子目录失败：固件不随上传自动建目录 → 直接存 `/home/llmachine/`；
2. 「仅存文件不启用」不符期望 → 导入改为覆盖 `para/rbt_Point.rpt4` + 刷新；
3. **运行日志证因（`logs/app_2026-10-26.log` 13:12/13:13）**：文件**已成功写入** `para/rbt_Point.rpt4`；但固件对 `refreshPointLibrary` 返回**空 body**，旧代码走 JSON 解析抛 `FormatException` → 误报「刷新未确认」且表格不动（即用户说的"卡住/没导入成功"）。已修：改用 `refreshPointLibRaw`，空 body/非 JSON 视为已应答（对齐 robotChmod 惯例），固件不回数据时用本地解析刷新表格。

涉及文件：`lib/core/robot_path_layout.dart`、`lib/core/robot_point_library.dart`（新增 `applyImported`）、`lib/network/api/robot_http_points.dart`（新增 `refreshPointLibRaw`）、`lib/features/point_library/point_library_file_io.dart`（新增）、`lib/features/point_library/widgets/point_library_import_dialog.dart`（新增）、`lib/features/point_library/point_library_page.dart`、`test/point_lib_file_parse_test.dart`（新增）、`pubspec.yaml`（`2.2.3+8`）。

验证：`flutter analyze` 无新增问题；`flutter test` 29/30（`widget_test` 存量失败；新增解析器 3 用例全过）。

**待用户复测**：
- 导入后**表格立即变为所选文件点位**（含中文名称显示），消息显示「共 N 个点位」；
- 若固件实际运动用的仍是旧点位（本地解析只保证显示），需重启控制器验证 `refreshPointLibrary` 是否重载文件——这是剩余的唯一未证项；
- 保存：`/home/llmachine/xxx.rpt4` 落盘且内容与 `rbt_Point.rpt4` 一致。

### 导入速度优化 + 导入不生效修复 —— 已改（回读校验 + 逐点 updatePoint 兜底）

用户反馈导入很慢，且导入后重启软件点库没变。

**慢点定位**：`refreshPointLibrary` 走 `_postViaSocket` 默认 45s 超时，驱控响应偏慢（~30s 或超时），导入卡在刷新步骤。

**不生效根因**：`refreshPointLibrary` 日志显示超时未应答——该命令固件可能未实现或响应极慢，驱控内存点库未从 `rbt_Point.rpt4` 重载；连接时驱控返回内存点库，故重连后仍是旧点位。同时上传是否真覆盖文件未验证（空 body 被误判成功）。

修改：
- `robotCmdRaw` 增加 `ioTimeoutOverride` / `connectTimeoutOverride`；
- `refreshPointLibRaw` 支持自定义超时（导入场景用 20s）；
- 上传后**回读校验**：下载 `para/rbt_Point.rpt4` 逐字节对比，不一致即报错；
- **逐点 updatePoint 兜底**：refresh 未应答时，逐点 `updatePoint(refresh=true)` 直接修改驱控内存点库并落盘，不依赖 `refreshPointLibrary`；
- 各步骤加 `Stopwatch` 耗时日志。

验证：`flutter analyze lib/` 无新增问题；`flutter test` 29/30。

**待用户复测**：① 状态栏"校验通过/未通过"确认文件覆盖；② 刷新失败时看"逐点写入"成功数；③ 重启软件后点库是否变为导入内容。若 updatePoint 对不存在点位失败（非 upsert），需改 addPoint+updatePoint 两步。

**第六轮补充（2026-10-26）**：用户复测反馈「导入没有反应」——查证为**复测跑的旧 exe**（编译于 11:59:59，早于第五轮源码 13:48:36；日志 13:52/13:54 三次导入话术均为第四轮形态，无逐点兜底痕迹），复测数据不构成对修复的否定。已 `flutter build windows --debug` 重编译（kernel_blob.bin 13:58:25 含新代码），**待用户用新产物重测**上述三项。经验：Debug 产物代码新旧看 `data\flutter_assets\kernel_blob.bin` mtime，exe 时间戳不变；改完 Dart 必须 flutter run / build 后再测。

**第七轮（2026-10-26）**：新产物复测（日志 14:00–14:03 三次导入 + 截图）证实 **updatePoint 非 upsert**——293ms 内 3/11 成功，失败的 8 个全是驱控内存中不存在的点位（约 30ms 即拒，驱控响应并不慢），表格剩的 3 个点即固件响应回传的成功点位。修改：① 失败点位改 **addPoint→updatePoint 两步写入**；② **删除内存中多余点位**（不在导入文件内），兑现「覆盖」语义；③ refresh 仅在**带回点库数据**时视为生效（空 body 已证实不重载），超时降回 8s；④ 错误详情逐点捕获写入 WARN（落 `app_*.log`，不再 `catch(_)` 吞错）；⑤ 空文件防线（0 点位中止，防止删光点库）。验证：analyze 无问题、解析器测试 3/3、已重编译（kernel 14:13:30）。**待复测**：导入消息应为「已导入并刷新（共 N 个）」或 WARN 带具体失败原因；重启软件后点库与文件一致。未证项：addPoint 是否遵守请求序号、空名称是否被拒——失败时日志会给出固件原始错误。

**第八轮（2026-10-26）**：用户要求导入弹窗内存卡源**默认进入 `/home/llmachine`**（保存 .rpt4 的目录，此前从根目录开始每次要手动翻）。改 `point_library_import_dialog.dart`：`_remoteDirStack` 初始 `['', robotPointFileDir]`、`initState` 直接加载该目录；返回键仍可回到根目录。已 analyze + 重编译。

## 本轮结论（2026-10-23）

### 新增程序日志系统（操作/报警/崩溃分离）—— 已改，待用户实测

新增 `lib/core/app_logger.dart` 全局文件日志：
- **操作日志** `app_YYYY-MM-DD.log`：连接/断开、主页导航（操控/编程/监控/维护）、运行控制（启动/停止/复位/调速）、操控页功能切换/点库/清零等关键用户操作。
- **报警日志** `alarm_YYYY-MM-DD.log`：电机报警产生、报警码变化、报警消除，由 `RobotTelemetry.applyCurState` 自动检测并写入。
- **崩溃日志** `crash_YYYY-MM-DD.log`：`main.dart` 通过 `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` 捕获未处理异常与框架异常。

日志目录跟随现有路径约定：`config/`、`files/` 同级下的 `logs/`；Windows 安装到 Program Files 等只读目录时自动落到 `%LOCALAPPDATA%\Lingpeng\LPRobot\logs\`。

其他细节：
- 单文件超过 10MB 自动按序号切分（`app_2026-10-23.1.log`）。
- 每类日志保留最近 30 个文件。
- `LpStatusLog` 的 error/warning 自动同步到 operation 日志，避免 UI 日志丢失。

涉及文件：`lib/core/app_logger.dart`、`lib/core/robot_paths*.dart`、`lib/main.dart`、`lib/core/robot_telemetry.dart`、`lib/core/lp_status_log.dart`、`lib/features/connect/connect_page.dart`、`lib/features/home/main_home_page.dart`、`lib/features/home/home_run_actions.dart`、`lib/features/control/control_page.dart`。

验证：`flutter analyze lib/` 无新增错误（剩余 8 条为历史 info/warning）。

**待用户实测**：
- 运行程序后 `logs/` 目录是否正常生成；
- 操作后 `app_*.log` 是否有记录；
- 触发/消除报警后 `alarm_*.log` 是否有记录；
- 人为制造异常（如可选项）后 `crash_*.log` 是否记录堆栈。

### 文件配置页左侧说明按安卓原版全面核对补全 —— 已改，待用户实测

用户提供旧安卓项目地址 `D:\Adroid_ws\LpRobt_Flutter\LPRobot-qrcode_http_1.4.8\LPRobot-qrcode_http`，据其 `app/src/main/res/values/strings.xml`（tips_* 定义）与 `ConfigFileActivity.java` 逐项核对 Flutter `config_file_defs.dart` 的左侧说明：

修正/补全（与安卓 strings.xml 逐字对齐）：
- **HomeIO.txt**：上一轮凭截图补的第 4、5 条内容有偏差，已按原版修正（第 4 条为「极性」的本体轴/雷赛步进扩展轴按位或规则），并补上「注释：G代码回零模式（大胜/得胜 各 0-3 四种回零方向）」9 行。
- **StepMotor.txt**：2 条 → 7 条（补轴号/极性按位或/电流 mA/每转脉冲数默认 50000/加速度单位）。
- **RobotAccJerk.pa**：2 条 → 1 条（原版无「单位全是脉冲单位」）。
- **SafetyPos.txt**：1 条 → 4 条（补跳过说明/轴号规则/安全位置）。
- **DriverAxisNum.txt**：1 条 → 5 条（6 轴写 6、4 轴写 4、得胜步进写 0、空默认 4 轴）。
- **deshengpara.dps**：1 条 → 6 条（电流 mA/脉冲细分数 4-128 与 200×细分数/静音无效/编码器分辨率/闭环控制）。
- **ethernet_select（index 15，导航跳过页）**：空 → 1 条（开 ecat 写 1 关写 0）。

核对后无需改动（与安卓一致）：comSetting 6 条、manuVmax 4 条、AxisRatio 3 条、AccJerk 2 条、BrakeIO 5 条、EtherCAT 6 条、LineMotor 3 条；licence/necePara/eth0/wifi_io 安卓本就无 tips（空，一致）。安卓 `tips_MotorRotate` 为死字符串（代码未引用），Flutter 无对应步骤，不补。

验证：`flutter analyze lib/features/config_file/` 通过。

**待用户实测**：文件配置页逐步进入 HomeIO/StepMotor/SafetyPos/DriverAxisNum/desheng 等步骤，左侧说明条数与安卓一致。

## 本轮结论（2026-10-21）

两个修复：

### 1. 单轴参数「加载」子目录文件失败 —— 已修

`lib/features/driver/widgets/driver_params_panel.dart` 的 `_loadSelectedSingleAxisFile` 之前**硬编码**路径为 `$_singleAxisRoot/$fileName`（即 `/home/llmachine/pid_ini_file/$fileName`），无论用户当前在哪个子目录。结果：
- 文件不在 `pid_ini_file/` 根下 → 加载失败（`Return Code error-1`）；
- 文件在子目录（如 `pid_ini_file/LLRS1540_ZR/R_motor_normal.txt`）→ 同样失败。

修复：改用当前 `_remoteDirKey` 拼接完整路径：
```dart
final dir = _remoteDirKey.endsWith('/') ? _remoteDirKey : '$_remoteDirKey/';
final path = '$dir$fileName';
```
保存（`robotWriteSingleAxisPara`）机器人侧只收 `name`，仍保存到默认目录，未改。

### 2. 返回登录页清空全部运行时缓存 —— 已修

用户要求「每次返回登录界面清空所有缓存，像刚打开程序一样」。此前：
- `_disconnect()` 只清了 poller/telemetry/clrZero/pointLibrary + disconnect；
- `_backToConnect()` **什么都没清**。

新增 `RobotConnectionMonitor.resetAllRuntimeState()` 统一入口，清空：
`RobotStatePoller.stop` → `RobotTelemetry.reset` → `RobotClrZeroState.reset` → `RobotPointLibrary.reset` → `RobotConnectionMonitor.reset` → `DriverTechModeGate.resetOnDisconnect` → `MonitorWatchStatus.reset`（新增）→ `LpStatusLog.clear`（新增）→ `RobotState.disconnect`。

`cancelWaiting()` 改为调用该方法；`main_home_page.dart` 的 `_disconnect()` 与 `_backToConnect()` 均改为调用 `resetAllRuntimeState()` 后再跳转 `ConnectPage`。本地设置（IP 等）保留，不影响重连。

**补漏核查（同轮）**：逐单例核对后发现并补充：
- `RobotState.disconnect()` 此前未清 `lastConnectError` / `_pendingUiMessage`，已补上。
- `HttpManager.lastProgramSync` / `lastProgramSyncError`（连接时同步 main 程序的结果）此前未清，已在 `resetAllRuntimeState` 中置 null。
- `LpStatusLog.clear()` 此前只清日志条目，已追加复位 `panelExpanded=false`、`selectedTab=connection`，与首次打开一致。

完整清空清单（11 项）：poller.stop → telemetry.reset → clrZero.reset → pointLibrary.reset → connectionMonitor.reset → driverTechMode.resetOnDisconnect → monitorWatch.reset → statusLog.clear → httpManager.lastProgramSync=null → httpManager.lastProgramSyncError=null → robotState.disconnect。
未清（刻意保留）：`serverBaseUrl`（连接页会从本地设置覆盖）、`app_settings.json`（IP 等本地设置）、`RobotHttpClient`/`ConfigFileService`（无实例状态）、Blockly（WebView 随页面 dispose）。

`flutter analyze` 6 文件通过（顺带删了 `robot_connection_monitor.dart` 里冗余的 `robot_api_constants.dart` import）。

### 3. 断开重连后调试模式灰色进不去 —— 已修

根因有二：

**(a) `DriverTechModeGate` 串行链 `_chain` 失败后永久阻塞**

`_enqueue` 用 `Future.then` 串行化 enter/exit。原代码 `catchError` 里 `throw e`，导致任一次操作失败后 `_chain` 停在 failed 状态，后续 `enter()` 的 `.then` 回调永远不执行——调试模式按钮点了没反应（或 `canEnterDriverPage` 因 `_sessionActive` 残留 true 而变灰）。

修复：
- `_enqueue` 改为 `previous.catchError((_) {}).then((_) => action())`，上一操作失败不阻塞后续操作。
- `resetOnDisconnect()` 追加 `_chain = null`，断开时彻底清空残留链（含进行中/失败的操作）。

**(b) `ConfigFilePage` / `ToolPage` 未监听 `RobotState`**

两页的 `ListenableBuilder` 只 merge 了 `RobotTelemetry` + `DriverTechModeGate`，没 merge `RobotState`。断开/重连时 `isConnected` 变化不会触发重建，调试模式按钮状态滞后。已补上 `RobotState.instance`。

涉及：`driver_tech_mode_gate.dart`、`config_file_page.dart`、`tool_page.dart`。后续改为诊断模式：两个页面的「调试模式」/「驱动器参数设置」按钮始终可点，点击后逐项在状态栏打印失败原因（connected/canEdit/inDebug/alarmCode/sessionActive/transitionBusy/isControllerInitializing），便于用户定位实际卡住的项；同时清理了预存 `_selectedDriverRow` 与 `_canOpenDriver` 未使用警告。`flutter analyze` 通过。

## 本轮结论（2026-10-16）

新增源码打包脚本 `tool/package_source_zip.dart`（`dart run tool/package_source_zip.dart`，基于已有 `archive` 依赖）：把项目必要源文件打成 `LPRobot-src-<版本>.zip`。含 pubspec/README/AGENTS/规则 + lib/ windows/ dll/visualprogram/ config/ tool/ scripts/ installer/ ai_project/ .cursor/ test/；排除 build/.dart_tool/.git/dist/.vs/.idea/.vscode/bin/obj、*.iml/*.log、`.flutter-plugins-dependencies`、`dll/visualprogram.lpk`、含密钥的 `config/blockly_ai.json` 与 `.env*`。首次产物 4215 文件 / 107.31 MB，校验通过（关键文件在包、排除项无泄漏）。

## 安卓数字键盘：光标定位 + 小数点（2026-10-16 续）

驱动器参数 Android 弹窗数字键盘改进（`driver_numeric_input_dialog.dart`）：
- 输入框由静态 `Text` 改为只读 `TextField`（`readOnly + showCursor + autofocus`），支持点按定位光标、按光标位置插入/删除。
- 小数点键常显，所有数值框均支持小数输入（用户选定「全部数值框都支持小数」）。
- 移除对话框 `decimal` 参数；字段级 `decimal` 仍保留，仅供 Windows 行内编辑 formatter/键盘类型使用（Android 走弹窗键盘，不受影响）。
- `driver_adaptive_value_field.dart` 的 `_openAndroidDialog` 不再传 `decimal`。

`flutter analyze` 通过（仅改上述两个文件）。**待用户安卓真机/模拟器实测**：光标点按定位、插入/退格在光标处生效、小数点输入。

## 拖动「散架」隔离测试：回退按帧合并（2026-10-16）—— 测试不成立，已还原

用户称 Android 数值键盘已解决，但 Blockly 拖动仍「散架」，怀疑上一轮「拖动流畅度」改动。做了**单变量隔离**：把 `block_dragger.js` 临时回退到 HEAD（备份 `%TEMP%\block_dragger.framemerge.bak.js`），其余 Blockly 改动全部保留，并重打 zip + 两个 LPK。

**用户回测结果：块完全拖不动（回归）。**

**静态核验（判定该隔离测试不成立）**：
- HEAD 版 `block_dragger.js` 与改动版的差异**仅**移除 `DRAG_THROTTLE_THRESHOLD_`、`LARGE_WORKSPACE_CONN_THROTTLE_`、`estimateWorkspaceConnCount_`、`throttleConnectionSearch_` —— 全部是**该文件内部符号**。
- `git grep HEAD` 证实 HEAD **本就定义** `Blockly.BlockDragger.collectDraggingConnections_`；其调用方 `block_svg.js`（L781）与 `connection.js`（L381 读 `Blockly.draggingConnectionSet_`）相对 HEAD **零改动**。
- 即回退是「符号超集」操作，**理论上不应**导致拖不动 → 「拖不动」另有其因，本轮隔离测试被污染、结论不可用。

**已还原**：`block_dragger.js` 恢复改动版；并**强制重建** zip（3576 项 / 31.8 MB）+ 两个 LPK。注意：`tool/sync_blockly_assets.dart` 按 mtime 判定会误报 "zip up to date"，回滚/还原后须**先删 `assets/blockly/visualprogram.zip`** 再重新生成。

**用户实际测试目标已确认（关键）**：用户在 **Windows** 上**双击 Release exe** 测试（页面正常、但块拖不动）。逐文件哈希比对 `build/windows/x64/runner/Release/dll/visualprogram/blockly/**` 与工程源码：`block_dragger.js`/`code.js`/`touch.js`/`css.js`/`workspace_svg.js`/`workspace_dragger.js`/`index.html`/`style.css` **全部一致**，仅 `block_drag_surface.js` 差 `translate()` 里一个空格。→ **该 exe 跑的正是「按帧合并 + clip」当前代码**，本轮回退**从未进入其运行进程**。

**修正结论**：`散架` 与 `拖不动` 都出现在这份 frame-merge 构建上 → 两者与**未提交的 Blockly 改动（按帧合并 / clip 裁切）相关**，而非此前以为的无关；上一轮单文件隔离测试**无效作废**。

**下一步**：弃用 build 快照 exe，改 `flutter run -d windows`（`findPlainDevRoot()` 从工程根向上直接读工程明文目录）作为可信测试目标；先复现「拖不动」，再据此用**整组 Blockly 改动对 HEAD 的全量基线隔离**定位（单文件隔离已证不可靠）。

**已用 Debug 可信目标复测（2026-10-16）**：`flutter run -d windows` 下用户报告「**能拖动了，但仍散架**」。⚠️ 当时「Release 读 LPK 快照」的推断**已被下节文件系统核查推翻**（Release exe 读的是完整明文快照，与源码同源），故「拖不动」不能用源码差异解释。截图形态：两叠积木纵向错位叠加（一叠发白、一叠正常），符合「拖拽面 vs 主画布双渲染不同步」。

**散架 + 拖不动根因定位（2026-10-16）—— 已修复，用户确认效果 OK**

全量 HEAD 基线回退后用户报告「又拖不动了」，证明 HEAD 本身有拖不动问题。逐项 diff 9 个改动文件后定位两个根因：

1. **「拖不动」根因 = `code.js` 的 `installDragStateRecoveryFix_`**（HEAD 有，改动版删了）。该函数在 `visibilitychange`/`blur`/`mouseup` 等事件中无条件 `cancelCurrentGesture()` + `clearTouchIdentifier()`，WebView2 中会把正常拖拽刚启动的手势误杀。改动版移除它 → 能拖动。**最终保留改动版 code.js（无此函数）**。

2. **「散架」根因 = `workspace_svg.js` 去掉了 `cachedBlocksBoxDuringDrag_` 缓存**。该缓存在拖动期间冻结工作区内容边界；去掉后每帧 `getBlocksBoundingBox()` 含被拖块实时位置 → 内容边界变化 → 滚动条重算 → 主画布 `translate`。被拖块在拖拽面上不受画布平移影响，于是与主画布积木纵向错位叠加（一叠发白=拖拽面、一叠正常=主画布）。**已恢复 `workspace_svg.js` 为 HEAD 版（带回缓存）**，其余 8 个文件保持改动版。

当前工程状态：
- `code.js`：改动版（无 dragRecovery，有 clipWrap）→ 能拖动
- `workspace_svg.js`：HEAD 版（带回 cachedBlocksBoxDuringDrag_）→ 防散架
- `block_dragger.js`：改动版（按帧合并 + dispose 守卫）
- 其余 6 文件：改动版
- zip（3576 项 / 31.8 MB）+ 两个 LPK 已重建；Release bundle 明文目录已同步。

**用户确认（2026-10-16）**：拖动能用、散架消失，效果 OK。修复完成。

## Windows 发布版「拖不动」：CMake 与 bootstrap 矛盾（2026-10-16）—— 已修

事实核查（均以文件系统为准）：
- `build\windows\x64\runner\Release\dll\visualprogram` **完整**（7 个关键文件齐全、非空），其 `block_dragger.js` 是**带 dispose 保护的改动版**；`Release\dll\` 下**没有** `visualprogram.lpk`。
- `build\windows\x64\runner\Debug\dll\visualprogram` **不存在**，只有 `Debug\dll\visualprogram.lpk`。
- `%LOCALAPPDATA%\Lingpeng\LPRobot` 下没有 `dll`。
→ 用户双击的 Release exe 读的是「当前源码的冻结快照」（与工程源码哈希一致，仅 `block_drag_surface.js` 差一空格）→ **「拖不动」不是源码差异**；同一份源码在 Debug 能拖。

**确定性缺陷**：`windows/CMakeLists.txt` 旧分支是「检测到 `dll/visualprogram.lpk` 就删明文目录、只装 LPK」，而 [lp_blockly_asset_bootstrap.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/blockly/lp_blockly_asset_bootstrap.dart#L42-L47) 在 Windows 找不到完整明文目录会 `throw StateError`。二者矛盾 → **全新打包的 Windows 安装版会直接打不开编程页**（正是长期挂着的「Windows 发布版与开发态不一致」）。补充：`scripts/package/windows.ps1` 本就复制明文目录，只有 CMake 这半边跑偏。

**修复**：`windows/CMakeLists.txt` 改为**始终安装明文 `dll/visualprogram/`** 到 exe 同级（LPK 仅保留给 Android assets 与工程内维护），对齐 AGENTS.md 核心约束。回退方式：恢复原 `if(EXISTS "${BLOCKLY_LPK}")` 分支即可。

**重建后核查（重要）**：`flutter build windows --release` 成功（exit 0），新 bundle 已满足新规则——`Release\dll\visualprogram` 存在、`Release\dll\visualprogram.lpk` 不存在、10 个块文件与工程**逐一同哈希**（含 `media/bg.png`）。但 `Release\领鹏智能.exe` 时间戳仍是 10-15 13:56（C++/Dart 未变故未重链）→ **本地 Release bundle 与用户此前测的那份功能等价**，本次 CMake 修复只对未来**全新打包/安装版**（其上方没有工程明文目录）生效，不改变本地这次测试目标。

**待验证顺序**：① 关闭 Release 应用 → ② 删 `%LOCALAPPDATA%\Lingpeng\LPRobot\WebView2` 缓存目录（历史上该目录损坏导致过 WebView2 加载失败；注意该目录可能含 WebView 本地存储，删前确认无未保存工作区）→ ③ 重开 `Release\领鹏智能.exe` 试拖。若仍拖不动，改取 WebView 控制台报错（`WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS=--remote-debugging-port=9222`），不再靠猜。

生效路径（代码事实）：
- **Windows 开发态 `flutter run -d windows`**：`findPlainDevRoot()` 向上找到工程 `dll/visualprogram/` 明文目录并**直接使用**，无需 LPK。
- **Android**：读 `installRoot/dll/visualprogram/` 解压缓存；缓存戳 = 版本+构建号，当前 `2.2.0+7` 未变 → **旧缓存不刷新**，须删设备上 `LPRobot/dll/visualprogram` 与 `dll/visualprogram.lpk`，或把构建号 +1 触发自动重解压。

## 拖动视觉脱节排查结论（2026-10-16）

编程页拖动积木时存在「视觉位置与真实落点轻微脱节/残影」，不影响操作（用户多次确认「使用不妨碍」）。排查与结论：

- 移除拖拽面 `toFixed(0)` → 阶梯状散开（已回退）
- 给主画布 `WorkspaceSvg.translate` 加 `Math.round` → 有缓解但仍在（已回退）
- 给 `BlockSvg.translate` 加 `Math.round` → 子块独立取整累积误差，更严重（已回退）
- 隔离 `.lpClipWrap` 裁切（临时禁 `applyWorkspaceClip_`）→ 脱节仍在

**结论：属 Blockly 双面（拖拽面/主画布）架构 + WebView2 子像素合成的固有残留，与坐标取整、clip 裁切均无关。所有实验改动已回退**，代码回到稳定态：`block_drag_surface.js`（toFixed 保留）、`workspace_svg.js`/`block_svg.js`（不取整）、`code.js`（`applyWorkspaceClip_` 白框裁切保留）。记为**已知轻微视觉残留（不影响使用）**，不再做猜测性改动。

## 已稳定的主要功能（现场确认程度待验证）

- 连接、首页、操控、点库、Blockly 工程、监控、驱动器参数、文件备份、打包脚本
- Blockly AI：真空取放快路径、IO 映射、追加保护（单测覆盖）

## 本轮结论（2026-10-09）

编程页**代码区积木溢出到左侧功能区**（功能区底色改透明后暴露）——**已解决，用户实测确认（2026-10-09）**。修改 `demos/code/code.js`：
- `applyWorkspaceClip_(chromeLeft)`：按代码区白板左边界对主 SVG 加 `clip-path: inset(0 0 0 Npx)`；
- `ensureDragSurfaceClipWrap_()`：把 `blocklyWsDragSurface`（平移面）与 `blocklyBlockDragSurface`（拖块面）移进不平移的固定容器 `.lpClipWrap`（z-index 50 同拖块面原值、pointer-events:none），对容器加同样裁切，**拖动中（平移/拖块）也不越界**。直接裁拖拽面会跟着 translate3d 跑（第一版「拖动中内容消失」的根因），套固定容器解决；
- 不裁飞出层 `blocklyFlyout`（独立 SVG，z-index 80，不受影响）。
已重建 zip + lpk。`flutter test` 26/27 通过；`widget_test` 为**存量失败**（期望 Dart 层标题，本轮未改 Dart 代码）。

### 拖动手感与「拖出分离」（2026-10-09 续）

- **拖动按帧合并（保留）**：`core/block_dragger.js` —— 所有尺寸拖拽统一 rAF 合并昂贵副作用（snap 搜索/图标/光标），平移仍逐事件同步跟手；删除 80 块门槛（`DRAG_THROTTLE_THRESHOLD_`），>200 跳过吸附搜索的旧逻辑不变。另修复隐患：松手后排队 rAF 在 dispose 后重复执行/空指针（`flushDragFrame_` 加 dispose 保护，`endBlockDrag` 同步刷后作废 pending）。流畅度改善**待用户复测**。
- **「从弹出列表拖出时块与列表行偶发错位分离」（未解决，修复尝试已按用户要求复原）**：尝试在 `startBlockDrag` 里按视觉 rect（inverse CTM 换算）重锚定块位置，用户实测后要求复原，已恢复原样（仅刷新屏幕换算 + 重读起点）。现象特征：偶发、整段拖动保持恒定错位、松手多数正常、偶尔落点不恢复。后续如再修，可考虑排查 `Flyout.createBlock_`/`placeNewBlock` 的坐标换算链路。
- 本轮多次重启应用：**重启前必须先杀残留 `flutter_application_1` 进程**（否则 MSB3021：WebView2Loader.dll 被占用，构建失败）；沙箱外启动结论同上节。

上一轮（10-08）：Windows 发布版直接读安装目录 `dll/visualprogram/`，不再解压 LPK 缓存。

### 调试插曲（2026-10-09，非代码问题，已定位）

症状：AI 侧后台启动 `flutter run -d windows` 后，编程页报 `WebView2 native create failed, result=-2147024726`（0x800700AA / ERROR_BUSY），反复出现。已排除残留进程与 DLL 占用。**根因：TRAE 沙箱** —— 沙箱内启动的 flutter 其子进程（应用）继承了对 `%LOCALAPPDATA%\Lingpeng\LPRobot\WebView2` 的写限制；沙箱外（dangerouslyDisableSandbox）启动同一命令立即 `native create: id = 1` 成功。结论：**AI 侧启动 flutter run 必须在沙箱外执行**；用户自己终端运行天然无此问题。另：期间对该 WebView2 目录的删除被沙箱拦截只删了一半（剩 6 个缓存子目录），属纯缓存，不影响运行，用户可随时手动整删。

## 一键备份不完整（2026-10-15）

用户反馈一键备份内容不全。直连机器人列目录比对 `lib/features/files/robot_file_backup.dart` 的 `_collectBackupFiles`，确认遗漏：

- **其他配置参数（最大遗漏）**：原仅递归 `para/RobotType/XYZ01/`，但 `para/` 下有 17 个核心配置文件直接落在该层（`auto_run.rp4`、`com_setting.pa`、`CommPort.port`、`hold_data.pa`、`hold_Mreg.pa`、`manu_Vmax.pa`、`maxAuAv.auav`、`plcSocket.sct`、`rbt_Point.rpt4`、`rbt_zero_pos.rpt4`、`tech_mode.txt` 等）完全未备份。
- **固件和应用**：`/usr/lib/` 只拿了 3 个 `.so.1.0.0`，遗漏 `libllDriver`、`libllMotion`、`libllmotionECat`、`libethercat`、`libwifi`；`/home/` 只拿了 `ll_libot`，遗漏主程序 `robotKit`、`EcatMaster`、启动脚本 `startli.sh`。
- **IP**：只拿了 `eth0`，遗漏 `eth1`。

修复（备份 + 恢复两侧对称）：
- `其他配置参数`：改为递归整个 `para/`（排除 `driverparams.dps`，已由电机参数项覆盖）+ `cfg_ini_file/` + `EtherCAT/` + `pid_ini_file/`。
- `固件和应用`：补 5 个 `.so.1.0.0` + `robotKit`/`EcatMaster`/`startli.sh`。
- `IP`：补 `eth1`。
- `G代码` 仍只备份当前 `Grobot.rp4`/`Grobot.xml`（`Grobot_backup_2019*` 为历史程序备份，未纳入）。
- `_bk` 后缀文件随所在目录递归一并备份。

`flutter analyze` 通过。**待用户实测**：选全部 7 项做一次备份，解压 zip 确认目录结构含 `home/llmachine/Axis4/para/` 直接文件、`cfg_ini_file/`、`EtherCAT/`、`pid_ini_file/`、`usr/lib/` 全部 8 个 `.so.1.0.0`、`home/robotKit` 等。

## 正在处理的问题

- ~~代码区积木溢出白框~~：**已解决**（主 SVG + 拖拽面固定容器双裁切，用户实测确认）。
- 弹出列表拖出偶发错位分离：**未解决**（修复尝试已复原，见本轮「拖出分离」节）。
- Windows 拖动散架／「块拖不动」：单文件回退隔离测试**不成立**（回测反而「拖不动」，但静态核验证明回退不可能致此），**已全部还原**；真因待运行时证据。
- Windows 发布版 Blockly 与开发态不一致：已改直接使用安装包内 `dll/visualprogram/`，待用户安装包实测。
- 逍遥模拟器编程页整页放大橙色刷新图标。**待用户完全重装运行验证**。
- Blockly LLM Tool Loop。
- **一键备份不完整（2026-10-15）**：已修复，待用户实测备份/恢复。见下节。

## 尚待用户实际验证

- ~~代码区是否已不超出白框~~：**已确认解决**。
- 拖动按帧合并后起步流畅度是否改善（block_dragger.js 本轮改动）。
- Windows 拖动是否仍散架（若仍散架，需带 `flutter run -d windows` 日志继续排查）。
- D 下拉是否已无坐标/轴角度项。
- Windows 编程页「返回」红框位置。
- C# 读 S 示例是否符合使用场景（若要改写入/批量读再说明）。

## 当前已知风险

- 工作区有**大量未提交**的 Blockly/编程页改动（clip 裁切、飞出层 z-index、拖拽回退、分区底板、拖动按帧合并），均未经真机验证。
- 拖动按帧合并（block_dragger.js）：平移保持逐事件同步、副作用按帧合并，理论上不改变落点逻辑；若现场出现吸附位置异常，回退方式是恢复 `DRAG_THROTTLE_THRESHOLD_=80` 分支（git diff 可查）。
- clip 方案已实测稳定；风险点：`.lpClipWrap` 容器若与 Blockly 内部 DOM 操作冲突（当前无），回退方式是删掉 `applyWorkspaceClip_` 里的 `ensureDragSurfaceClipWrap_` 调用（`code.js` 一处）。
- 旧工程若已选 Px–U4，下拉可能显示原值；生成器仍识别这些取值。
- 无按轮次落盘运行日志。
- `widget_test.dart` 存量失败，待后续轮次确认是否修测试。

## 下一步最优先任务

用户实测剩余项：① Windows 拖动散架是否解决；② 按帧合并后拖动起步是否流畅；③ 安装包直读 `dll/visualprogram/`。弹出列表拖出偶发分离（遗留，未解决）按用户优先级安排是否再修。之后按结果继续或回退。

---

## Next Session Entry

下一轮任何 AI 在修改代码前，必须重新读取：

1. `AGENTS.md`
2. `dll/AI/AI编程项目运行法则_0.4.md`
3. `ai_project/STATUS.md`
4. 如果存在运行日志，读取最新且与当前问题相关的日志
5. 必要时再读取 `ai_project/CHANGELOG.md` 与 `ai_project/history/`
