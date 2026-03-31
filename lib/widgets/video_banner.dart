import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class VideoBanner extends StatefulWidget {
  final String videoUrl;
  final Color borderColor;
  final VoidCallback? onPlay;
  final VoidCallback? onEnded;

  const VideoBanner({
    super.key,
    required this.videoUrl,
    required this.borderColor,
    this.onPlay,
    this.onEnded,
  });

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> {
  late String _viewId;

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

    video.onPlay.listen((_) => widget.onPlay?.call());
    video.onEnded.listen((_) => widget.onEnded?.call());

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => video);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Responsive: desktop chico, mobile más grande
        final double videoWidth;
        final double videoHeight;

        if (screenWidth > 900) {
          // Desktop → estilo Instagram web reel
          videoWidth = 300;
          videoHeight = 530;
        } else if (screenWidth > 600) {
          // Tablet
          videoWidth = 280;
          videoHeight = 500;
        } else {
          // Mobile → reel más grande pero no fullscreen
          videoWidth = screenWidth * 0.65;
          videoHeight = videoWidth * (16 / 9);
        }

        return Center(
          child: Container(
            width: videoWidth,
            height: videoHeight,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.borderColor.withAlpha(80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.borderColor.withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: HtmlElementView(viewType: _viewId),
          ),
        );
      },
    );
  }
}
