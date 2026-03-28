import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBanner extends StatefulWidget {
  final String videoUrl;
  final Color borderColor;

  const VideoBanner({super.key, required this.videoUrl, required this.borderColor});

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      }).catchError((e) {
        debugPrint('VideoBanner error: $e');
        if (mounted) setState(() { _error = true; _errorMsg = e.toString(); });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('Error al cargar video: $_errorMsg',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.borderColor.withAlpha(60)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _initialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}
