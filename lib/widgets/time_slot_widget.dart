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
    if (!isAvailable) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.red[300],
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ocupado',
              style: TextStyle(fontSize: 9, color: Colors.red[300], fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? primary : Colors.grey[400]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primary.withAlpha(60), blurRadius: 10, spreadRadius: 1)]
              : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}
