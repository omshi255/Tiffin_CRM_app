import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.payments_outlined,
      title: 'No payments yet',
      subtitle: 'Payment history will appear here.',
    );
  }
}
