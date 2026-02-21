import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class MealPlansScreen extends StatelessWidget {
  const MealPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.restaurant_menu_outlined,
      title: 'No meal plans yet',
      subtitle: 'Create meal plans to offer to your customers.',
    );
  }
}
