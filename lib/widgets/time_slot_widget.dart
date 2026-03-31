import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/public_theme.dart';

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
          color: PublicTheme.cream,
          shape: BoxShape.circle,
          border: Border.all(color: PublicTheme.stroke, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.red[200],
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ocupado',
              style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.red[300], fontWeight: FontWeight.w700),
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
          color: isSelected ? Colors.black : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : PublicTheme.stroke,
            width: isSelected ? 3 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Colors.black : primary).withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            time,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isSelected ? Colors.white : PublicTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
