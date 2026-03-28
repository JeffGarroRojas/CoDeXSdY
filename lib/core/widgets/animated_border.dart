import 'package:flutter/material.dart';

class AnimatedBorderWidget extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color color1;
  final Color color2;

  const AnimatedBorderWidget({
    super.key,
    required this.child,
    this.width = 350,
    this.height = 220,
    this.color1 = const Color(0xFF007AFF),
    this.color2 = const Color(0xFF6F42C1),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: SweepGradient(
          colors: [color1, color2, color1, color2, color1, color2],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
      ),
    );
  }
}

class CircularAnimatedBorder extends StatelessWidget {
  final Widget child;
  final double size;
  final Color color1;
  final Color color2;

  const CircularAnimatedBorder({
    super.key,
    required this.child,
    this.size = 120,
    this.color1 = const Color(0xFF007AFF),
    this.color2 = const Color(0xFF6F42C1),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [color1, color2, color1, color2, color1],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(12),
        child: ClipOval(
          child: SizedBox(width: size - 40, height: size - 40, child: child),
        ),
      ),
    );
  }
}
