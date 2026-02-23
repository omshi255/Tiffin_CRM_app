import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/customer_model.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subs = getMockSubscriptionsByCustomerId(customer.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push(AppRoutes.editCustomer, extra: customer),
          ),
        ],
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
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.onPrimaryContainer,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      customer.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (customer.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        customer.email!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (customer.address != null && customer.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        customer.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription History',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (subs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No subscriptions yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ...subs.map(
                (s) {
                  final plan = getMockMealPlanById(s.planId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(plan?.planName ?? s.planId),
                      subtitle: Text(
                        '${s.startDate.day}/${s.startDate.month}/${s.startDate.year} - ${s.endDate.day}/${s.endDate.month}/${s.endDate.year}',
                      ),
                      trailing: Chip(
                        label: Text(
                          s.status,
                          style: theme.textTheme.labelSmall,
                        ),
                        backgroundColor: s.status == 'active'
                            ? AppColors.secondaryContainer
                            : theme.colorScheme.surfaceContainerHigh,
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
