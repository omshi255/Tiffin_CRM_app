import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../../core/widgets/stat_card.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Welcome back',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s your overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.people_outline,
                        label: 'Customers',
                        value: '0',
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.customers),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StatCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Active plans',
                        value: '0',
                        color: AppColors.secondary,
                        onTap: () => context.push(AppRoutes.subscriptions),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.local_shipping_outlined,
                        label: 'Today\'s delivery',
                        value: '0',
                        color: AppColors.tertiary,
                        onTap: () => context.push(AppRoutes.delivery),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StatCard(
                        icon: Icons.payments_outlined,
                        label: 'Pending amount',
                        value: '\u20B90',
                        color: AppColors.success,
                        onTap: () => context.push(AppRoutes.payments),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Quick actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                QuickActionTile(
                  icon: Icons.person_add_outlined,
                  title: 'Add customer',
                  subtitle: 'Register a new customer',
                  onTap: () => context.push(AppRoutes.customers),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'New subscription',
                  subtitle: 'Create a meal plan subscription',
                  onTap: () => context.push(AppRoutes.subscriptions),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  icon: Icons.route_outlined,
                  title: 'Delivery routes',
                  subtitle: 'View and manage today\'s deliveries',
                  onTap: () => context.push(AppRoutes.delivery),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Payments & invoices',
                  subtitle: 'Collect payments and generate invoices',
                  onTap: () => context.push(AppRoutes.payments),
                ),
              ]),
            ),
          ),
        ],
    );
  }
}
