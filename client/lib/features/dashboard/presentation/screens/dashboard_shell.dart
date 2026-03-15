import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/data/auth_api.dart';
import '../../../auth/models/user_model.dart';
import '../../../customers/presentation/screens/customers_list_screen.dart';
import 'dashboard_home_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, this.adminName = 'Vendor'});

  final String adminName;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  String _vendorDisplayName = 'Vendor';
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  Future<void> _loadVendorProfile() async {
    try {
      final user = await AuthApi.getProfile();
      if (mounted) {
        setState(() {
          _vendorDisplayName = _displayNameFromUser(user);
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _vendorDisplayName = widget.adminName;
          _profileLoaded = true;
        });
      }
    }
  }

  static String _displayNameFromUser(UserModel user) {
    if (user.businessName.isNotEmpty) return user.businessName;
    if (user.name.isNotEmpty) return user.name;
    return 'Vendor';
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Overview'),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    _NavItem(icon: Icons.people_outline, label: 'Customers'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: Text(_profileLoaded ? _vendorDisplayName : 'TiffinCRM'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      drawer: Drawer(
        child: AppDrawer(fallbackUserName: _vendorDisplayName),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardHomeScreen(adminName: _vendorDisplayName),
          const _TabPlaceholder(label: 'Orders'),
          const CustomersListScreen(),
          const _TabPlaceholder(label: 'Finance'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        items: _navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
