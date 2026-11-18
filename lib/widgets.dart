import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// خلفية مستقبلية: تدرج داكن + كرات نيون متحركة + شبكة خفيفة.
class NeonBackdrop extends StatefulWidget {
  final Widget child;
  const NeonBackdrop({super.key, required this.child});

  @override
  State<NeonBackdrop> createState() => _NeonBackdropState();
}

class _NeonBackdropState extends State<NeonBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _orb(Alignment a, Color col, double size) => Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [col.withOpacity(0.28), col.withOpacity(0)],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.bg1, C.bg0],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = _c.value * 2 * pi;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _orb(Alignment(sin(t) * .9, cos(t) * .7), C.violet, 340),
                  _orb(Alignment(cos(t + 2) * .9, sin(t + 1) * .8), C.cyan, 300),
                  _orb(Alignment(sin(t + 4) * .8, cos(t + 3) * .9), C.pink, 260),
                ],
              );
            },
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// بطاقة زجاجية بتوهج نيون.
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color glow;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.glow = C.cyan,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: glow.withOpacity(0.18), blurRadius: 24)],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: r,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  border: Border.all(color: glow.withOpacity(0.45)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زر متوهج بتدرج لوني.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final List<Color> colors;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.colors = const [C.cyan, C.violet],
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(colors: colors),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.45), blurRadius: 22)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.black87),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
