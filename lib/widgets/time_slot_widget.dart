import 'package:flutter/material.dart';


class TimeSlotWidget extends StatelessWidget {
  final String time;
  final bool isSelected;
  final bool isAvailable;
  final Color primary;
  final VoidCallback? onTap;

  const TimeSlotWidget({
    super.key,
    required this.time,
    this.isSelected = false,
    this.isAvailable = true,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final Color borderColor;

    if (!isAvailable) {
      bg = Colors.white.withAlpha(8);
      textColor = Colors.white.withAlpha(60);
      borderColor = Colors.red.withAlpha(80);
    } else if (isSelected) {
      bg = primary.withAlpha(40);
      textColor = primary;
      borderColor = primary;
    } else {
      bg = Colors.white.withAlpha(10);
      textColor = Colors.white.withAlpha(200);
      borderColor = Colors.white.withAlpha(30);
    }

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          // Cross-out for unavailable
          if (!isAvailable)
            Positioned.fill(
              child: CustomPaint(painter: _CrossPainter(Colors.red.withAlpha(100))),
            ),
        ],
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  final Color color;
  _CrossPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(4, 4), Offset(size.width - 4, size.height - 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
