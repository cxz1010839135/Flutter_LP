import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mock_vision_server.dart';
import 'mjpeg_client.dart';
import 'roi_canvas.dart';
import 'roi_model.dart';
import 'vision_params.dart';

void main() {
  runApp(const VisionDemoApp());
}

/// 视觉调参 Demo：
/// 本机 = 视觉调参工作站。图像获取与处理在“下位机”（demo 内嵌 MockVisionServer
/// 模拟，127.0.0.1:8600），本机只负责：收图 → 画 ROI → 下发参数 → 收处理结果图。
class VisionDemoApp extends StatelessWidget {
  const VisionDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '视觉调参 Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF22C55E),
          surface: Color(0xFF141519),
        ),
        scaffoldBackgroundColor: const Color(0xFF141519),
        fontFamily: 'Microsoft YaHei UI',
      ),
      home: const VisionDemoPage(),
    );
  }
}

class VisionDemoPage extends StatefulWidget {
  const VisionDemoPage({super.key});

  @override
  State<VisionDemoPage> createState() => _VisionDemoPageState();
}

class _VisionDemoPageState extends State<VisionDemoPage> {
  final MockVisionServer _server = MockVisionServer();
  MjpegStream? _raw;
  MjpegStream? _processed;

  // 画布当前显示哪一路流：原始 / 处理结果
  bool _showProcessed = true;

  // ROI 与参数（本机为“源头”，下发到下位机）
  final List<RoiShape> _rois = <RoiShape>[];
  String? _selectedId;
  ToolMode _mode = ToolMode.select;
  int _roiSeq = 0; // ROI 自增序号：画布草稿 id 固定为 'draft'，入库前必须换成唯一 id

  /// 处理参数表（键名对齐 LLVisionBridge params.json）
  final VisionParams _vp = VisionParams();

  String _status = '启动中…';
  bool _sending = false;

  // 选中 ROI 属性编辑（几何字段输入框）
  final Map<String, TextEditingController> _propCtl = <String, TextEditingController>{};
  final Map<String, FocusNode> _propNodes = <String, FocusNode>{};
  bool get _propEditing => _propNodes.values.any((n) => n.hasFocus);

  // 参数面板输入框
  final TextEditingController _noteCtl = TextEditingController();
  final TextEditingController _stepCtl = TextEditingController();
  String? _stepTarget; // 取数步骤输入框当前对应的 ROI id

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      await _server.start(port: 8600);
      final base = 'http://127.0.0.1:${_server.port}';
      _raw = MjpegStream('$base/stream', name: '原始')
        ..start();
      _processed = MjpegStream('$base/processed/stream', name: '结果')
        ..start();
      setState(() => _status = '已连接模拟下位机 127.0.0.1:${_server.port}');
    } catch (e) {
      setState(() => _status = '模拟下位机启动失败：$e');
    }
  }

  @override
  void dispose() {
    _raw?.stop();
    _processed?.stop();
    _server.stop();
    for (final c in _propCtl.values) {
      c.dispose();
    }
    for (final n in _propNodes.values) {
      n.dispose();
    }
    _noteCtl.dispose();
    _stepCtl.dispose();
    super.dispose();
  }

  MjpegStream get _current => (_showProcessed ? _processed : _raw)!;

  // ---- ROI 操作 --------------------------------------------------------

  void _onCreate(RoiShape r) {
    // 矩形/圆规范化为左上→右下，属性编辑区才能按 X/Y/宽/高 双向读写
    if (r.type != RoiType.line) {
      final b = Rect.fromPoints(r.p1, r.p2);
      r.p1 = b.topLeft;
      r.p2 = b.bottomRight;
    }
    // 画布草稿 id 固定为 'draft'，入库必须换成唯一 id，
    // 否则所有 ROI 同 id：拖拽/属性编辑永远落在列表第一个上
    final roi = RoiShape(
      id: 'roi_${++_roiSeq}',
      type: r.type,
      p1: r.p1,
      p2: r.p2,
      params: r.params,
    );
    // 画完自动切回选择工具并选中，立即可拖动/拉端点/编辑属性
    setState(() {
      _rois.add(roi);
      _selectedId = roi.id;
      _mode = ToolMode.select;
    });
  }

  /// 选中 ROI（画布点击 / 列表点击共用）：切换选中并让属性输入框失焦，
  /// 否则输入框保持焦点时显示值不会同步到新选中的 ROI
  void _selectRoi(String? id) {
    setState(() {
      _selectedId = id;
      _mode = ToolMode.select;
      for (final n in _propNodes.values) {
        n.unfocus();
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _rois.removeWhere((r) => r.id == _selectedId);
      _selectedId = null;
    });
  }

  // ---- 参数下发 --------------------------------------------------------

  Future<void> _sendParams() async {
    if (_sending) return;
    // fail-loud：校验不通过就不下发（沿袭参考项目，绝不带病下发）
    final errs = _vp.validate();
    if (errs.isNotEmpty) {
      setState(() => _status = '校验失败未下发：${errs.join(', ')}');
      return;
    }
    setState(() {
      _sending = true;
      _status = '下发参数中…';
    });
    try {
      final client = HttpClient();
      final req = await client.openUrl(
        'POST',
        Uri.parse('http://127.0.0.1:${_server.port}/params'),
      );
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(<String, dynamic>{
        'rois': _rois.map((r) => r.toJson()).toList(),
        'params': _vp.toJson(),
      }));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();
      if (res.statusCode == 200) {
        setState(() => _status = '参数已下发 OK（${_rois.length} 个 ROI）');
      } else {
        setState(() => _status = '下发失败：HTTP ${res.statusCode} $body');
      }
    } catch (e) {
      setState(() => _status = '下发失败：$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---- UI --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _raw == null || _processed == null
                      ? const Center(child: Text('…'))
                      : VisionCanvas(
                          stream: _current,
                          rois: _rois,
                          selectedId: _selectedId,
                          mode: _mode,
                          onSelect: _selectRoi,
                          onCreate: _onCreate,
                          onUpdate: (_) {},
                        ),
                ),
                _buildSidePanel(),
              ],
            ),
          ),
          _buildFlowBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Text(
            '视觉调参 Demo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Text(
            _status,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('原始图像')),
              ButtonSegment(value: true, label: Text('处理结果')),
            ],
            selected: {_showProcessed},
            onSelectionChanged: (s) => setState(() => _showProcessed = s.first),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _sendParams,
            icon: _sending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload, size: 16),
            label: const Text('下发参数'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF191B20),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('工具',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 8),
          Row(
            children: [
              _toolBtn(ToolMode.select, Icons.near_me, '选择'),
              _toolBtn(ToolMode.rect, Icons.crop_free, '矩形'),
              _toolBtn(ToolMode.line, Icons.straighten, '卡尺线'),
              _toolBtn(ToolMode.ellipse, Icons.circle_outlined, '圆'),
            ].map((w) => Expanded(child: w)).toList(),
          ),
          const SizedBox(height: 16),
          const Text('ROI 列表',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 4),
          if (_rois.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '无 ROI。选工具后在图像上拖拽新建。',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          for (final r in _rois) _roiTile(r),
          // 选中 ROI 的几何属性编辑
          if (_rois.any((r) => r.id == _selectedId)) ...[
            _buildPropEditor(_rois.firstWhere((r) => r.id == _selectedId)),
          ],
          const Divider(color: Colors.white12),
          const Text('处理参数 · params.json',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
          // ---- 检测 ----
          Row(
            children: [
              const Text('阈值', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _vp.threshold,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: '${_vp.threshold.round()}',
                  onChanged: (v) => setState(() => _vp.threshold = v),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text('${_vp.threshold.round()}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF22C55E))),
              ),
            ],
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('极性：暗目标', style: TextStyle(fontSize: 13)),
            subtitle: Text(
              'polarity = ${_vp.polarity}',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
            value: _vp.polarity == 'dark',
            onChanged: (v) => setState(() => _vp.polarity = v ? 'dark' : 'light'),
          ),
          // ---- Z 偏移槽 ----
          _buildZGroup(),
          // ---- 角度槽 ----
          _buildRollGroup(),
          // ---- 备注 ----
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _noteCtl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                labelText: '备注 note',
                border: OutlineInputBorder(),
              ),
              onChanged: (t) => _vp.note = t,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _selectedId == null ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('删除选中 ROI'),
          ),
        ],
      ),
    );
  }

  /// 底部编程流程栏：图像采集 → 查找定位 → 每个 ROI 一个检测步骤节点，
  /// 点节点选中对应 ROI（对齐参考软件的节点式编程流程）
  Widget _buildFlowBar() {
    Widget node({
      required IconData icon,
      required String label,
      required bool selected,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                : const Color(0xFF1D1F24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF22C55E) : Colors.white24,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 26,
                  color: selected
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.7)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? const Color(0xFF22C55E)
                        : Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      );
    }

    Widget arrow() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.east, size: 16, color: Colors.white24),
        );

    final children = <Widget>[
      node(icon: Icons.photo_camera_outlined, label: '图像采集', selected: false),
      arrow(),
      node(icon: Icons.center_focus_weak, label: '查找定位', selected: false),
    ];
    for (int i = 0; i < _rois.length; i++) {
      final r = _rois[i];
      final step = (r.params['target_step_name'] as String?) ?? '';
      children
        ..add(arrow())
        ..add(node(
          icon: switch (r.type) {
            RoiType.rect => Icons.crop_free,
            RoiType.line => Icons.straighten,
            RoiType.ellipse => Icons.circle_outlined,
          },
          label: step.isNotEmpty ? step : '计算${i + 1}',
          selected: r.id == _selectedId,
          onTap: () => _selectRoi(r.id),
        ));
    }

    return Container(
      height: 96,
      decoration: const BoxDecoration(
        color: Color(0xFF191B20),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: SizedBox(
              width: 60,
              child: Text('编程流程',
                  style: TextStyle(fontSize: 12, color: Colors.white38)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(ToolMode m, IconData icon, String label) {
    final sel = _mode == m;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => setState(() => _mode = m),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF22C55E).withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? const Color(0xFF22C55E) : Colors.white24,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: sel
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.6)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: sel
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 选中 ROI 属性编辑 ------------------------------------------------

  /// build 时同步输入框显示值；正在输入的字段不覆盖
  void _syncPropControllers(RoiShape sel) {
    final Map<String, double> vals;
    if (sel.type == RoiType.line) {
      vals = <String, double>{
        'x1': sel.p1.dx,
        'y1': sel.p1.dy,
        'x2': sel.p2.dx,
        'y2': sel.p2.dy,
      };
    } else {
      final b = sel.bounds;
      vals = <String, double>{
        'x': b.left,
        'y': b.top,
        'w': b.width,
        'h': b.height,
      };
    }
    for (final e in vals.entries) {
      final c = _propCtl.putIfAbsent(e.key, TextEditingController.new);
      final s = e.value.round().toString();
      if (c.text != s && !_propEditing) c.text = s;
    }
  }

  /// 输入框写回 ROI（图像像素坐标），画布即时重绘
  void _applyProp(RoiShape sel, String key, String text) {
    final v = double.tryParse(text);
    if (v == null) return;
    setState(() {
      if (sel.type == RoiType.line) {
        switch (key) {
          case 'x1':
            sel.p1 = Offset(v, sel.p1.dy);
          case 'y1':
            sel.p1 = Offset(sel.p1.dx, v);
          case 'x2':
            sel.p2 = Offset(v, sel.p2.dy);
          case 'y2':
            sel.p2 = Offset(sel.p2.dx, v);
        }
      } else {
        final b = sel.bounds;
        switch (key) {
          case 'x':
            sel.p1 = Offset(v, b.top);
            sel.p2 = Offset(b.right, b.bottom);
          case 'y':
            sel.p1 = Offset(b.left, v);
            sel.p2 = Offset(b.right, b.bottom);
          case 'w':
            sel.p2 = Offset(b.left + math.max(1, v), b.bottom);
          case 'h':
            sel.p2 = Offset(b.right, b.top + math.max(1, v));
        }
      }
    });
  }

  Widget _buildPropEditor(RoiShape sel) {
    _syncPropControllers(sel);
    // 取数步骤输入框：换选中对象时刷新内容（一个检测框对应一个取数步骤）
    if (_stepTarget != sel.id) {
      _stepTarget = sel.id;
      _stepCtl.text = (sel.params['target_step_name'] as String?) ?? '';
    }
    final fields = sel.type == RoiType.line
        ? const [('x1', 'X1'), ('y1', 'Y1'), ('x2', 'X2'), ('y2', 'Y2')]
        : const [('x', 'X'), ('y', 'Y'), ('w', '宽'), ('h', '高')];
    final typeLabel = switch (sel.type) {
      RoiType.rect => '矩形',
      RoiType.line => '卡尺线',
      RoiType.ellipse => '圆',
    };
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('选中 ROI · $typeLabel',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF22C55E))),
              const Spacer(),
              IconButton(
                tooltip: '删除此 ROI',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: _deleteSelected,
              ),
            ],
          ),
          for (final (key, label) in fields)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(label,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _propCtl[key],
                      focusNode:
                          _propNodes.putIfAbsent(key, FocusNode.new),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[-0-9.]')),
                      ],
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (t) => _applyProp(sel, key, t),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(
                width: 32,
                child: Text('步骤', style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: TextField(
                  controller: _stepCtl,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '取数步骤 target_step_name',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (t) =>
                      setState(() => sel.params['target_step_name'] = t),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 参数分组面板 ------------------------------------------------------

  /// Z 偏移槽（键名对齐 LLVisionBridge：z_mode / z_fixed_offset_mm / …）
  Widget _buildZGroup() {
    final on = _vp.zMode != 'off';
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Z 偏移槽 · ${_vp.zMode}',
          style: TextStyle(
              fontSize: 13, color: on ? const Color(0xFF22C55E) : null)),
      subtitle: Text(
        switch (_vp.zMode) {
          'measured' => 'dz = 方向×(参考v−检测v)×像素比 + 固定偏移',
          'random' => '随机偏移 ±${_vp.zRandomRangeMm}mm',
          _ => '未启用',
        },
        style: const TextStyle(fontSize: 11, color: Colors.white38),
      ),
      children: [
        _modeSeg(_vp.zMode, (m) => setState(() => _vp.zMode = m)),
        if (_vp.zMode == 'measured') ...[
          _NumField(
              label: '参考像素 v',
              value: _vp.zReferenceV,
              onChanged: (v) => setState(() => _vp.zReferenceV = v)),
          _NumField(
              label: '像素比 mm/px',
              value: _vp.zMmPerPixel,
              onChanged: (v) => setState(() => _vp.zMmPerPixel = v)),
        ],
        if (_vp.zMode == 'random') ...[
          _NumField(
              label: '随机上限 mm',
              value: _vp.zRandomRangeMm,
              onChanged: (v) => setState(() => _vp.zRandomRangeMm = v)),
          _NumField(
              label: '随机种子',
              value: _vp.zRandomSeed.toDouble(),
              onChanged: (v) => setState(() => _vp.zRandomSeed = v.round())),
        ],
        _NumField(
            label: '固定偏移 mm',
            value: _vp.zFixedOffsetMm,
            onChanged: (v) => setState(() => _vp.zFixedOffsetMm = v)),
        _dirRow('方向', _vp.zDirection,
            (d) => setState(() => _vp.zDirection = d)),
        _NumField(
            label: '值下标',
            value: _vp.zValueIndex.toDouble(),
            onChanged: (v) => setState(() => _vp.zValueIndex = v.round())),
      ],
    );
  }

  /// 角度槽（roll_mode / roll_reference_theta / roll_gain_deg_per_deg / …）
  Widget _buildRollGroup() {
    final on = _vp.rollMode != 'off';
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('角度槽 · ${_vp.rollMode}',
          style: TextStyle(
              fontSize: 13, color: on ? const Color(0xFF22C55E) : null)),
      subtitle: Text(
        switch (_vp.rollMode) {
          'measured' => 'dθ = 方向×增益×(检测θ−参考θ)，容差 ${_vp.rollTolDeg}° 内回 0',
          'random' => '随机角度 ±${_vp.rollRandomRangeDeg}°',
          _ => '未启用',
        },
        style: const TextStyle(fontSize: 11, color: Colors.white38),
      ),
      children: [
        _modeSeg(_vp.rollMode, (m) => setState(() => _vp.rollMode = m)),
        if (_vp.rollMode == 'measured') ...[
          _NumField(
              label: '参考角度 °',
              value: _vp.rollReferenceTheta ?? 0,
              onChanged: (v) => setState(() => _vp.rollReferenceTheta = v)),
          _NumField(
              label: '增益 °/°',
              value: _vp.rollGainDegPerDeg,
              onChanged: (v) => setState(() => _vp.rollGainDegPerDeg = v)),
          _NumField(
              label: '容差 °',
              value: _vp.rollTolDeg,
              onChanged: (v) => setState(() => _vp.rollTolDeg = v)),
        ],
        if (_vp.rollMode == 'random')
          _NumField(
              label: '随机上限 °',
              value: _vp.rollRandomRangeDeg,
              onChanged: (v) => setState(() => _vp.rollRandomRangeDeg = v)),
        _dirRow('方向', _vp.rollDirection,
            (d) => setState(() => _vp.rollDirection = d)),
      ],
    );
  }

  Widget _modeSeg(String mode, ValueChanged<String> on) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
              value: 'off',
              label: Text('关', style: TextStyle(fontSize: 12))),
          ButtonSegment(
              value: 'random',
              label: Text('随机', style: TextStyle(fontSize: 12))),
          ButtonSegment(
              value: 'measured',
              label: Text('实测', style: TextStyle(fontSize: 12))),
        ],
        selected: {mode},
        onSelectionChanged: (s) => on(s.first),
      ),
    );
  }

  Widget _dirRow(String label, int dir, ValueChanged<int> on) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 88,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          ToggleButtons(
            isSelected: [dir == 1, dir == -1],
            borderRadius: BorderRadius.circular(6),
            constraints: const BoxConstraints(minHeight: 30, minWidth: 44),
            onPressed: (i) => on(i == 0 ? 1 : -1),
            children: const [
              Text('+1', style: TextStyle(fontSize: 12)),
              Text('-1', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roiTile(RoiShape r) {
    final sel = r.id == _selectedId;
    final label = switch (r.type) {
      RoiType.rect =>
        '矩形 (${r.bounds.left.round()},${r.bounds.top.round()}) ${r.bounds.width.round()}×${r.bounds.height.round()}',
      RoiType.line =>
        '卡尺线 (${r.p1.dx.round()},${r.p1.dy.round()})→(${r.p2.dx.round()},${r.p2.dy.round()})',
      RoiType.ellipse =>
        '圆 (${r.bounds.left.round()},${r.bounds.top.round()}) D${r.bounds.width.round()}',
    };
    return ListTile(
      dense: true,
      selected: sel,
      selectedTileColor: const Color(0xFF22C55E).withValues(alpha: 0.12),
      onTap: () => _selectRoi(r.id),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => setState(() {
          _rois.remove(r);
          if (_selectedId == r.id) _selectedId = null;
        }),
      ),
    );
  }
}

/// 参数数值输入行：label + 数字输入（失焦/外部变化时同步显示）
class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _ctl =
      TextEditingController(text: _fmt(widget.value));

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void didUpdateWidget(covariant _NumField old) {
    super.didUpdateWidget(old);
    final parsed = double.tryParse(_ctl.text);
    if (parsed == null || parsed != widget.value) {
      _ctl.text = _fmt(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 88,
              child: Text(widget.label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: TextField(
              controller: _ctl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
              onChanged: (t) {
                final v = double.tryParse(t);
                if (v != null) widget.onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }
}
