/// Three bouncing dots shown while waiting for the AI response.
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // wing flap angle: 0.0 (open) -> 1.0 (closed)
            final flap = _controller.value;
            return SizedBox(
              width: 26,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left wing
                  Transform(
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(flap * 1.1),
                    child: CustomPaint(
                      size: const Size(13, 20),
                      painter: _WingPainter(color: widget.color, isLeft: true),
                    ),
                  ),
                  // Right wing
                  Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-flap * 1.1),
                    child: CustomPaint(
                      size: const Size(13, 20),
                      painter: _WingPainter(color: widget.color, isLeft: false),
                    ),
                  ),
                  // Body
                  Container(
                    width: 2.4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints a single butterfly wing (upper + lower lobe) as a soft teardrop.
class _WingPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  const _WingPainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isLeft) {
      path.moveTo(w, h * 0.5);
      path.quadraticBezierTo(w * 0.1, 0, 0, h * 0.32);
      path.quadraticBezierTo(w * 0.05, h * 0.5, w, h * 0.5);
      path.moveTo(w, h * 0.5);
      path.quadraticBezierTo(w * 0.15, h * 0.62, w * 0.08, h);
      path.quadraticBezierTo(w * 0.35, h * 0.7, w, h * 0.5);
    } else {
      path.moveTo(0, h * 0.5);
      path.quadraticBezierTo(w * 0.9, 0, w, h * 0.32);
      path.quadraticBezierTo(w * 0.95, h * 0.5, 0, h * 0.5);
      path.moveTo(0, h * 0.5);
      path.quadraticBezierTo(w * 0.85, h * 0.62, w * 0.92, h);
      path.quadraticBezierTo(w * 0.65, h * 0.7, 0, h * 0.5);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) =>
      oldDelegate.color != color;
}
