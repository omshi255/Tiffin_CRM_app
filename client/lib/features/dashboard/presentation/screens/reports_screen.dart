import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.analytics_outlined,
      title: 'No reports yet',
      subtitle: 'Generate reports from the data you collect.',
    );
  }
}
