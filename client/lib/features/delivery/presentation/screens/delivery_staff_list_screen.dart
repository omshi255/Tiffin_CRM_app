import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/delivery_api.dart';
import '../../models/delivery_staff_model.dart';

class DeliveryStaffListScreen extends StatefulWidget {
  const DeliveryStaffListScreen({super.key});

  @override
  State<DeliveryStaffListScreen> createState() => _DeliveryStaffListScreenState();
}

class _DeliveryStaffListScreenState extends State<DeliveryStaffListScreen> {
  List<DeliveryStaffModel> _staff = [];
  bool _loading = true;
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await DeliveryApi.listStaff(
        limit: 100,
        isActive: _activeOnly ? true : null,
      );
      if (mounted) setState(() => _staff = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirmDelete(DeliveryStaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove staff'),
        content: Text('Remove ${staff.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DeliveryApi.deleteStaff(staff.id);
                if (mounted) {
                  AppSnackbar.success(context, 'Removed');
                  _load();
                }
              } catch (e) {
                if (mounted) ErrorHandler.show(context, e);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Staff'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_activeOnly ? 'Active only' : 'All'),
              selected: _activeOnly,
              onSelected: (_) {
                setState(() {
                  _activeOnly = !_activeOnly;
                  _load();
                });
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _staff.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 48),
                        Center(
                          child: Text(
                            'No delivery staff',
                            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _staff.length,
                      itemBuilder: (context, index) {
                        final s = _staff[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              s.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.phone, style: theme.textTheme.bodySmall),
                                if (s.areas.isNotEmpty)
                                  Text(
                                    s.areas.join(', '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: s.isActive,
                                  onChanged: (v) async {
                                    try {
                                      await DeliveryApi.updateStaff(s.id, {'isActive': v});
                                      if (!context.mounted) return;
                                      _load();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ErrorHandler.show(context, e);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    final updated = await context.push<bool?>(
                                      AppRoutes.editDeliveryStaff,
                                      extra: s,
                                    );
                                    if (updated == true && mounted) _load();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  tooltip: 'Track on Map',
                                  onPressed: () => context.push(AppRoutes.maps, extra: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(s),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool?>(AppRoutes.addDeliveryStaff);
          if (created == true && mounted) _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
