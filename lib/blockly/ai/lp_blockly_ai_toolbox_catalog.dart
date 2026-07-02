/// 领鹏 Blockly 四分类工具箱完整说明（来自 demos/code/index.html + blocks/*.js）。
///
/// UI 分类：逻辑 | 变量 | 运动 | 自定义
abstract final class LpBlocklyAiToolboxCatalog {
  static const int maxChars = 14000;

  static String buildFullSection() {
    const text = '''
## 工具箱四分类（仅可使用下列块）

### 逻辑（controls 类）
| 块 type | 说明 | 齿轮(mutator) | 下拉/槽位 |
|---------|------|---------------|-----------|
| controls_if | 如果…执行 | **仅「否则执行」**，**无「否则如果」**；不要写 mutation elseif | IF0=条件 value；DO0=执行 statement；可选 else=1 + ELSE statement |
| logic_operation_m_vertical | 和/或（竖向，推荐） | logic_op_item：追加条件槽 | OP=AND/OR；2条件：items=1，A+ADD0；3条件：items=2，A+ADD0+ADD1 |
| logic_operation_m | 和/或（横向） | 同上 | 优先用 vertical |
| logic_compare | 比较 | 无 | OP=EQ/NEQ/LT/LTE/GT/GTE；A/B 为 value |

### 变量（math/thread 类）
| 块 type | 说明 | 齿轮 | 下拉/槽位 |
|---------|------|------|-----------|
| math_variable | 赋值 D400=1 | 无 | Variable_Name: D/V/I/J/K/W/X/Y/M/S/T/C/Px/Py/Pz/Pw/U1-U4；Variable_Idx；Variable_Value |
| math_arithmetic | 四则运算 | 无 | OP=ADD/SUBTRACT/MULTIPLY/DIVIDE/POWER |
| thread_get_bitX | 读 X 位 | 无 | ACTIVE_Data: X/XUP/XDN/XOFF；Idx |
| thread_get_bitY | 读 Y 位 | 无 | ACTIVE_Data: Y/YUP/YDN/YOFF；Idx |
| thread_get_bitM | 读 M 位 | 无 | ACTIVE_Data: M/MUP/MDN/MOFF；Idx |
| thread_get_bitS | 读 S 位 | 无 | ACTIVE_Data: S/SUP/SDN/SOFF；Idx |
| thread_get_bitT | 读 T 位 | 无 | ACTIVE_Data: T/TOFF/TUP/TDN；Idx |
| thread_get_bitC | 读 C 位 | 无 | ACTIVE_Data: C/COFF/CUP/CDN；Idx |
| thread_get_data | 读寄存器数值 | 无 | ACTIVE_Data: D/V/I/J/K/W/Px/Py/Pz/Pw/U1-U4/#；Idx |
| math_number | 数字常量 | 无 | NUM |
| math_constant | 数学常量 | 无 | CONSTANT=PI/E/GOLDEN_RATIO/SQRT2/INFINITY |
| math_variableNotes | 注释 | 无 | 无输入 |

### 运动（motion 类）
| 块 type | 说明 | 齿轮可加入项 | 下拉/槽位 |
|---------|------|-------------|-----------|
| motion_moveptp_point | 门型/点到点 | **条件**×N、**IO输出**、**偏移**、**航偏**、**避障列表**、**绝对模式** | MotionMode: DoorFree(自由门型)/DoorLine/DoorDynamic/MoveLine；条件齿轮每项 OP：AvoidPoint(P)/HeightAvoid(避障高度)/MaxSpeed(最大速度)/EndSpeed(终点速度)；标准3参数：para=3，OP0/1/2 如上；偏移 mutation offset=1 → OFFSET/YValue/ZValue/WValue |
| motion_move_go | 独立定位 G0 | 轴运动、点动开始、点动停止、绝对模式、回零模式 | mutator: axis/s_jog/t_jog/absmode/zeromode |
| motion_ele_mode | 电子齿轮 | 无 | idxSelect/idxFollow/molecule/denominator |
| batch | 批量赋值 | 无 | batch_name: batch_D/batch_M/batch_S；batch_index/batch_num/batch_value |

### 自定义（函数）
| 块 type | 说明 |
|---------|------|
| procedures_defnoreturn | 定义无返回值函数（工具箱 PROCEDURE 自定义） |
| procedures_callnoreturn | 调用函数 |

## 关键约束（必须遵守）
1. controls_if：**禁止** mutation elseif、禁止 IF1/DO1（否则如果）；默认仅 IF0+DO0
2. controls_if 齿轮 UI **没有**「否则如果」，只有「否则执行」；除非用户明确要求 else，否则不要 mutation else
3. 门型 motion_moveptp_point：3 参数时 OP 必须为 AvoidPoint+HeightAvoid+MaxSpeed，不可全写 AvoidPoint
4. 复合条件用 logic_operation_m_vertical，items=条件数-1，第一个条件放 A
''';
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}\n<!-- toolbox catalog truncated -->';
  }
}
