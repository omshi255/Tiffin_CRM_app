import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_label.dart';

class DashboardMoreScreen extends StatelessWidget {
  const DashboardMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionLabel(title: 'Account'),
        const SizedBox(height: 8),
        _MoreTile(
          icon: Icons.person_outline,
          title: 'Profile',
          onTap: () => context.push(AppRoutes.profile),
        ),
        _MoreTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(height: 24),
        const SectionLabel(title: 'Business'),
        const SizedBox(height: 8),
        _MoreTile(
          icon: Icons.payments_outlined,
          title: 'Payments',
          onTap: () => context.push(AppRoutes.payments),
        ),
        _MoreTile(
          icon: Icons.receipt_long_outlined,
          title: 'Invoices',
          onTap: () => context.push(AppRoutes.invoices),
        ),
        _MoreTile(
          icon: Icons.bar_chart_outlined,
          title: 'Reports',
          onTap: () => context.push(AppRoutes.reports),
        ),
        _MoreTile(
          icon: Icons.analytics_outlined,
          title: 'Analytics',
          onTap: () => context.push(AppRoutes.analytics),
        ),
        const SizedBox(height: 24),
        const SectionLabel(title: 'Meal plans'),
        const SizedBox(height: 8),
        _MoreTile(
          icon: Icons.restaurant_menu_outlined,
          title: 'Meal plans',
          onTap: () => context.push(AppRoutes.mealPlans),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
