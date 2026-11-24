# CHANGELOG

简洁版本索引。移植期详细条目仍在 [docs/migration/changelog/CHANGELOG.md](../docs/migration/changelog/CHANGELOG.md)，此处不整份复制。

## v2.3.0

- 日期：2026-11-24
- 修改：寄存器监视面板新增「新通讯」兼容开关——新 TCP 8088 数字指令协议客户端（照搬 DScom.cs：get_M=1/get_D=3/get_S=130，扁平 JSON 无换行，按 result/data 解析，请求串行+失败断线重连+超时防卡轮询）；开关开且 D/M/S 走新协议，X/Y 恒走旧 HTTP；开关与通道指示（TCP·8088/HTTP）随页签实时显示并持久化。文件管理页：本地目录路径改可点击面包屑（点任意层直接跳转）；左右分栏中间分界线可拖拽（10%~90%，同驱动器参数页分割交互）；一键备份/恢复按钮与右侧按钮同尺寸；第二排新增「安装目录」「日志目录」按钮（explorer 直达，日志目录自动定位 LOCALAPPDATA 回退位置）。运行日志写入 UTF-8 BOM（记事本不乱码，仅新建文件生效）。安装器：LpWebView2Repair.exe 改静态链接 C/C++ 运行库，裸机无 VC++ 运行库不再报 VCRUNTIME140_1.dll 缺失（根因=CMakeLists 中 CMAKE_MSVC_RUNTIME_LIBRARY 设在 add_executable 之后未生效）
- 状态：已发布 GitHub Release v2.3.0（2026-11-24，apk + msi + Setup.exe）；用户已实测新 TCP 协议跑通（netstat 见 8088 ESTABLISHED）
- 详情：history/v2.3.0.md

## v2.2.8

- 日期：2026-11-19
- 修改：一键备份/恢复新增 FPGA/SDK 固件（`/opt/firmware/fpga_servo.bin`、`sdk_servo.img`，恢复下发到 `/usr/appupdate/`）；机械手类型修改页保存加密码确认（默认 0000）；下载脚本源码 ZIP 改为 Gitee Release 附件优先（国内直连），GitHub API 版本解析超时 15s→5s
- 状态：已发布 GitHub Release v2.2.8（2026-11-19）
- 详情：STATUS.md 2026-11-19 节

## v2.2.7

- 日期：2026-11-04（2026-11-16 / 2026-11-17 补充）
- 修改：视觉机型首页分流——控制器上报型号以 `SJ` 开头（暂定规则，`RobotState.isVisionModel`）时连接成功进入新视觉首页骨架（同主页风格顶栏/四键/运行栏/底栏，中央为视觉功能占位区）；其余型号与离线预览仍走原主页，现有界面零改动。视觉首页「编程」按钮为占位提示，不进 Blockly（视觉后期引入专属编程界面，不套用 Blockly）。补充：配置页新增第 7 键「视觉程序退出」——发送指令头 `robotExitProgram` 给下位机视觉软件（下位机只认指令头；响应空/非 JSON 视为已应答）。补充：文件配置向导新增 eth1 步骤（`/home/llmachine/ipaddress/eth1`，排在 eth0 之后），下位机无该文件时可一键创建，默认 IP `192.168.88.10`（用户指定，可改）。补充：文件配置向导首位新增「机械手类型」下拉步骤——选项来自 `RobotTypeList.rtl`，选中保存写入 `DefaultRobotType.drt`（重启驱控生效）；drt 缺失时保存即创建。补充：一键备份/恢复新增新版程序库名 `librobot.so`/`libplc.so`/`libecat_rk.so`/`ll_main`（文件存在才导出导入，兼容旧版控制器与旧备份包；ll_main 恢复后补 +x），备份排除 `/home/llmachine/EtherCAT`（太大；恢复侧仍兼容旧备份包）。补充：文件管理左侧本地目录头部新增「返回上一级」按钮（与右侧驱控目录返回同款，调用既有本地后退逻辑，顶层置灰）
- 状态：待用户实测；已发布 GitHub Release v2.2.7（2026-11-17，含 apk + msi + Setup.exe）
- 详情：history/v2.2.7.md

## v2.2.6

- 日期：2026-10-30
- 修改：离线预览——连接页入口改「离线预览(不连接机器人)」，主页监控/维护与驱动器参数页离线可浏览（在线门控不变，离线退出驱动器页不发 HTTP）；驱动器参数页分隔条 maxFrac 0.72→0.92、左列/底部/轴调试行滚动兜底修 overflow；「电流前馈」与「最大扭矩输出限制%」key 冲突修正（`current_forward`=`paras[66]` 归位增益调整-1）；修正存量失效 widget_test（首屏断言连接页）。本轮推送 GitHub 并发布 Release v2.2.6（上次 GitHub release 为 v2.1.3，2.1.4–2.2.5 为本地迭代）
- 状态：待用户实测；已发布 GitHub Release
- 详情：history/v2.2.6.md

## v2.2.3

- 日期：2026-10-26
- 修改：点位页底栏新增「保存点位库」「导入点位库」；保存=当前点库以自定义名备份到驱控 `/home/llmachine/`（.rpt4）；导入=双源选 `.rpt4`，覆盖驱控 `para/rbt_Point.rpt4` 后表格刷新（固件 `refreshPointLibrary` 空 body 容错 + 本地解析 `.rpt4` 文本兜底，解析器带单测）；构建号 `+8`。经五轮真机实测迭代：① 固件不随上传建目录（pointHome 废弃）→ 直存 `/home/llmachine/`；② 导入由"仅存文件"改为"导入即刷新"；③ 日志证实刷新命令返回空 body 误报失败 → `refreshPointLibRaw` + 本地解析兜底；④ 导入慢 → `refreshPointLibRaw` 超时从 45s 降到 8s + 各步耗时日志；⑤ 导入后重启点库没变 → 上传后回读校验 + refresh 超时调到 20s + 逐点 `updatePoint(refresh=true)` 兜底（不依赖 refreshPointLibrary）
- 状态：待用户复测（回读校验确认文件覆盖、逐点写入成功数、重启后点库是否更新）
- 详情：history/v2.2.3.md

## v2.2.2 / v2.2.1

- 日期：未知（dist 有对应安装包；本轮接手时 pubspec 已是 `2.2.2+7`）
- 修改：未知（无 history 条目，未追溯）
- 状态：无法确认

## v2.1.6

- 日期：2026-09-15；补充 2026-09-17
- 修改：Windows 顶栏「返回」对齐奶油槽上半；D 取值下拉隐藏坐标/轴角度（构建号 `+7`）；Windows 拖动散架实验性回退（关闭未提交的视觉节流与视口裁剪）
- 状态：待用户刷新编程页确认下拉；拖动散架待用户实测
- 详情：history/v2.1.6.md

## v2.1.5

- 日期：2026-09-14；补充 2026-09-15
- 修改：工程记忆；Tool Loop；模拟器刷新图标/拖块/双返回/顶栏偏上；逍遥巨大刷新图标改 Hybrid Composition（`+4`）
- 状态：待用户实际验证
- 详情：history/v2.1.5.md

## v2.1.4

- 日期：未知
- 修改：未知（迁移 changelog 无条目；pubspec 已越过此号）
- 状态：无法确认
- 详情：无独立 history 文件

## v2.1.3

- 日期：2026-09-07
- 修改：编程页功能区与代码区拆分；备份恢复小文件覆盖上传
- 状态：README 记为已发布；本轮未复核现场
- 详情：docs/migration/changelog/CHANGELOG.md（无 ai_project/history 副本）

更早版本索引见迁移 changelog（2.1.2、2.0.7、2.0.6 …）。
