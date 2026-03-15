import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../plans/data/plan_api.dart';
import '../../../plans/models/plan_model.dart';

class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await PlanApi.list(limit: 50, isActive: true);
      if (mounted) setState(() => _plans = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(PlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete ${plan.planName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await PlanApi.delete(plan.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan deleted')),
                  );
                  _load();
                }
              } catch (e) {
                if (mounted) ErrorHandler.show(context, e);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final globalPlans = _plans.where((p) => p.customerId == null || p.customerId!.isEmpty).toList();
    final customPlans = _plans.where((p) => p.customerId != null && p.customerId!.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SectionHeader(title: 'Global Plans'),
                  const SizedBox(height: 8),
                  ...globalPlans.map((plan) => _PlanCard(
                        plan: plan,
                        theme: theme,
                        onEdit: () async {
                          final updated = await context.push<bool?>(
                            AppRoutes.createPlan,
                            extra: plan,
                          );
                          if (updated == true && mounted) _load();
                        },
                        onDelete: () => _confirmDelete(plan),
                        onAssign: () {
                          context.push(AppRoutes.planAssignments, extra: plan);
                        },
                      )),
                  if (globalPlans.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No global plans',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Custom Plans'),
                  const SizedBox(height: 8),
                  ...customPlans.map((plan) => _PlanCard(
                        plan: plan,
                        theme: theme,
                        isCustom: true,
                        onEdit: () async {
                          final updated = await context.push<bool?>(
                            AppRoutes.createPlan,
                            extra: plan,
                          );
                          if (updated == true && mounted) _load();
                        },
                        onDelete: () => _confirmDelete(plan),
                        onAssign: () => context.push(AppRoutes.planAssignments, extra: plan),
                      )),
                  if (customPlans.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No custom plans',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool?>(AppRoutes.createPlan);
          if (created == true && mounted) _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.theme,
    this.isCustom = false,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  final PlanModel plan;
  final ThemeData theme;
  final bool isCustom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.planName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Custom',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '₹${plan.price.toStringAsFixed(0)} • ${plan.planType}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (plan.mealSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: plan.mealSlots
                    .map((s) => Chip(
                          label: Text(s.slot, style: theme.textTheme.labelSmall),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAssign,
                child: const Text('Assign to Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
