import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/admin_api.dart';
import '../../models/admin_stats_model.dart';
import 'admin_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.onListTap,
    this.onReportsTap,
  });
  final void Function(AdminListType type)? onListTap;
  final VoidCallback? onReportsTap;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStatsModel? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await AdminApi.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    await AuthApi.logout();
    await SecureStorage.clearAll();
    if (!mounted) return;
    router.go(AppRoutes.roleSelection);
  }

  void _navigateToList(AdminListType type) {
    if (widget.onListTap != null) {
      widget.onListTap!(type);
    } else {
      context.push(AppRoutes.adminList, extra: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
          PopupMenuButton<void>(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
              ),
            ],
            onSelected: (_) => _logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: 'Overview'),
                    const SizedBox(height: 8),
                    if (s != null)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _StatCard(
                            title: 'Vendors',
                            value: '${s.totalVendors}',
                            icon: Icons.store,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            title: 'Customers',
                            value: '${s.totalCustomers}',
                            icon: Icons.people,
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            title: 'Orders',
                            value: '${s.totalOrders}',
                            icon: Icons.receipt_long,
                            color: AppColors.warning,
                          ),
                          _StatCard(
                            title: 'Revenue',
                            value: '₹${s.totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            color: AppColors.success,
                          ),
                          _StatCard(
                            title: "Today's orders",
                            value: '${s.todayOrders}',
                            icon: Icons.today,
                            color: AppColors.tertiary,
                          ),
                          _StatCard(
                            title: "Today's revenue",
                            value: '₹${s.todayRevenue.toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                          _StatCard(
                            title: 'Active plans',
                            value: '${s.activeSubscriptions}',
                            icon: Icons.assignment,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            title: 'Pending orders',
                            value: '${s.pendingOrders}',
                            icon: Icons.pending_actions,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Lists'),
                    const SizedBox(height: 8),
                    _ListTile(
                      icon: Icons.store,
                      label: 'Vendors',
                      onTap: () => _navigateToList(AdminListType.vendors),
                    ),
                    _ListTile(
                      icon: Icons.people,
                      label: 'Customers',
                      onTap: () => _navigateToList(AdminListType.customers),
                    ),
                    _ListTile(
                      icon: Icons.delivery_dining,
                      label: 'Delivery staff',
                      onTap: () => _navigateToList(AdminListType.deliveryStaff),
                    ),
                    _ListTile(
                      icon: Icons.edit_note,
                      label: 'Plans',
                      onTap: () => _navigateToList(AdminListType.plans),
                    ),
                    _ListTile(
                      icon: Icons.restaurant_menu,
                      label: 'Items',
                      onTap: () => _navigateToList(AdminListType.items),
                    ),
                    _ListTile(
                      icon: Icons.assignment,
                      label: 'Plan assignments',
                      onTap: () => _navigateToList(AdminListType.subscriptions),
                    ),
                    _ListTile(
                      icon: Icons.receipt_long,
                      label: 'Orders',
                      onTap: () => _navigateToList(AdminListType.orders),
                    ),
                    if (widget.onReportsTap != null)
                      _ListTile(
                        icon: Icons.assessment,
                        label: 'Reports',
                        onTap: widget.onReportsTap!,
                      ),
                    _ListTile(
                      icon: Icons.payment,
                      label: 'Payments',
                      onTap: () => _navigateToList(AdminListType.payments),
                    ),
                    _ListTile(
                      icon: Icons.description,
                      label: 'Invoices',
                      onTap: () => _navigateToList(AdminListType.invoices),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
