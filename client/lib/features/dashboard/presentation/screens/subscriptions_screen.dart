import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'No active subscriptions',
      subtitle: 'Subscriptions will appear here once customers subscribe.',
    );
  }
}
