import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PerformanceUtils {
  static bool get isLowEndDevice => kIsWeb ? false : _detectLowEndDevice();

  static bool _detectLowEndDevice() {
    return false;
  }

  static Duration get animationDuration {
    return isLowEndDevice
        ? const Duration(milliseconds: 150)
        : const Duration(milliseconds: 300);
  }

  static Duration get fastAnimationDuration {
    return isLowEndDevice
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 200);
  }

  static Duration get slowAnimationDuration {
    return isLowEndDevice
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 400);
  }
}

class OptimizedAnimatedList extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const OptimizedAnimatedList({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _OptimizedFadeSlide(index: index, delay: delay, child: child),
    );
  }
}

class _OptimizedFadeSlide extends StatefulWidget {
  final int index;
  final Duration delay;
  final Widget child;

  const _OptimizedFadeSlide({
    required this.index,
    required this.delay,
    required this.child,
  });

  @override
  State<_OptimizedFadeSlide> createState() => _OptimizedFadeSlideState();
}

class _OptimizedFadeSlideState extends State<_OptimizedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformanceUtils.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 20,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class OptimizedImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OptimizedImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: PerformanceUtils.fastAnimationDuration,
          child: frame != null
              ? child
              : placeholder ??
                    Container(
                      width: width,
                      height: height,
                      color: Colors.grey[900],
                    ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[900],
              child: const Icon(Icons.image_not_supported),
            );
      },
    );
  }
}

class PerformanceOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: PerformanceUtils.slowAnimationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          suffix != null ? '$value$suffix' : value.toString(),
          style: style,
        );
      },
    );
  }
}

extension PerformanceExtension on Widget {
  Widget optimizedFadeIn({Duration delay = Duration.zero, Duration? duration}) {
    return _OptimizedFade(delay: delay, duration: duration, child: this);
  }

  Widget optimizedSlideIn({
    Duration delay = Duration.zero,
    Offset begin = const Offset(0, 0.1),
    Duration? duration,
  }) {
    return _OptimizedSlide(
      delay: delay,
      begin: begin,
      duration: duration,
      child: this,
    );
  }

  Widget optimizedScale({
    Duration delay = Duration.zero,
    double begin = 0.8,
    Duration? duration,
  }) {
    return _OptimizedScale(
      delay: delay,
      begin: begin,
      duration: duration,
      child: this,
    );
  }
}

class _OptimizedFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration? duration;

  const _OptimizedFade({
    required this.child,
    required this.delay,
    this.duration,
  });

  @override
  State<_OptimizedFade> createState() => _OptimizedFadeState();
}

class _OptimizedFadeState extends State<_OptimizedFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? PerformanceUtils.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          Opacity(opacity: _animation.value, child: child),
      child: widget.child,
    );
  }
}

class _OptimizedSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset begin;
  final Duration? duration;

  const _OptimizedSlide({
    required this.child,
    required this.delay,
    required this.begin,
    this.duration,
  });

  @override
  State<_OptimizedSlide> createState() => _OptimizedSlideState();
}

class _OptimizedSlideState extends State<_OptimizedSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? PerformanceUtils.animationDuration,
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_animation.value.dx * 100, _animation.value.dy * 100),
        child: Opacity(opacity: _controller.value, child: child),
      ),
      child: widget.child,
    );
  }
}

class _OptimizedScale extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double begin;
  final Duration? duration;

  const _OptimizedScale({
    required this.child,
    required this.delay,
    required this.begin,
    this.duration,
  });

  @override
  State<_OptimizedScale> createState() => _OptimizedScaleState();
}

class _OptimizedScaleState extends State<_OptimizedScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? PerformanceUtils.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.begin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
        scale: _animation.value,
        child: Opacity(opacity: _animation.value.clamp(0.0, 1.0), child: child),
      ),
      child: widget.child,
    );
  }
}
