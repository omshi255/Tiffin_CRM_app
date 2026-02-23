import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../transitions/page_transitions.dart';
import '../../features/auth/presentation/screens/facebook_login_screen.dart';
import '../../features/auth/presentation/screens/google_login_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/truecaller_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/dashboard/presentation/screens/business_profile_screen.dart';
import '../../features/dashboard/presentation/screens/delivery_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_shell.dart';
import '../../features/dashboard/presentation/screens/invoices_screen.dart';
import '../../features/dashboard/presentation/screens/maps_screen.dart';
import '../../features/dashboard/presentation/screens/meal_plans_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/dashboard/presentation/screens/payments_screen.dart';
import '../../features/dashboard/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/reports_screen.dart';
import '../../features/dashboard/presentation/screens/settings_screen.dart';
import '../../features/dashboard/presentation/screens/subscriptions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../models/customer_model.dart';
import 'app_routes.dart';

final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter get router => _router;
  static final GoRouter _router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.onboarding,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => _PlaceholderScreen(routeLabel: 'Splash'),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String?;
          return OtpScreen(phone: phone ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.truecaller,
        name: 'truecaller',
        builder: (context, state) => const TruecallerScreen(),
      ),
      GoRoute(
        path: AppRoutes.googleLogin,
        name: 'googleLogin',
        builder: (context, state) => const GoogleLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.facebookLogin,
        name: 'facebookLogin',
        builder: (context, state) => const FacebookLoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) {
          if (state.uri.path == '/' || state.uri.path.isEmpty) {
            return AppRoutes.dashboard;
          }
          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const DashboardShell()),
          ),
          GoRoute(
            path: 'customers',
            name: 'customers',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const CustomersListScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'add',
                name: 'addCustomer',
                pageBuilder: (context, state) =>
                    slideTransitionPage(state, const AddEditCustomerScreen()),
              ),
              GoRoute(
                path: 'detail',
                name: 'customerDetail',
                pageBuilder: (context, state) {
                  final customer = state.extra as CustomerModel?;
                  final child = customer == null
                      ? Scaffold(
                          body: Center(
                            child: Builder(
                              builder: (ctx) => Text(
                                'Customer not found',
                                style: Theme.of(ctx).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        )
                      : CustomerDetailScreen(customer: customer);
                  return slideTransitionPage(state, child);
                },
              ),
              GoRoute(
                path: 'edit',
                name: 'editCustomer',
                pageBuilder: (context, state) {
                  final customer = state.extra as CustomerModel?;
                  final child = customer == null
                      ? Scaffold(
                          body: Center(
                            child: Builder(
                              builder: (ctx) => Text(
                                'Customer not found',
                                style: Theme.of(ctx).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        )
                      : AddEditCustomerScreen(customer: customer);
                  return slideTransitionPage(state, child);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meal-plans',
            name: 'mealPlans',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const MealPlansScreen()),
          ),
          GoRoute(
            path: 'subscriptions',
            name: 'subscriptions',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const SubscriptionsScreen()),
          ),
          GoRoute(
            path: 'delivery',
            name: 'delivery',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const DeliveryScreen()),
          ),
          GoRoute(
            path: 'payments',
            name: 'payments',
            pageBuilder: (context, state) =>
                slideTransitionPage(state, const PaymentsScreen()),
          ),
          GoRoute(
            path: 'invoices',
            name: 'invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'analytics',
            name: 'analytics',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'business-profile',
            name: 'businessProfile',
            builder: (context, state) => const BusinessProfileScreen(),
          ),
          GoRoute(
            path: 'maps',
            name: 'maps',
            builder: (context, state) => const MapsScreen(),
          ),
          GoRoute(
            path: 'staff-management',
            name: 'staffManagement',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Staff Management'),
          ),
          GoRoute(
            path: 'recent-events',
            name: 'recentEvents',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Recent Events'),
          ),
          GoRoute(
            path: 'import-data',
            name: 'importData',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Import Data'),
          ),
          GoRoute(
            path: 'export-data',
            name: 'exportData',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Export Data'),
          ),
          GoRoute(
            path: 'learn-more',
            name: 'learnMore',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Learn More'),
          ),
          GoRoute(
            path: 'support',
            name: 'support',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Support'),
          ),
          GoRoute(
            path: 'tier-details',
            name: 'tierDetails',
            builder: (context, state) => _PlaceholderScreen(routeLabel: 'Tier Details'),
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
