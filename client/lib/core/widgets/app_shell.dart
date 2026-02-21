import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  static String _titleForPath(String path) {
    switch (path) {
      case '/dashboard':
        return 'Dashboard';
      case '/customers':
        return 'Customers';
      case '/meal-plans':
        return 'Meal Plans';
      case '/subscriptions':
        return 'Subscriptions';
      case '/delivery':
        return 'Deliveries';
      case '/payments':
        return 'Payments';
      case '/invoices':
        return 'Invoices';
      case '/reports':
        return 'Reports';
      case '/analytics':
        return 'Analytics';
      case '/settings':
        return 'Settings';
      default:
        return 'TiffinCRM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final path = state.uri.path;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: Drawer(child: AppDrawer()),
      appBar: AppBar(
        title: Text(
          _titleForPath(path),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: child,
    );
  }
}
