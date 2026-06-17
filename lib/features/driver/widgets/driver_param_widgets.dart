import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';
import '../driver_params_defs.dart';
import '../driver_params_model.dart';
import '../driver_ui_style.dart';

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
      color: selected ? LpRobotColors.primary.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? LpRobotColors.primary : DriverUiStyle.boxBorder,
              width: DriverUiStyle.boxBorderWidth,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? LpRobotColors.primary : LpRobotColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class DriverParamField extends StatefulWidget {
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

  @override
  State<DriverParamField> createState() => _DriverParamFieldState();
}

class _DriverParamFieldState extends State<DriverParamField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant DriverParamField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Text(
              widget.def.label,
              textAlign: TextAlign.end,
              style: DriverUiStyle.labelStyle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 12,
            child: TextField(
              enabled: widget.enabled,
              controller: _controller,
              onChanged: widget.onChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
              ],
              style: DriverUiStyle.fieldTextStyle,
              decoration: DriverUiStyle.fieldDecoration(enabled: widget.enabled),
            ),
          ),
        ],
      ),
    );
  }
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
    this.busy = false,
  });

  final String title;
  final List<String> tabLabels;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final List<List<DriverFieldDef>> fieldGroups;
  final DriverParamsModel model;
  final void Function(String key, String value) onFieldChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fields = tabIndex < fieldGroups.length ? fieldGroups[tabIndex] : const <DriverFieldDef>[];
    return DecoratedBox(
      decoration: DriverUiStyle.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: DriverUiStyle.sectionTitleStyle,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < tabLabels.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                DriverTabChip(
                  label: tabLabels[i],
                  selected: tabIndex == i,
                  onTap: () => onTabChanged(i),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              children: [
                for (final def in fields)
                  DriverParamField(
                    def: def,
                    value: model.get(def.key),
                    onChanged: (v) => onFieldChanged(def.key, v),
                    enabled: !busy,
                  ),
              ],
            ),
          ),
        ],
      ),
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
    if (tabIndex == 1) {
      return DriverParamColumn(
        title: '增益调整',
        tabLabels: const ['1', '2'],
        tabIndex: tabIndex,
        onTabChanged: onTabChanged,
        fieldGroups: const [DriverParamsDefs.gainTab2],
        model: model,
        onFieldChanged: onFieldChanged,
        busy: busy,
      );
    }
    return DecoratedBox(
      decoration: DriverUiStyle.panelDecoration(),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('增益调整', style: DriverUiStyle.sectionTitleStyle),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DriverTabChip(label: '1', selected: true, onTap: () => onTabChanged(0)),
              const SizedBox(width: 4),
              DriverTabChip(label: '2', selected: false, onTap: () => onTabChanged(1)),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(4),
                    children: [
                      for (final def in DriverParamsDefs.gainTab1Left)
                        DriverParamField(
                          def: def,
                          value: model.get(def.key),
                          onChanged: (v) => onFieldChanged(def.key, v),
                          enabled: !busy,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(4),
                    children: [
                      for (final def in DriverParamsDefs.gainTab1Right)
                        DriverParamField(
                          def: def,
                          value: model.get(def.key),
                          onChanged: (v) => onFieldChanged(def.key, v),
                          enabled: !busy,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
