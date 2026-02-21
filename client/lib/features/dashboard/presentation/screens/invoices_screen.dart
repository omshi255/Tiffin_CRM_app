import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.description_outlined,
      title: 'No invoices yet',
      subtitle: 'Generated invoices will appear here.',
    );
  }
}
