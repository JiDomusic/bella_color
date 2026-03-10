import 'package:flutter/material.dart';

class UrgencyBanner extends StatefulWidget {
  final int available;
  final int total;
  final Color primary;

  const UrgencyBanner({
    super.key,
    required this.available,
    required this.total,
    required this.primary,
  });

  @override
  State<UrgencyBanner> createState() => _UrgencyBannerState();
}

class _UrgencyBannerState extends State<UrgencyBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.total <= 0) return const SizedBox.shrink();

    final ratio = widget.available / widget.total;
    if (ratio > 0.3) return const SizedBox.shrink();

    final Color bannerColor;
    final String message;
    final IconData icon;

    if (widget.available <= 0) {
      bannerColor = Colors.red.shade700;
      message = 'Turnos agotados para este horario';
      icon = Icons.block;
    } else if (ratio <= 0.1) {
      bannerColor = Colors.red.shade600;
      message = 'Ultimo turno disponible!';
      icon = Icons.local_fire_department;
    } else {
      bannerColor = Colors.amber.shade700;
      message = 'Quedan pocos turnos - Alta demanda';
      icon = Icons.trending_up;
    }

    return ScaleTransition(
      scale: _pulse,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bannerColor.withAlpha(40), bannerColor.withAlpha(20)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bannerColor.withAlpha(100)),
        ),
        child: Row(
          children: [
            Icon(icon, color: bannerColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: bannerColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
