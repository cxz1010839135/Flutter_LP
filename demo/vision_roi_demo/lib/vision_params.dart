/// 视觉处理参数表 —— 键名与 LLVisionBridge `PartParameters`（params.json）对齐。
///
/// 沿袭参考项目的设计原则：
/// - 扁平可扩展键值表：未知键原样保留（往返不丢），便于以后加厂商自定义键
/// - 三态模式 + 非法值 fail-loud：`validate()` 返回错误码列表，绝不静默回 0
/// - 单位约定：内部 mm / 度；如通信层需要 m / 弧度，由单一出口换算
class VisionParams {
  VisionParams();

  // ---- 检测 ----
  double threshold = 128;
  String polarity = 'light'; // light | dark

  // ---- Z 偏移槽（参考项目核心概念）----
  // dz(mm) = z_direction × (z_reference_v − 检测v) × z_mm_per_pixel + z_fixed_offset_mm
  String zMode = 'off'; // off | random | measured
  double zReferenceV = -1; // 参考像素 v（measured 时须 ≥0，-1=未设）
  double zMmPerPixel = 0; // mm/px（measured 时须 >0）
  double zFixedOffsetMm = 0; // 固定 Z 偏移 mm（可负，0=不加）
  double zRandomRangeMm = 0; // random 模式须 >0
  int zRandomSeed = -1; // -1=进程随机
  int zValueIndex = 0; // 取检测返回数组第 N 个
  int zDirection = 1; // 只接受 ±1

  // ---- 角度槽（与 Z 槽对称）----
  String rollMode = 'off'; // off | random | measured
  double? rollReferenceTheta; // 参考边角度（度，null=未设，0 合法）
  double rollGainDegPerDeg = 1.0; // 增益 °/°（≠0）
  double rollTolDeg = 3.0; // 容差（>0，容差内回 0）
  double rollGainMin = 0.15; // 不可控门（>0，|k|<门 ⇒ 不可控）
  double rollRandomRangeDeg = 0;
  int rollRandomSeed = -1;
  int rollThetaIndex = 0;
  int rollDirection = 1; // 只接受 ±1

  // ---- 其它 ----
  String note = '';

  /// 未知键（厂商/未来扩展），下发时原样带回
  final Map<String, dynamic> extra = <String, dynamic>{};

  static const _knownKeys = <String>{
    'threshold', 'polarity',
    'z_mode', 'z_reference_v', 'z_mm_per_pixel', 'z_fixed_offset_mm',
    'z_random_range_mm', 'z_random_seed', 'z_value_index', 'z_direction',
    'roll_mode', 'roll_reference_theta', 'roll_gain_deg_per_deg',
    'roll_tol_deg', 'roll_gain_min', 'roll_random_range_deg',
    'roll_random_seed', 'roll_theta_index', 'roll_direction',
    'note',
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'threshold': threshold.round(),
        'polarity': polarity,
        'z_mode': zMode,
        'z_reference_v': zReferenceV,
        'z_mm_per_pixel': zMmPerPixel,
        'z_fixed_offset_mm': zFixedOffsetMm,
        'z_random_range_mm': zRandomRangeMm,
        'z_random_seed': zRandomSeed,
        'z_value_index': zValueIndex,
        'z_direction': zDirection,
        'roll_mode': rollMode,
        if (rollReferenceTheta != null)
          'roll_reference_theta': rollReferenceTheta,
        'roll_gain_deg_per_deg': rollGainDegPerDeg,
        'roll_tol_deg': rollTolDeg,
        'roll_gain_min': rollGainMin,
        'roll_random_range_deg': rollRandomRangeDeg,
        'roll_random_seed': rollRandomSeed,
        'roll_theta_index': rollThetaIndex,
        'roll_direction': rollDirection,
        'note': note,
        ...extra,
      };

  factory VisionParams.fromJson(Map<String, dynamic> j) {
    final p = VisionParams();
    double? d(Object? v) => v is num ? v.toDouble() : null;
    int? i(Object? v) => v is num ? v.toInt() : null;

    p.threshold = d(j['threshold']) ?? p.threshold;
    p.polarity = j['polarity'] as String? ?? p.polarity;

    p.zMode = j['z_mode'] as String? ?? p.zMode;
    p.zReferenceV = d(j['z_reference_v']) ?? p.zReferenceV;
    p.zMmPerPixel = d(j['z_mm_per_pixel']) ?? p.zMmPerPixel;
    p.zFixedOffsetMm = d(j['z_fixed_offset_mm']) ?? p.zFixedOffsetMm;
    p.zRandomRangeMm = d(j['z_random_range_mm']) ?? p.zRandomRangeMm;
    p.zRandomSeed = i(j['z_random_seed']) ?? p.zRandomSeed;
    p.zValueIndex = i(j['z_value_index']) ?? p.zValueIndex;
    p.zDirection = i(j['z_direction']) ?? p.zDirection;

    p.rollMode = j['roll_mode'] as String? ?? p.rollMode;
    p.rollReferenceTheta = d(j['roll_reference_theta']);
    p.rollGainDegPerDeg = d(j['roll_gain_deg_per_deg']) ?? p.rollGainDegPerDeg;
    p.rollTolDeg = d(j['roll_tol_deg']) ?? p.rollTolDeg;
    p.rollGainMin = d(j['roll_gain_min']) ?? p.rollGainMin;
    p.rollRandomRangeDeg = d(j['roll_random_range_deg']) ?? p.rollRandomRangeDeg;
    p.rollRandomSeed = i(j['roll_random_seed']) ?? p.rollRandomSeed;
    p.rollThetaIndex = i(j['roll_theta_index']) ?? p.rollThetaIndex;
    p.rollDirection = i(j['roll_direction']) ?? p.rollDirection;

    p.note = j['note'] as String? ?? p.note;

    for (final e in j.entries) {
      if (!_knownKeys.contains(e.key)) p.extra[e.key] = e.value;
    }
    return p;
  }

  /// fail-loud 校验：返回错误码列表（空 = 合法）。
  /// 错误码命名沿袭参考项目（z_calib_invalid / offset_frame_conflict 等）。
  List<String> validate() {
    final errs = <String>[];
    const modes = {'off', 'random', 'measured'};

    if (!modes.contains(zMode)) errs.add('z_mode_invalid');
    if (zDirection != 1 && zDirection != -1) errs.add('z_direction_invalid');
    if (zMode == 'measured') {
      // 参考像素未设或像素比非正 ⇒ 标定无效，拒绝下发（绝不静默回 0）
      if (!(zReferenceV >= 0) || !(zMmPerPixel > 0)) errs.add('z_calib_invalid');
    }
    if (zMode == 'random' && !(zRandomRangeMm > 0)) {
      errs.add('z_random_range_invalid');
    }
    if (zValueIndex < 0) errs.add('z_value_index_invalid');

    if (!modes.contains(rollMode)) errs.add('roll_mode_invalid');
    if (rollDirection != 1 && rollDirection != -1) {
      errs.add('roll_direction_invalid');
    }
    if (rollMode == 'measured') {
      if (rollReferenceTheta == null) errs.add('roll_reference_missing');
      if (rollGainDegPerDeg == 0) errs.add('roll_gain_invalid');
      if (rollGainDegPerDeg.abs() < rollGainMin) errs.add('roll_uncontrollable');
    }
    if (rollMode == 'random' && !(rollRandomRangeDeg > 0)) {
      errs.add('roll_random_range_invalid');
    }
    if (rollThetaIndex < 0) errs.add('roll_theta_index_invalid');

    return errs;
  }
}
