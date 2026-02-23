import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Deliveries'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'To Process'),
                const SizedBox(width: 8),
                _FilterChip(label: 'In Transit'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Delivered'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockDeliveries.length,
              itemBuilder: (context, index) {
                final d = mockDeliveries[index];
                final isLast = index == mockDeliveries.length - 1;
                final borderColor = statusBorderColor(d.status);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: borderColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.border,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
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
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Assign Delivery Boy',
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 16),
                                          const TextField(
                                            decoration: InputDecoration(
                                              labelText: 'Delivery person',
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx),
                                            child: const Text('Assign'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                  left: BorderSide(
                                    color: borderColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  d.customerName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.address,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      d.deliveryTime ?? '—',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        borderColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    d.status,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: borderColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.maps),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.map),
        label: const Text('View Map'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      onSelected: (bool value) {},
      label: Text(label),
    );
  }
}
