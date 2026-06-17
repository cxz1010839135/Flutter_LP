import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';

/// 模式选择格：Flutter 自绘，对齐 Android 截图（不用 PNG，避免拉伸/叠层）。
class ControlModeTile extends StatelessWidget {
  const ControlModeTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.distanceController,
    this.bracketScale = 1.0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextEditingController? distanceController;
  final double bracketScale;

  bool get _isDistance => distanceController != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxHeight < constraints.maxWidth
            ? constraints.maxHeight
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Ink(
                  decoration: _decoration(),
                  child: _isDistance ? _distanceBody() : _continuousBody(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _decoration() {
    if (selected) {
      return BoxDecoration(
        color: LpRobotColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _glow(0.42, blur: 14, spread: 2),
      );
    }

    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFFFFC995),
        width: 1.4,
      ),
      boxShadow: _glow(0.28, blur: 12, spread: 1),
    );
  }

  List<BoxShadow> _glow(
    double alpha, {
    double blur = 10,
    double spread = 0,
  }) =>
      [
        BoxShadow(
          color: LpRobotColors.primary.withValues(alpha: alpha),
          blurRadius: blur,
          spreadRadius: spread,
          offset: Offset.zero,
        ),
      ];

  Widget _continuousBody() {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : LpRobotColors.primary,
        ),
      ),
    );
  }

  Widget _distanceBody() {
    final accent = selected ? Colors.white : LpRobotColors.primary;
    // 选中时橙底 + 白字在部分 Windows 主题下会不可见，数字改用白底橙字。
    final valueColor = LpRobotColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
              height: 1.1,
            ),
          ),
          Expanded(
            child: Center(
              child: selected
                  ? Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _distanceField(valueColor),
                    )
                  : _distanceField(LpRobotColors.textDark),
            ),
          ),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _ModeBracketPainter(
                scale: bracketScale,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _distanceField(Color textColor) {
    return TextField(
      controller: distanceController,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.1,
      ),
      cursorColor: textColor,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        filled: false,
      ),
      onTap: onTap,
    );
  }
}

class _ModeBracketPainter extends CustomPainter {
  _ModeBracketPainter({required this.scale, required this.color});

  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.45;
    final halfW = (size.width * 0.38 * scale).clamp(10.0, size.width * 0.42);
    final cx = size.width / 2;
    const horn = 5.0;

    final left = Offset(cx - halfW, y);
    final right = Offset(cx + halfW, y);

    final path = Path()
      ..moveTo(left.dx, left.dy - horn)
      ..lineTo(left.dx, left.dy + horn)
      ..moveTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..moveTo(right.dx, right.dy - horn)
      ..lineTo(right.dx, right.dy + horn);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ModeBracketPainter old) =>
      old.scale != scale || old.color != color;
}
