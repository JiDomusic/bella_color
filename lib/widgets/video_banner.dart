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

class _VideoBannerState extends State<VideoBanner> {
  late String _viewId;
  bool _visible = true;

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
      ..style.objectFit = 'contain'
      ..style.backgroundColor = 'transparent'
      ..setAttribute('playsinline', 'true');

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => video);

    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    // Formato reel vertical (9:16) - se ve completo sin recorte
    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 480),
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
      ),
    );
  }
}
