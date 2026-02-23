import 'package:flutter/material.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockSubscriptions.length,
        itemBuilder: (context, index) {
          final sub = mockSubscriptions[index];
          final customer = getMockCustomerById(sub.customerId);
          final plan = getMockMealPlanById(sub.planId);
          final planName = plan?.planName ?? sub.planId;
          final totalDays = sub.endDate.difference(sub.startDate).inDays;
          final now = DateTime.now();
          final daysRemaining = sub.endDate.isAfter(now)
              ? sub.endDate.difference(now).inDays
              : 0;
          final progress = totalDays > 0 ? 1 - (daysRemaining / totalDays) : 1.0;
          final statusColor = statusBorderColor(sub.status);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BottomSheetHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Subscription Detail',
                              style: Theme.of(ctx).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text('Customer: ${customer?.name ?? sub.customerId}'),
                            Text('Plan: $planName'),
                            Text('Status: ${sub.status}'),
                            Text('Auto renewal: ${sub.autoRenewal}'),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer?.name ?? sub.customerId,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sub.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${sub.startDate.day}/${sub.startDate.month}/${sub.startDate.year} - ${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BottomSheetHandle(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Subscription',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Customer'),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Plan'),
                  ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
    );
  }
}
