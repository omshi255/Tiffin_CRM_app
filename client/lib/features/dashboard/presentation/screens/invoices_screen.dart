import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mockInvoices = [
      {'number': 'INV-001', 'customer': 'Rajesh Kumar', 'amount': 4500},
      {'number': 'INV-002', 'customer': 'Priya Sharma', 'amount': 5000},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockInvoices.length,
        itemBuilder: (context, index) {
          final inv = mockInvoices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(inv['number'] as String),
              subtitle: Text(
                '${inv['customer']} • ₹${inv['amount']}',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PDF Invoice Viewer Placeholder',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
