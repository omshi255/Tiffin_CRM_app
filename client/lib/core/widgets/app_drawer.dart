import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.fallbackUserName = 'Guest'});

  final String fallbackUserName;

  static const Color _drawerBackground = Color(0xFFFAFBFC);
  static const Color _drawerSurface = Color(0xFFF3F4F6);
  static const Color _drawerText = Color(0xFF1F2937);
  static const Color _drawerTextSecondary = Color(0xFF6B7280);
  static const Color _dividerColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      color: _drawerBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              userName: fallbackUserName,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile Info',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.profile);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.notifications);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.login,
                    label: 'iMeals (Customer Login)',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.login);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.groups_outlined,
                    label: 'Staff Management',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/staff-management');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.edit_note,
                    label: 'Standard Meal Plans',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.mealPlans);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history,
                    label: 'Recent Events',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/recent-events');
                    },
                  ),
                  const _DrawerDivider(),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.settings);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.upload_outlined,
                    label: 'Import Data',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/import-data');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.download_outlined,
                    label: 'Export Data',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/export-data');
                    },
                  ),
                  const _DrawerDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _drawerTextSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'Learn More',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/learn-more');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.share_outlined,
                    label: 'Share TiffinCRM App',
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share TiffinCRM App')),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.star_outline,
                    label: 'Rate This App!',
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rate This App!')),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.headset_mic_outlined,
                    label: 'Support',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/support');
                    },
                  ),
                  const _DrawerDivider(),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.userName, required this.onClose});

  final String userName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      color: AppDrawer._drawerBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDrawer._drawerSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppDrawer._drawerText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome to TiffinCRM',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppDrawer._drawerTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDrawer._drawerSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/tier-details');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 16,
                    color: AppDrawer._drawerTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Free Tier • 0/25 Orders Processed Today',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppDrawer._drawerTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppDrawer._drawerTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppDrawer._drawerText, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: AppDrawer._drawerText,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppDrawer._dividerColor,
      height: 24,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
