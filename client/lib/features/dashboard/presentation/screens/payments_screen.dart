import 'package:flutter/material.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/section_header.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = mockPayments.where((p) => p.status == 'pending').toList();
    final history = mockPayments.where((p) => p.status == 'completed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Collect Payment',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Customer'),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Mode (Cash/UPI)'),
                    ),
                    const SizedBox(height: 16),
                    // API_INTEGRATION
                    // Endpoint: POST /api/payments
                    // Purpose: Record payment
                    // Request: { customerId: String, amount: double, mode: String }
                    // Response: { id: String, customerId: String, amount: double, date: String }
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: const Text('Record Payment'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Overdue Payments'),
            const SizedBox(height: 12),
            if (overdue.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No overdue payments',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...overdue.map(
                (p) {
                  final amountColor = statusBorderColor(p.status);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Customer ${p.customerId}'),
                      subtitle: Text(
                        '${p.date.day}/${p.date.month}/${p.date.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Text(
                        '₹${p.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Payment History'),
            const SizedBox(height: 12),
            ...history.map(
              (p) {
                final amountColor = statusBorderColor(p.status);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('Customer ${p.customerId}'),
                    subtitle: Text(
                      '${p.mode} • ${p.date.day}/${p.date.month}/${p.date.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      '₹${p.amount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
