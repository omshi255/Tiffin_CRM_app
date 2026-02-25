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
            childAspectRatio: 1.15,
            children: [
              _StatCard(
                title: 'Total Customers',
                value: '${summary.totalCustomers}',
                icon: Icons.people,
                accentColor: AppColors.primary,
              ),
              _StatCard(
                title: 'Total Subscriptions',
                value: '${summary.activeSubscriptions}',
                icon: Icons.subscriptions,
                accentColor: AppColors.secondary,
              ),
              _StatCard(
                title: 'Pending Deliveries',
                value: '${summary.pendingDeliveries}',
                icon: Icons.delivery_dining,
                accentColor: AppColors.warning,
              ),
              _StatCard(
                title: 'Revenue',
                value: '${summary.dailyRevenue.toInt()}',
                icon: Icons.currency_rupee,
                accentColor: AppColors.success,
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

class _StatCard extends StatefulWidget {
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
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = double.tryParse(widget.value) ?? 0;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 30, color: widget.accentColor),
              const SizedBox(height: 10),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: number),
                duration: const Duration(milliseconds: 900),
                builder: (context, value, child) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),

              Text(
                widget.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
