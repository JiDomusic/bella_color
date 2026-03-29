import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class VideoBanner extends StatefulWidget {
  final String videoUrl;
  final Color borderColor;

  const VideoBanner({super.key, required this.videoUrl, required this.borderColor});

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> with SingleTickerProviderStateMixin {
  late String _viewId;
  bool _visible = true;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-banner-${widget.videoUrl.hashCode}';

    final video = html.VideoElement()
      ..src = widget.videoUrl
      ..autoplay = true
      ..muted = true
      ..loop = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.borderRadius = '14px'
      ..setAttribute('playsinline', 'true');

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => video);

    // A los 18s empieza fade out, a los 20s desaparece
    Future.delayed(const Duration(seconds: 18), () {
      if (mounted) setState(() => _opacity = 0.0);
    });
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(seconds: 2),
      child: Container(
        width: double.infinity,
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.borderColor.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.borderColor.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}
