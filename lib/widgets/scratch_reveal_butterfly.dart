import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScratchRevealButterfly extends StatefulWidget {
  final String assetPath;
  final double height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ScratchRevealButterfly({
    super.key,
    required this.assetPath,
    required this.height,
    this.errorBuilder,
  });

  @override
  State<ScratchRevealButterfly> createState() => _ScratchRevealButterflyState();
}

class _ScratchRevealButterflyState extends State<ScratchRevealButterfly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _image;
  Object? _error;
  late List<Path> _strokes;
  late List<double> _staggerStart;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _generateStrokes();
    _loadImage();
    _controller.forward();
  }

  void _generateStrokes() {
    final size = widget.height;
    final rnd = Random(7);
    const strokeCount = 16;
    _strokes = [];
    _staggerStart = [];
    for (int i = 0; i < strokeCount; i++) {
      final startEdge = rnd.nextInt(4);
      Offset start;
      switch (startEdge) {
        case 0:
          start = Offset(rnd.nextDouble() * size, 0);
          break;
        case 1:
          start = Offset(size, rnd.nextDouble() * size);
          break;
        case 2:
          start = Offset(rnd.nextDouble() * size, size);
          break;
        default:
          start = Offset(0, rnd.nextDouble() * size);
      }
      final end = Offset(
        size * 0.5 + (rnd.nextDouble() - 0.5) * size * 1.2,
        size * 0.5 + (rnd.nextDouble() - 0.5) * size * 1.2,
      );
      final control = Offset(
        (start.dx + end.dx) / 2 + (rnd.nextDouble() - 0.5) * size * 0.6,
        (start.dy + end.dy) / 2 + (rnd.nextDouble() - 0.5) * size * 0.6,
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      _strokes.add(path);
      _staggerStart.add(i / strokeCount * 0.55);
    }
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!, null) ??
          const Icon(Icons.auto_awesome, size: 100, color: Colors.purpleAccent);
    }

    return SizedBox(
      width: widget.height,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_image == null) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
              ),
            );
          }
          return CustomPaint(
            size: Size(widget.height, widget.height),
            painter: _ScratchPainter(
              image: _image!,
              progress: _controller.value,
              strokes: _strokes,
              staggerStart: _staggerStart,
            ),
          );
        },
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final List<Path> strokes;
  final List<double> staggerStart;

  _ScratchPainter({
    required this.image,
    required this.progress,
    required this.strokes,
    required this.staggerStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.999) {
      _drawImageContain(canvas, size, Paint());
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.22;

    for (int i = 0; i < strokes.length; i++) {
      final denom = (1 - staggerStart[i]);
      final localProgress = denom <= 0
          ? 1.0
          : ((progress - staggerStart[i]) / denom).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;
      final metric = strokes[i].computeMetrics().first;
      final extractLength = metric.length * Curves.easeOut.transform(localProgress);
      final subPath = metric.extractPath(0, extractLength);
      canvas.drawPath(subPath, strokePaint);
    }

    final imagePaint = Paint()..blendMode = BlendMode.srcIn;
    _drawImageContain(canvas, size, imagePaint);

    canvas.restore();
  }

  void _drawImageContain(Canvas canvas, Size size, Paint paint) {
    final imgSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imgSize, size);
    final sourceRect = Alignment.center.inscribe(fitted.source, Offset.zero & imgSize);
    final destRect = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image, sourceRect, destRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.image != image;
}
