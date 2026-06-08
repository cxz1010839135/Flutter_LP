import 'package:flutter/material.dart';

import '../lp_robot_colors.dart';

/// 主界面左侧导航式模块按钮（白底圆角 + 橙色图标文字）
class LpModuleButton extends StatelessWidget {
  const LpModuleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: LpRobotColors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? LpRobotColors.primary.withValues(alpha: 0.35)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled ? LpRobotColors.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: enabled ? LpRobotColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
