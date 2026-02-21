import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/google_login_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/truecaller_screen.dart';
import '../../features/customers/data/customer_model.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_shell.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'app_routes.dart';

final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static GlobalKey<NavigatorState> get rootKey => _rootKey;

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.onboarding,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Splash'),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.truecaller,
        name: 'truecaller',
        builder: (_, __) => const TruecallerScreen(),
      ),
      GoRoute(
        path: AppRoutes.googleLogin,
        name: 'googleLogin',
        builder: (_, __) => const GoogleLoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, state) {
          if (state.uri.path == '/' || state.uri.path.isEmpty) return AppRoutes.dashboard;
          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'dashboard',
            name: 'dashboard',
            builder: (_, __) => const DashboardShell(),
          ),
          GoRoute(
            path: 'customers',
            name: 'customers',
            builder: (_, __) => const CustomersListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'addCustomer',
                builder: (_, __) => const AddEditCustomerScreen(),
              ),
              GoRoute(
                path: 'edit',
                name: 'editCustomer',
                builder: (context, state) {
                  final customer = state.extra as Customer?;
                  if (customer == null) {
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'Customer not found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    );
                  }
                  return AddEditCustomerScreen(customer: customer);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meal-plans',
            name: 'mealPlans',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Meal Plans'),
          ),
          GoRoute(
            path: 'subscriptions',
            name: 'subscriptions',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Subscriptions'),
          ),
          GoRoute(
            path: 'delivery',
            name: 'delivery',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Deliveries'),
          ),
          GoRoute(
            path: 'payments',
            name: 'payments',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Payments'),
          ),
          GoRoute(
            path: 'invoices',
            name: 'invoices',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Invoices'),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Reports'),
          ),
          GoRoute(
            path: 'analytics',
            name: 'analytics',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Analytics'),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Settings'),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Profile'),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Notifications'),
          ),
          GoRoute(
            path: 'staff-management',
            name: 'staffManagement',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Staff Management'),
          ),
          GoRoute(
            path: 'recent-events',
            name: 'recentEvents',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Recent Events'),
          ),
          GoRoute(
            path: 'import-data',
            name: 'importData',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Import Data'),
          ),
          GoRoute(
            path: 'export-data',
            name: 'exportData',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Export Data'),
          ),
          GoRoute(
            path: 'learn-more',
            name: 'learnMore',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Learn More'),
          ),
          GoRoute(
            path: 'support',
            name: 'support',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Support'),
          ),
          GoRoute(
            path: 'tier-details',
            name: 'tierDetails',
            builder: (_, __) => const _PlaceholderScreen(routeLabel: 'Tier Details'),
          ),
        ],
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.routeLabel});

  final String routeLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeLabel)),
      body: Center(
        child: Text(routeLabel, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
