import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/onboarding_slide_data.dart';

class OnboardingSlidePage extends StatefulWidget {
  const OnboardingSlidePage({
    super.key,
    required this.data,
  });

  final OnboardingSlideData data;

  @override
  State<OnboardingSlidePage> createState() => _OnboardingSlidePageState();
}

class _OnboardingSlidePageState extends State<OnboardingSlidePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (data.iconCodePoint != null) ...[
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    IconData(data.iconCodePoint!, fontFamily: 'MaterialIcons'),
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 36),
              ],
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
