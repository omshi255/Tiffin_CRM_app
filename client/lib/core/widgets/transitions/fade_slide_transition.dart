import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 24),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class StaggeredFadeSlide extends StatelessWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 380),
    this.stagger = const Duration(milliseconds: 60),
    this.offset = const Offset(0, 20),
  });

  final List<Widget> children;
  final Duration duration;
  final Duration stagger;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0, end: 1),
            duration: duration + (stagger * i),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
                  child: child,
                ),
              );
            },
            child: children[i],
          ),
      ],
    );
  }
}
