import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  final Color barColor;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor = const Color(0xFFD4A0A0),
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Sin datos', style: TextStyle(color: Colors.white.withAlpha(100))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size(double.infinity, height),
            painter: _BarChartPainter(data: data, barColor: barColor),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Color barColor;

  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final entries = data.entries.toList();
    final barWidth = (size.width - 40) / entries.length - 8;
    final chartHeight = size.height - 30;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Colors.white.withAlpha(150),
      fontSize: 10,
    );

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final barHeight = (entry.value / maxVal) * chartHeight;
      final x = 30 + i * (barWidth + 8);
      final y = chartHeight - barHeight;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rRect, barPaint);

      // Value
      final valueSpan = TextSpan(text: '${entry.value}', style: textStyle);
      final valuePainter = TextPainter(text: valueSpan, textDirection: TextDirection.ltr)..layout();
      valuePainter.paint(canvas, Offset(x + barWidth / 2 - valuePainter.width / 2, y - 14));

      // Label
      final labelSpan = TextSpan(text: entry.key, style: textStyle.copyWith(fontSize: 9));
      final labelPainter = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
      labelPainter.paint(canvas, Offset(x + barWidth / 2 - labelPainter.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
