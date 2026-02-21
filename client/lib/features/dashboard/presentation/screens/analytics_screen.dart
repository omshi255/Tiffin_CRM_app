import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.insights_outlined,
      title: 'No analytics data yet',
      subtitle: 'Analytics will show trends and insights.',
    );
  }
}
