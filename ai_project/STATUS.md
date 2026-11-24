# STATUS.md

当前版本：`2.3.0+8`（`pubspec.yaml`）
基于版本：`2.2.8`
最近用户实际确认的稳定版本：未知。README 发布 **v2.1.3**；GitHub Release 最新 **v2.3.0**（2026-11-24，含 Setup.exe + msi + apk，Gitee 同步 tag + 源码 zip 附件）。

## 本轮结论（2026-11-24）

### 寄存器监视面板新增「新通讯方式」兼容开关 —— 已改，待用户实测

用户需求（图 + 参考 C# 源码 DScom.cs）：编程页右侧寄存器监视面板加兼容开关（面板标题前，默认开=新方式），对照 `DScom.cs` 新版协议；只影响监视面板的读取，其它功能不动。

DScom.cs 新版协议（已逐行核对）：TCP 8088 长连接；发送扁平 JSON（无换行）：`{"command":<数字码>,"data":{...}}`；响应取 `result`（==1 成功）与 `data`；指令码 get_M=1、get_D=3、set_M=5、set_D=16、get_Marr=21、get_Darr=22、get_S=130；请求串行（C# lock）；失败断线重连（Re_connect）；**新版协议无 robot_get_X / robot_get_Y 指令**（C# 直接 return false）。Flutter 现状=旧版 HTTP 字符串指令（`robot_get_D` 等）。

修改：
- 新增 [ds_tcp_client.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/network/ds_tcp_client.dart)：`DsTcpClient` 单例，dart:io Socket 连 8088（IP 取 `RobotState.connectionHost`），请求串行链、发送 JSON（无换行，同 C#）、收包按分片累积到可 jsonDecode 为止（防半包）、1.5s 响应超时、2s 连接超时、失败断开下次请求自动重连、连接失败 2s 内快速跳过（防死轮询卡整轮）；`readRegister(command, index)` 供面板单读。
- [monitor_plc_watch_storage.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/monitor/monitor_plc_watch_storage.dart)：`MonitorPlcWatchConfig` 新增 `useTcp`（默认 true，旧配置文件缺字段视为 true），随 JSON 持久化。
- [monitor_plc_watch_panel.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/monitor/widgets/monitor_plc_watch_panel.dart)：第二行工具栏加「新通讯」标签+Switch（第一行标题前放开关会遮挡标题，已按用户反馈改到第二行，与「自动刷新」同行；第二行是 Wrap，窄面板自动换行）+ 通道小字：当前页签实际走 TCP·8088（主色）/ HTTP（灰），随开关和页签切换实时变（TabController 加了 listener）；`_readEntry` 分流——D/M/S 且开关开走 `DsTcpClient`（指令码 3/1/130），X/Y 或开关关走原 HTTP；开关状态持久化。用户问过「切换后为什么监视依然正常」：预期行为，开关只改下一轮轮询通道、不清数据，且 X/Y 恒走 HTTP。

验证：`flutter analyze` 3 文件无问题；`flutter test` 40/40 通过。
追加：文件管理页底部按钮排（本地后退/程序配置/下载目录）右侧新增「安装目录」按钮（仅 Windows，样式同款 OutlinedButton），点击用 explorer.exe 打开 `RobotPaths.installRoot()`（exe 所在根目录）；用户已实测确认新 TCP·8088 协议跑通（netstat 见 flutter_application_1.exe 与机器人 192.168.1.14:8088 ESTABLISHED，日志零条 robot_get_*）。控制台 accessibility_bridge.cc AXTree 报错为 Flutter 引擎已知无障碍噪音，与本工程代码无关、无影响。
**待用户实测**：连真机后开关开=新 TCP 方式读 D/M/S 数值正常；开关关=恢复旧 HTTP；X/Y tab 两种方式下都正常；断网/机器人未开 8088 时显示「!」不卡 UI，恢复后自动续读。

### 同轮追加：文件管理页交互改进 + 日志 BOM + 安装器修复 —— 已改，部分实测通过

- 文件管理页（[files_page.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/files/files_page.dart)）：① 本地目录路径改可点击面包屑（每段可点跳层，同右侧驱控样式）；② 左右分栏中间分界线可拖拽 10%~90%（初版卡顿根因=拖动状态变量写在 LayoutBuilder 闭包内每帧重置，改实例字段解决）；③ 一键备份/恢复按钮与右侧按钮同尺寸（OutlinedButton 主样式补水平内边距）；④ 第二排新增「安装目录」「日志目录」按钮（explorer 直达；日志目录自动定位 LOCALAPPDATA 回退位置）。
- 运行日志 UTF-8 BOM（[app_logger.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/core/app_logger.dart)）：新日志文件写入 BOM，记事本不乱码；仅新建文件生效。
- 安装器修复（[installer/webview2_repair/CMakeLists.txt](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/installer/webview2_repair/CMakeLists.txt)）：客户裸机报「找不到 VCRUNTIME140_1.dll」装不了——根因 `set(CMAKE_MSVC_RUNTIME_LIBRARY)` 在 `add_executable` 之后未生效（target 已按默认 /MD 初始化）；移到前面后重新编译验证 PE 无 VC 运行库依赖，裸机可跑。
- **v2.3.0 已发布**：commit + tag v2.3.0 推送 origin（GitHub）与 gitee；GitHub Release v2.3.0（Setup.exe 311MB + msi 107MB + apk 128MB）已创建；Gitee release 本机无私人令牌（push 密码不能调 API，401）→ 正文已复制剪贴板并打开发版页，待用户手动创建并上传 `LPRobot-src-v2.3.0.zip`（90MB，源码 zip 国内直连通道，发版必传）。CHANGELOG 补 v2.3.0/v2.2.8 条目，新增 history/v2.3.0.md。
- **待用户实测**：文件管理页面包屑跳层/拖拽分栏/按钮布局/两个目录按钮；裸机安装新 Setup.exe 不再报 VCRUNTIME140_1.dll。

## 本轮结论（2026-11-19）

### Gitee 附件 = 国内下载唯一可靠通道 —— 已落地

用户实测：GitHub 直连 DNS 失败、ghproxy.cn 下载不完整、gh-proxy.com 404、ghfast.top 403——ghproxy 系镜像全挂，国内无翻墙唯一可靠下载就是 Gitee。**Gitee 网页「源码包」对本仓库 reject（pack 约 490MB），但 Release 附件不受限（上限 100MB）**：已生成并上传 `LPRobot-src-v2.2.7.zip`（90.11MB，`git archive --format=zip --prefix="Flutter_LP-v2.2.7/" -o dist\LPRobot-src-v2.2.7.zip v2.2.7`，attach_files multipart 上传），附件直链 `https://gitee.com/liomr-chen1/flutter_-lp/releases/download/v2.2.7/LPRobot-src-v2.2.7.zip`（实测 ~2MB/s）。下载脚本已改为：源码 ZIP **Gitee 附件优先 → GitHub 直连 → 镜像**；版本解析 GitHub API 超时 15s→5s；已端到端实测通过。Gitee PATCH release 中文 body 400 报错：PS5.1 `[Text.Encoding]::UTF8` 写文件带 BOM，须用 `New-Object System.Text.UTF8Encoding($false)` + curl `--data-binary @file`。发新版本必须把源码 zip 传到 Gitee 对应 release 附件（命名 `LPRobot-src-v版本号.zip`）。注意：Gitee 私人令牌已在聊天中出现，建议用户删除重建。

### 一键备份/恢复 FPGA/SDK 固件 + 机械手类型密码确认 —— 已改，待用户实测

用户需求（2026-11-19）：① 一键备份增加 `/opt/firmware/` 的 `fpga_servo.bin`、`sdk_servo.img`，一键恢复把这两个文件下发到 `/usr/appupdate/`；② 机械手类型修改页加密码确认防误改，默认密码 0000。

修改：
- [robot_file_backup.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/files/robot_file_backup.dart)：
  - 备份 `_collectBackupFiles` 固件分支追加 2 个 `/opt/firmware/` 文件（文件存在才导出，旧控制器无此文件自动跳过）；
  - 恢复 `_collectRestoreFiles` 固件分支新增 `_addFirmwareUpdateFiles`：从备份包 `opt/firmware/` 取两个文件，`LocalBackupEntry(serverTagPath: '/usr/appupdate/')` 下发到升级目录（备份包没有该目录自动跳过 = 兼容旧备份包）。
- [config_file_page.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/config_file/config_file_page.dart)：`_saveFile` 开头对 `robotTypeSelect` 步骤先弹 `_confirmRobotTypePassword()`（AlertDialog + obscureText 输入，密码 '0000'，错误留在弹窗提示重输，取消/错误均中止），通过后才走原有「是否保存该文件」确认。

验证：`flutter analyze` 两文件无问题；`flutter test` 40/40 通过。
**待用户实测**：① 新控制器一键备份压缩包含 `opt/firmware/fpga_servo.bin`、`sdk_servo.img`；恢复后两文件出现在驱控 `/usr/appupdate/`；② 机械手类型页点保存先弹密码框，输错 0000 提示「密码错误」，输对或取消后行为正确。

## 本轮结论（2026-11-17）

### v2.2.7 发布 —— 已发布 GitHub Release

- 提交 `d800b91` 已推送 origin/main；release tag `v2.2.7` 指向该提交。
- 产物（dist/ 与 release 资产一致）：`LPRobot-2.2.7-x64-Setup.exe`（296.65MB，WebView2 离线 bundle）、`LPRobot-2.2.7-x64.msi`（101.97MB）、`LPRobot-2.2.7.apk`（121.52MB，`flutter build apk --release`）。
- Release：https://github.com/cxz1010839135/Flutter_LP/releases/tag/v2.2.7（name「领鹏智能 v2.2.7」）。
- 已添加 Gitee 镜像远端 `gitee`（https://gitee.com/liomr-chen1/flutter_-lp.git，仓库为 GitHub 导入）；main + tag v2.2.7 已推送。Gitee Release「领鹏智能 v2.2.7」已建（API），正文指向 GitHub Release 下载——**Gitee 免费账户附件上限 100MB**，三个安装包均超限无法上传；**Gitee 源码包（archive/refs/tags）对本仓库（pack 约 490MB）返回 400 `reject by [gitee]` 拒绝生成，网页源码包不可用，clone 不受影响**。Gitee API 用私人令牌（`POST/PATCH /api/v5/repos/{owner}/{repo}/releases`，上传附件 attach_files）；PS5.1 构造 JSON 用 `[IO.File]::ReadAllText`，勿用 `Get-Content -Raw`（会被 ConvertTo-Json 序列化成 `{value:...}`）。
- 注意：远端曾存在 11-16 提前建的旧 release（tag 指向 4fe0d05、只有旧 Windows 资产、缺 APK），已删除后在新提交上重建。后续发版前先 `gh release view vX.Y.Z` 确认是否已存在。
- Android 打包经验：TRAE 沙箱内跑 `flutter build apk` 会因 Kotlin daemon / pub 缓存 ACL 拒绝访问失败（沙箱内创建的文件带受限 ACL，删除可以、读写被拒 errno 5）；须前台 + 沙箱外执行，失败后需清理 `~\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn\jni-*` 与 `hosted-hashes` 对应 .sha256 再 `flutter pub get`。
- 下载脚本 `下载领鹏智能源码和安装包.bat`（仓库根，已附到 GitHub Release v2.2.7）：源码 ZIP **Gitee Release 附件优先**（国内直连实测 ~2MB/s，无需翻墙）/ GitHub 直连+ghproxy 系镜像回退 / git 克隆（Gitee 优先）/ 安装包下载（安装包超 100MB 挂不上 Gitee，仍走 GitHub）。**发新版本必须把源码 zip 传到 Gitee 对应 release 附件，命名 `LPRobot-src-v版本号.zip`**（`git archive --format=zip --prefix="Flutter_LP-vX.Y.Z/" -o dist\LPRobot-src-vX.Y.Z.zip vX.Y.Z`，v2.2.7 实测 90.11MB < 100MB 上限；附件直链 `https://gitee.com/{owner}/{repo}/releases/download/v{ver}/LPRobot-src-v{ver}.zip`）。bat 必须 **GBK 编码 + CRLF 换行**（Write 工具默认 UTF-8+LF 会导致 cmd 解析错位乱执行）；菜单输入用 `%VAR:~0,1%` 取首字符比较；cmd `set /p` 在管道下会吞掉缓冲区剩余行，自动化测试只能喂第一问，交互双击不受影响。用户实测 GitHub 直连 DNS 失败、ghproxy.cn 内容不完整、gh-proxy.com 404、ghfast.top 403——所以国内源码下载唯一可靠路径就是 Gitee 附件。版本解析 GitHub API 超时已调 5s（无翻墙时最多等 5s 回退 DEFAULT_VER）。

### 一键备份适配新版程序/库名 + 排除 EtherCAT —— 已改，待用户实测

用户需求（图）：程序和库名称修改，一键备份增加导入导出（文件存在才导出导入，兼容原来版本）：`/usr/lib/librobot.so`、`/usr/lib/libplc.so`、`/usr/lib/libecat_rk.so`、`/home/ll_main`；一键备份不备份 `/home/llmachine/EtherCAT`（太大）。另：网络部分 eth1 备份——**代码里备份/恢复两侧的「IP」分类本来就有 eth1**（`ipOn` 分支），无需改；用户测不到大概率是旧 exe。

修改（仅 [robot_file_backup.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/files/robot_file_backup.dart)）：
- 备份 `_collectBackupFiles` 固件分支追加 4 个新名字（缺文件下载抛错/空字节 → 既有单文件 try/catch 与 `bytes.isEmpty` 跳过 = 没有就不备份）；
- 备份 `_collectOtherConfigFiles` 移除 `/home/llmachine/EtherCAT/`（恢复侧**保留** EtherCAT 分支：旧备份包里有的仍会恢复，新包不再包含）；
- 恢复 `_collectRestoreFiles` 固件分支追加 4 个 `addRelative`（本地无该文件自动跳过 = 兼容旧备份包）；
- `_needsExecuteBit` 加 `ll_main`（主程序需 +x，同 `ll_libot`）。

验证：`flutter analyze` 无问题；`flutter test` 40/40 通过。
**待用户实测**：新版控制器一键备份压缩包含 4 个新文件且明显变小（无 EtherCAT）；旧控制器备份不受影响；恢复新备份包后新程序/库文件到位且可执行。

### 文件管理左侧本地目录加「返回上一级」按钮 —— 已改，待用户实测

用户反馈（截图）：文件管理页右侧驱控目录有「← 根目录」返回，左侧本地目录进入子目录后没有返回按钮。

修改（仅 [files_page.dart](file:///d:/Adroid_ws/LpRobt_Flutter/Lpzn_windows/lib/features/files/files_page.dart)）：
- `_buildLocalPanel` 路径行前加 `IconButton(arrow_back)`（与右侧头部同款样式），调用既有 `_localBack()`；
- 新增 `_canLocalBack`：加载中/磁盘列表视图不可退；Windows 盘符根可退（→ 磁盘列表）；已到最顶层目录置灰。

验证：`flutter analyze` 无问题；`flutter test` 40/40 通过。
**待用户实测**：进入下载目录子文件夹后点左上角 ← 可逐级返回；到最顶层按钮置灰。

## 本轮结论（2026-11-16）

### 配置页新增「视觉程序退出」按钮 —— 已改，待用户实测

用户需求（两图）：下位机视觉软件已实现指令头 `robotExitProgram`（`HttpServer::robotExitProgram`），配置页新增按键发送该指令、「只要这个指令头就可以识别」，按键名「视觉程序退出」。

修改：
- `lib/core/robot_api_constants.dart`：`RobotCommands` 新增 `robotExitProgram`；
- `lib/network/api/robot_http_state.dart`：新增 `robotExitProgram()` —— `robotCmdRaw` + `tryParse`（下位机响应体格式未知，空/非 JSON 视为已应答，同 robotChmod 惯例；标准 JSON 才校验 result==1）；
- `lib/features/tool/tool_page.dart`：配置页右列第 7 键「视觉程序退出」，`enabled: !_busy`（与文件管理同门控，非运动指令不要求机器人静止），点击走 `_runAction` 统一提示。

验证：`flutter analyze` 3 文件无问题；`flutter test` 40/40 通过。
**待用户实测**：连接下位机后点「视觉程序退出」→ 视觉软件退出、应用提示成功。

### 文件配置向导新增 eth1 步骤 —— 已改，待用户实测

用户需求：文件配置向导（eth0 步骤之后）新增 eth1 配置；下位机没有该文件时可以创建。

修改：
- `lib/features/config_file/config_file_defs.dart`：新增步骤 index 18 `eth1-本机IP(保存后请重启驱控)`，路径 `/home/llmachine/ipaddress/eth1`，singleValue；导航顺序 `…16 → 18 → 17`；
- `lib/features/config_file/config_file_codec.dart`：`createDefaultRows` 新增 case 18，默认 IP `192.168.88.10`（用户指定，创建后可在页面改）。

说明：文件不存在时页面走既有「创建该文件」按钮（底部栏），用默认 IP 建文件，再点 IP 单元格修改、保存文件。默认留空会卡死（空文件 reload 后无行且无添加按钮），所以默认值必须非空。

验证：`flutter analyze` 无问题；`flutter test` 40/40 通过。
**待用户实测**：eth0 下一步出现「eth1-本机IP」；无文件时点「创建该文件」→ 出现 192.168.88.10 → 可改可存。

### 文件配置向导新增「机械手类型」下拉步骤（首位）—— 已改，待用户实测

用户需求：向导增加配置机械手类型（下拉选择）；型号清单来自 `/home/llmachine/Axis4/para/RobotType/RobotTypeList.rtl`（每行一个型号，用户截图确认）；选中后写 `/home/llmachine/Axis4/para/RobotType/DefaultRobotType.drt`（修改生效处）。

修改：
- `lib/features/config_file/config_file_defs.dart`：新增 `ConfigFileFormat.robotTypeSelect`、路径常量 `configRobotTypeListPath`/`configDefaultRobotTypePath`、步骤 index 19「DefaultRobotType-机械手类型(修改后请重启驱控)」置于导航首位（初始 `_stepIndex=configFileNavOrder.first`）；
- `lib/features/config_file/config_file_codec.dart`：parse/serialize 中 robotTypeSelect 与 singleValue 同语义（drt 一行 = 当前型号）；
- `lib/features/config_file/config_file_service.dart`：新增 `loadRobotTypeOptions()` 读 rtl 清单；
- `lib/features/config_file/config_file_page.dart`：机械手类型步骤渲染下拉（当前型号不在清单也保留显示）；drt 缺失/为空保底一行空值、保存时即创建文件；清单拉取失败仅警告不阻塞；选择受 `MaintenanceEditGate` 门控；保存走既有 `_saveFile`（serialize singleValue → 上传 drt）。Flutter 3.44 用 `initialValue`（`value` 已弃用），字段离开步骤即销毁重建、行为一致。

验证：`flutter analyze` 无问题；`flutter test` 40/40 通过。
**待用户实测**：打开文件配置第一页为「机械手类型」，下拉列出 rtl 全部型号；选中→保存文件→重启驱控后机器人型号切换。

## 上一轮结论（2026-11-04）

### 视觉调参交互验证 demo（独立工程，不动主工程）

用户需求收敛为：图像获取与图像处理都在另一台机器（下位机）进行，本机只负责 ① 接收图像 ② 在图像上画框（ROI）③ 把修改后的参数发给下位机 ④ 接收处理完的图像回传。通信方式用户选择「先走 HTTP/MJPEG，协议层留抽象，后续可换 TCP」；交付形式「先独立 demo」。

新增独立工程 `demo/vision_roi_demo/`（flutter create 仅 Windows，零第三方依赖）：

- `lib/mock_vision_server.dart`：模拟下位机（进程内嵌，127.0.0.1:8600）——`GET /stream` 原始图像 MJPEG 流、`GET /processed/stream` 处理结果流（叠加 ROI 描绘+模拟检测结果+回显收到的参数）、`POST /params` 接收 `{rois:[...], params:{threshold,polarity}}`。dart:ui PictureRecorder 生成 800×600 模拟帧（移动工件），10fps PNG 编码。
- `lib/mjpeg_client.dart`：MJPEG（multipart/x-mixed-replace）客户端，只用 dart:io HttpClient；字节级找 boundary + Content-Length 提帧；解码跳帧（最多保留 2 帧）防延迟堆积；断流 1.5s 自动重连。对帧格式（PNG/JPEG）无假设，真实下位机 JPEG 原样可用。
- `lib/roi_model.dart`：RoiShape（矩形/卡尺线/圆），坐标一律为图像像素坐标系，显示变换由画布层负责；toJson/fromJson。
- `lib/roi_canvas.dart`：画布——显示 MJPEG 当前帧 + ROI 覆盖层；工具模式（选择/矩形/卡尺线/圆）拖拽新建、选中拖动/端点调整；滚轮以光标为中心缩放（0.5×–8×）、空手平移；卡尺线画刻度+方向箭头；右下角缩放条。
- `lib/main.dart`：应用壳——顶栏（原始图像/处理结果切换 + 下发参数按钮）、右侧面板（工具按钮、ROI 列表带删除、阈值 Slider、极性 Switch）；`POST /params` 下发全部 ROI+参数。

**迭代 2（同日）：ROI 编辑 + 错位修复 + 参数框架（参考 LLVisionBridge）**

- ROI 画完自动切回「选择」工具并选中；右侧新增「选中 ROI 属性」编辑区（矩形/圆 X/Y/宽/高，卡尺线 X1/Y1/X2/Y2，双向同步）+「取数步骤 target_step_name」输入。
- 修复 ROI 与图像错位：`_RoiPainter` 原把图像像素坐标直接当显示坐标画，漏乘帧显示的 fit 缩放（下位机回显的绿框跟着图像缩放、本机黄框不缩放）；painter 加 `canvas.scale(fit)` 与帧同缩放后黄绿重合。
- **参数框架对齐参考项目 `D:\有加视觉\LLVisionBridge_固定Z偏移\LLVisionBridge`**（Explore 调研结论：该项目不实现检测算法，参数体系=每料号一份 params.json 扁平可扩展键值表，Z/角度三态槽 + fail-loud 校验）：新增 `lib/vision_params.dart`，键名与 `PartParameters.cs` 一致（z_mode/z_reference_v/z_mm_per_pixel/z_fixed_offset_mm/z_random_range_mm/z_value_index/z_direction、roll_* 对称一组、note、未知键进 extra 原样保留）；`validate()` fail-loud（measured 须参考v≥0 且像素比>0 否则 `z_calib_invalid`，方向只收 ±1，random 须范围>0，|增益|<门 ⇒ `roll_uncontrollable`）。右侧面板改分组：检测（阈值/极性）+「Z 偏移槽」/「角度槽」ExpansionTile（关/随机/实测三态 SegmentedButton，按模式显示字段）+ 备注；下发前先校验，失败显示错误码不下发。mock server `POST /params` 独立复用 `VisionParams.fromJson().validate()`（非法返回 422+code），处理结果流回显 z_mode/实时模拟 dz（measured 用工件位置当检测 v）、roll 参数。
- 验证：analyze 干净、test 3/3、build+启动成功；**待用户实测**：分组面板手感、measured 模式 dz 随工件移动变化、校验拦截（如实测模式不填参考像素点下发）。

**迭代 3（同日）：修复「只能编辑第一个 ROI」**

- 根因：画布新建 ROI 的草稿 id 固定为 `'draft'`，`_onCreate` 未换 id 直接入库 → 所有 ROI 同 id，画布 `_find` 与属性区 `firstWhere` 永远命中列表第一个（拖第二个框动的是第一个框、属性编辑永远改第一个）。
- 修复：`_onCreate` 为每个新 ROI 生成唯一自增 id（`roi_1`/`roi_2`…）；选中逻辑收敛到 `_selectRoi`（画布点击与列表点击共用），切换选中时让属性输入框失焦，显示值才同步到新选中的 ROI。
- 验证：analyze 无问题、test 3/3、build+启动成功；**待用户实测**：画多个 ROI，点击/拖拽/拉端点/属性编辑均作用于各自 ROI。

**迭代 4（同日）：底部「编程流程」节点栏（对齐用户提供的参考软件截图）**

- 用户给出参考软件（微视 V2026.07.30）截图：底部节点链「图像采集 → 查找定位 → 计算1 → 计算2 …」，指明编程流程就按这种做。
- demo 底部新增 `_buildFlowBar`：固定「图像采集」「查找定位」占位节点 + 每个 ROI 一个检测节点（图标按矩形/卡尺线/圆，节点名取 `target_step_name`，缺省「计算N」），箭头串联、可横向滚动；点节点 = 选中对应 ROI（与画布/列表联动高亮）。步骤名输入实时刷新节点名。
- 验证：analyze 无问题、test 3/3、build+启动成功；**待用户实测**：流程节点栏布局与点选联动手感、节点命名是否符合预期。

验证：`flutter analyze` 无问题；`flutter test` 3/3 通过（RoiShape 序列化/命中）；`flutter build windows --debug` 成功并启动。**待用户实测**：图像流显示、ROI 绘制/编辑手感、下发参数后处理结果流的模拟检测回显是否符合预期。

demo 验证通过后可整体删除，方案再合入主工程视觉首页（对应遗留项「视觉首页主体内容与视觉专属编程界面」）。

## 本轮结论（2026-11-03）

### 新增《项目速览.md》—— 交接文档

应用户要求在工程根新增 `项目速览.md`：接手必读顺序、环境与常用命令、完整项目结构目录树（含 lib/ 各模块关键文件职责）、核心红线约定、打包与发布流程（含 v2.2.6 提交筛选实操经验）、每轮收尾闭环、当前状态速记。纯文档，无代码改动。

## 上一轮结论（2026-10-30）

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
