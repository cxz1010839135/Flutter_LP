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
        final h = constraints.maxHeight;
        final labelSize = (h * 0.18).clamp(14.0, 17.0);
        final valueSize = (h * 0.24).clamp(15.0, 20.0);
        final continuousSize = (h * 0.22).clamp(15.0, 20.0);
        final bracketH = (h * 0.16).clamp(10.0, 14.0);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Ink(
                decoration: _decoration(),
                child: _isDistance
                    ? _distanceBody(
                        labelSize: labelSize,
                        valueSize: valueSize,
                        bracketH: bracketH,
                      )
                    : _continuousBody(fontSize: continuousSize),
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
      );
    }

    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFFFFC995),
        width: 1.4,
      ),
    );
  }

  Widget _continuousBody({required double fontSize}) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : LpRobotColors.primary,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _distanceBody({
    required double labelSize,
    required double valueSize,
    required double bracketH,
  }) {
    final accent = selected ? Colors.white : LpRobotColors.primary;
    const valueColor = LpRobotColors.textDark;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, selected ? 8 : 6, 4, selected ? 6 : 4),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.1,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: _distanceField(valueColor, fontSize: valueSize),
            ),
          ),
          SizedBox(
            height: bracketH,
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

  Widget _distanceField(Color textColor, {required double fontSize}) {
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
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: textColor,
        height: 1.15,
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

    final y = size.height * 0.55;
    final halfW = (size.width * 0.36 * scale).clamp(8.0, size.width * 0.38);
    final cx = size.width / 2;
    const horn = 4.0;

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
