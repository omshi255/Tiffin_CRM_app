import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key, this.adminName = 'Admin'});

  final String adminName;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = mockReportsData;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_greeting()}, $adminName 👋',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Overview'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                title: 'Active subscriptions',
                value: '${summary.activeSubscriptions}',
                icon: Icons.subscriptions,
                accentColor: AppColors.primary,
              ),
              _StatCard(
                title: 'Pending deliveries',
                value: '${summary.pendingDeliveries}',
                icon: Icons.delivery_dining,
                accentColor: AppColors.secondary,
              ),
              _StatCard(
                title: 'Today\'s revenue',
                value: '₹${summary.dailyRevenue.toStringAsFixed(0)}',
                icon: Icons.currency_rupee,
                accentColor: AppColors.success,
              ),
              _StatCard(
                title: 'Overdue payments',
                value: '${summary.overduePayments}',
                icon: Icons.warning_amber,
                accentColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.person_add,
                  label: 'Add Customer',
                  onTap: () => context.push(AppRoutes.addCustomer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.receipt_long,
                  label: 'Subscriptions',
                  onTap: () => context.push(AppRoutes.subscriptions),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.delivery_dining,
                  label: 'Delivery',
                  onTap: () => context.push(AppRoutes.delivery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.payment,
                  label: 'Payments',
                  onTap: () => context.push(AppRoutes.payments),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent activity'),
          const SizedBox(height: 12),
          ...mockRecentActivity.map(
            (e) => Card(
              child: ListTile(
                title: Text(e['label']!),
                subtitle: Text(e['subtitle']!),
                trailing: Text(
                  e['time']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: accentColor, width: 3),
          left: const BorderSide(color: AppColors.border, width: 1),
          right: const BorderSide(color: AppColors.border, width: 1),
          bottom: const BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: accentColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
