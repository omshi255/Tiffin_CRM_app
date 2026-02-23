import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Slide from right (300ms) for forward, slide to right (250ms) for back
Page<dynamic> slideTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOut),
      );
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
