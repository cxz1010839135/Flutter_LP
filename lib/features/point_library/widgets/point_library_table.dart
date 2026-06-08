import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/lp_robot_colors.dart';
import '../../../core/robot_point_library.dart';

class _PointTableScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// 点库表格：轴列数由控制器 [axisCount] 决定（最多 32），超出可横向拖动。
class PointLibraryTable extends StatefulWidget {
  const PointLibraryTable({
    super.key,
    required this.axisCount,
    required this.points,
    required this.selectedIndex,
    required this.onSelected,
    this.onRename,
  });

  final int axisCount;
  final List<RobotPoint> points;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<RobotPoint>? onRename;

  static const double indexColWidth = 72;
  static const double labelColWidth = 110;
  static const double axisColWidth = 88;
  static const double rowHeight = 32;
  static const double headerHeight = 36;

  @override
  State<PointLibraryTable> createState() => _PointLibraryTableState();
}

class _PointLibraryTableState extends State<PointLibraryTable> {
  final ScrollController _hScroll = ScrollController();
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant PointLibraryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if (widget.points != oldWidget.points &&
        _selectedIndex != null &&
        !widget.points.any((p) => p.index == _selectedIndex)) {
      _selectedIndex = null;
    }
  }

  void _select(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    widget.onSelected(index);
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  double get _tableWidth =>
      PointLibraryTable.indexColWidth +
      PointLibraryTable.labelColWidth +
      widget.axisCount * PointLibraryTable.axisColWidth;

  String _formatJoint(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = math.max(_tableWidth, constraints.maxWidth);

            return ScrollConfiguration(
              behavior: _PointTableScrollBehavior(),
              child: Scrollbar(
                controller: _hScroll,
                thumbVisibility: tableWidth > constraints.maxWidth + 1,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: widget.points.isEmpty
                              ? const Center(
                                  child: Text(
                                    '暂无点位，请点击右侧 + 添加',
                                    style: TextStyle(
                                      color: LpRobotColors.label,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: widget.points.length,
                                  itemExtent: PointLibraryTable.rowHeight,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  itemBuilder: (context, index) {
                                    final point = widget.points[index];
                                    return _PointTableRow(
                                      point: point,
                                      rowIndex: index,
                                      axisCount: widget.axisCount,
                                      selected: _selectedIndex == point.index,
                                      onSelect: () => _select(point.index),
                                      onRename: widget.onRename == null
                                          ? null
                                          : () => widget.onRename!(point),
                                      formatJoint: _formatJoint,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: PointLibraryTable.headerHeight,
      color: LpRobotColors.primary,
      child: Row(
        children: [
          _headerCell('点编号', PointLibraryTable.indexColWidth),
          _headerCell('名称', PointLibraryTable.labelColWidth),
          for (var i = 0; i < widget.axisCount; i++)
            _headerCell('${i + 1}轴', PointLibraryTable.axisColWidth),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PointTableRow extends StatelessWidget {
  const _PointTableRow({
    required this.point,
    required this.rowIndex,
    required this.axisCount,
    required this.selected,
    required this.onSelect,
    required this.formatJoint,
    this.onRename,
  });

  final RobotPoint point;
  final int rowIndex;
  final int axisCount;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onRename;
  final String Function(double value) formatJoint;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? LpRobotColors.primary
        : rowIndex.isOdd
            ? LpRobotColors.surfaceWarm
            : LpRobotColors.surface;
    final fg = selected ? Colors.white : LpRobotColors.textDark;
    final borderColor =
        LpRobotColors.borderWarm.withValues(alpha: selected ? 0 : 0.35);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onSelect(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: onRename,
          onLongPress: onRename,
          child: SizedBox(
            height: PointLibraryTable.rowHeight,
            child: Row(
              children: [
                _cell('${point.index}', PointLibraryTable.indexColWidth, fg),
                _cell(
                  point.label,
                  PointLibraryTable.labelColWidth,
                  fg,
                  alignStart: true,
                ),
                for (var i = 0; i < axisCount; i++)
                  _cell(
                    formatJoint(point.jointAt(i)),
                    PointLibraryTable.axisColWidth,
                    fg,
                    alignStart: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String text,
    double width,
    Color color, {
    bool alignStart = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignStart ? Alignment.centerLeft : Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
