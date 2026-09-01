import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';
import 'driver_adaptive_value_field.dart';
import 'driver_canshu_section.dart';

class DriverTabChip extends StatelessWidget {
  const DriverTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFE0C2)
          : LpRobotColors.primary.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DriverUiStyle.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? LpRobotColors.primary : Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DriverParamField extends StatelessWidget {
  const DriverParamField({
    super.key,
    required this.def,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final DriverFieldDef def;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  void _showHelp(BuildContext context) {
    final help = DriverParamsDefs.helpOf(def.key);
    if (help == null || help.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(def.label),
        content: Text(help),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 行内标签略收，输入框更宽；在 1280 下加高行高。
        final labelW =
            (constraints.maxWidth * 0.58).clamp(40.0, constraints.maxWidth * 0.66);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelW,
                child: InkWell(
                  onTap: () => _showHelp(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        def.label,
                        maxLines: 2,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: DriverUiStyle.labelStyle.copyWith(
                          fontSize: 13,
                          height: 1.15,
                          color: LpRobotColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: DriverAdaptiveValueField(
                    value: value,
                    enabled: enabled,
                    onChanged: onChanged,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 将字段按奇偶分到左右两列（对齐目标图双列排布）。
List<List<DriverFieldDef>> _splitDualColumns(List<DriverFieldDef> fields) {
  final left = <DriverFieldDef>[];
  final right = <DriverFieldDef>[];
  for (var i = 0; i < fields.length; i++) {
    if (i.isEven) {
      left.add(fields[i]);
    } else {
      right.add(fields[i]);
    }
  }
  return [left, right];
}

class DriverParamColumn extends StatelessWidget {
  const DriverParamColumn({
    super.key,
    required this.title,
    required this.tabLabels,
    required this.tabIndex,
    required this.onTabChanged,
    required this.fieldGroups,
    required this.model,
    required this.onFieldChanged,
    this.sectionKey = '',
    this.busy = false,
  });

  final String title;
  final List<String> tabLabels;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final List<List<DriverFieldDef>> fieldGroups;
  final DriverParamsModel model;
  final void Function(String key, String value) onFieldChanged;
  final String sectionKey;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fields =
        tabIndex < fieldGroups.length ? fieldGroups[tabIndex] : const <DriverFieldDef>[];
    final cols = _splitDualColumns(fields);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DriverCanshuPanelHeader(
          title: title,
          tabLabels: tabLabels,
          tabIndex: tabIndex,
          onTabChanged: onTabChanged,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _fieldList(cols[0])),
                const SizedBox(width: 2),
                Expanded(child: _fieldList(cols[1])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldList(List<DriverFieldDef> defs) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final def in defs)
          DriverParamField(
            key: ValueKey(def.key),
            def: def,
            value: model.get(def.key),
            onChanged: (v) => onFieldChanged(def.key, v),
            enabled: !busy,
          ),
      ],
    );
  }
}

class DriverGainColumn extends StatelessWidget {
  const DriverGainColumn({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.model,
    required this.onFieldChanged,
    this.busy = false,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final DriverParamsModel model;
  final void Function(String key, String value) onFieldChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final left = tabIndex == 1
        ? DriverParamsDefs.gainTab2Left
        : DriverParamsDefs.gainTab1Left;
    final right = tabIndex == 1
        ? DriverParamsDefs.gainTab2Right
        : DriverParamsDefs.gainTab1Right;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DriverCanshuPanelHeader(
          title: '增益调整',
          tabLabels: const ['1', '2'],
          tabIndex: tabIndex,
          onTabChanged: onTabChanged,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _fieldList(left)),
                const SizedBox(width: 2),
                Expanded(child: _fieldList(right)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldList(List<DriverFieldDef> defs) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final def in defs)
          DriverParamField(
            key: ValueKey(def.key),
            def: def,
            value: model.get(def.key),
            onChanged: (v) => onFieldChanged(def.key, v),
            enabled: !busy,
          ),
      ],
    );
  }
}
