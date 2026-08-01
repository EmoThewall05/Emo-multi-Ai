import 'dart:math';
import 'dart:typed_data';
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

class _Particle {
  final Offset start;
  final Offset target;
  final Color color;
  final double radius;
  final double stagger;

  _Particle({
    required this.start,
    required this.target,
    required this.color,
    required this.radius,
    required this.stagger,
  });
}

class _ScratchRevealButterflyState extends State<ScratchRevealButterfly>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _image;
  Object? _error;
  List<_Particle>? _particles;

  static const int _particleCount = 450;
  static const double _assembleEnd = 0.82;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadImage();
    _controller.forward();
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (!mounted || byteData == null) return;
      final particles = _buildParticles(image, byteData);
      setState(() {
        _image = image;
        _particles = particles;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  List<_Particle> _buildParticles(ui.Image image, ByteData byteData) {
    final rnd = Random(11);
    final imgW = image.width;
    final imgH = image.height;
    final imgSize = Size(imgW.toDouble(), imgH.toDouble());
    final boxSize = Size(widget.height, widget.height);
    final fitted = applyBoxFit(BoxFit.contain, imgSize, boxSize);
    final destRect = Alignment.center.inscribe(fitted.destination, Offset.zero & boxSize);

    final pixels = byteData.buffer.asUint8List();

    Color? colorAt(int x, int y) {
      if (x < 0 || y < 0 || x >= imgW || y >= imgH) return null;
      final idx = (y * imgW + x) * 4;
      final a = pixels[idx + 3];
      if (a < 40) return null;
      return Color.fromARGB(a, pixels[idx], pixels[idx + 1], pixels[idx + 2]);
    }

    final particles = <_Particle>[];
    int attempts = 0;
    final scatterRadius = widget.height * 0.9;
    final center = Offset(widget.height / 2, widget.height / 2);

    while (particles.length < _particleCount && attempts < _particleCount * 40) {
      attempts++;
      final sx = rnd.nextInt(imgW);
      final sy = rnd.nextInt(imgH);
      final color = colorAt(sx, sy);
      if (color == null) continue;

      final u = sx / imgW;
      final v = sy / imgH;
      final target = Offset(
        destRect.left + u * destRect.width,
        destRect.top + v * destRect.height,
      );

      final angle = rnd.nextDouble() * 2 * pi;
      final dist = scatterRadius * (0.4 + rnd.nextDouble() * 0.9);
      final start = center + Offset(cos(angle), sin(angle)) * dist;

      particles.add(_Particle(
        start: start,
        target: target,
        color: color,
        radius: 1.3 + rnd.nextDouble() * 1.4,
        stagger: rnd.nextDouble() * 0.35,
      ));
    }

    return particles;
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
          if (_image == null || _particles == null) {
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
            painter: _ParticlePainter(
              image: _image!,
              particles: _particles!,
              progress: _controller.value,
              assembleEnd: _assembleEnd,
            ),
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final ui.Image image;
  final List<_Particle> particles;
  final double progress;
  final double assembleEnd;

  _ParticlePainter({
    required this.image,
    required this.particles,
    required this.progress,
    required this.assembleEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final denom = (assembleEnd - p.stagger);
      final local = denom <= 0
          ? 1.0
          : ((progress - p.stagger) / denom).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(local);
      final pos = Offset.lerp(p.start, p.target, eased)!;
      final radius = p.radius * (1.0 + (1 - eased) * 0.6);
      paint.color = p.color;
      canvas.drawCircle(pos, radius, paint);
    }

    if (progress > assembleEnd) {
      final fadeT = ((progress - assembleEnd) / (1 - assembleEnd)).clamp(0.0, 1.0);
      final imgOpacity = Curves.easeIn.transform(fadeT);
      final imgPaint = Paint()..color = Colors.white.withValues(alpha: imgOpacity);
      _drawImageContain(canvas, size, imgPaint);
    }
  }

  void _drawImageContain(Canvas canvas, Size size, Paint paint) {
    final imgSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imgSize, size);
    final sourceRect = Alignment.center.inscribe(fitted.source, Offset.zero & imgSize);
    final destRect = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image, sourceRect, destRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.image != image;
}
