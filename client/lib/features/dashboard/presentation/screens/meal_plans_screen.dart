import 'package:flutter/material.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/theme/app_colors.dart';

class MealPlansScreen extends StatelessWidget {
  const MealPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockMealPlans.length,
        itemBuilder: (context, index) {
          final plan = mockMealPlans[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(plan.planName),
              subtitle: Text(
                '${plan.mealsType} • ₹${plan.price.toStringAsFixed(0)}/mo',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              trailing: Chip(
                label: Text(
                  plan.status,
                  style: theme.textTheme.labelSmall,
                ),
                backgroundColor: plan.status == 'active'
                    ? AppColors.secondaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Meal Plan',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Plan name'),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Meals type'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
