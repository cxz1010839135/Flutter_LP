import 'package:flutter/material.dart';

import '../../app/lp_robot_colors.dart';
import 'monitor_special_registers.dart';

/// 弹出特殊寄存器说明（对齐 Blockly「版本信息」弹窗风格）。
Future<void> showMonitorSpecialRegisterDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final width = (size.width * 0.72).clamp(480.0, 720.0);
      final height = (size.height * 0.72).clamp(360.0, 560.0);

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: BoxDecoration(
                  color: LpRobotColors.primary.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '特殊寄存器说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LpRobotColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Text(
                  MonitorSpecialRegisters.intro,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: LpRobotColors.label,
                    height: 1.4,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: MonitorSpecialRegisters.entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = MonitorSpecialRegisters.entries[index];
                      return _RegisterRefTile(item: item);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('确定'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RegisterRefTile extends StatelessWidget {
  const _RegisterRefTile({required this.item});

  final SpecialRegisterRef item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LpRobotColors.surfaceWarm,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LpRobotColors.borderWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.address,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Consolas',
                    color: LpRobotColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                _AccessChip(access: item.access),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.function,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LpRobotColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: LpRobotColors.label,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.access});

  final String access;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: LpRobotColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        access,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: LpRobotColors.primary,
          fontFamily: 'Consolas',
        ),
      ),
    );
  }
}
