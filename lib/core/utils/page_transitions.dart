import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({required this.page, this.direction = SlideDirection.right})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          Offset begin;
          switch (direction) {
            case SlideDirection.left:
              begin = const Offset(-1.0, 0.0);
              break;
            case SlideDirection.right:
              begin = const Offset(1.0, 0.0);
              break;
            case SlideDirection.up:
              begin = const Offset(0.0, 1.0);
              break;
            case SlideDirection.down:
              begin = const Offset(0.0, -1.0);
              break;
          }

          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      );
}

enum SlideDirection { left, right, up, down }

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );
}

class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  RotationPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );
}

class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HeroPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

class AnimatedRouteHelper {
  static void navigate(
    BuildContext context,
    Widget page, {
    RouteTransitionType type = RouteTransitionType.fade,
    SlideDirection slideDirection = SlideDirection.right,
  }) {
    switch (type) {
      case RouteTransitionType.fade:
        Navigator.push(context, FadePageRoute(page: page));
        break;
      case RouteTransitionType.slide:
        Navigator.push(
          context,
          SlidePageRoute(page: page, direction: slideDirection),
        );
        break;
      case RouteTransitionType.scale:
        Navigator.push(context, ScalePageRoute(page: page));
        break;
      case RouteTransitionType.rotation:
        Navigator.push(context, RotationPageRoute(page: page));
        break;
      case RouteTransitionType.hero:
        Navigator.push(context, HeroPageRoute(page: page));
        break;
      case RouteTransitionType.none:
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        break;
    }
  }

  static void navigateAndReplace(
    BuildContext context,
    Widget page, {
    RouteTransitionType type = RouteTransitionType.fade,
  }) {
    PageRoute route;
    switch (type) {
      case RouteTransitionType.fade:
        route = FadePageRoute(page: page);
        break;
      case RouteTransitionType.slide:
        route = SlidePageRoute(page: page);
        break;
      case RouteTransitionType.scale:
        route = ScalePageRoute(page: page);
        break;
      case RouteTransitionType.rotation:
        route = RotationPageRoute(page: page);
        break;
      case RouteTransitionType.hero:
        route = HeroPageRoute(page: page);
        break;
      case RouteTransitionType.none:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
        return;
    }
    Navigator.pushReplacement(context, route);
  }
}

enum RouteTransitionType { fade, slide, scale, rotation, hero, none }

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeOffset;
  final int shakeCount;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeOffset = 10,
    this.shakeCount = 3,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));
  }

  void shake() {
    _controller.forward(from: 0);
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
      builder: (context, child) {
        final sineValue = _animation.value * widget.shakeCount * 3.14159 * 2;
        return Transform.translate(
          offset: Offset(
            widget.shakeOffset * _animation.value * (sineValue / 10).sin(),
            0,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

extension on double {
  double sin() => this == 0
      ? 0
      : this == 1
      ? 1
      : this < 0
      ? -_sin(-this)
      : _sin(this);

  double _sin(double x) {
    x = x % (3.14159 * 2);
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseWidget> createState() => PulseWidgetState();
}

class PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;

  const BounceWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.bounceHeight = 20,
  });

  @override
  State<BounceWidget> createState() => BounceWidgetState();
}

class BounceWidgetState extends State<BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -widget.bounceHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class LoadingDotsWidget extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const LoadingDotsWidget({
    super.key,
    this.color = Colors.white,
    this.size = 10,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<LoadingDotsWidget> createState() => _LoadingDotsWidgetState();
}

class _LoadingDotsWidgetState extends State<LoadingDotsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -10,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
