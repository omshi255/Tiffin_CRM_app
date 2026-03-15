import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../storage/secure_storage.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/profile/data/profile_api.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.fallbackUserName = 'Guest'});

  final String fallbackUserName;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const Color _drawerBackground = Color(0xFFFAFBFC);
  static const Color _drawerTextSecondary = Color(0xFF6B7280);

  String _businessName = '';
  String _ownerName = '';
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileApi.getMe();
      if (mounted) {
        setState(() {
          _businessName =
              data['businessName'] as String? ??
              data['tiffinCenterName'] as String? ??
              '';
          _ownerName =
              data['name'] as String? ??
              data['ownerName'] as String? ??
              widget.fallbackUserName;
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _businessName.isNotEmpty
        ? _businessName
        : (_ownerName.isNotEmpty ? _ownerName : widget.fallbackUserName);

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      color: _drawerBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              businessName: displayName,
              ownerName: _ownerName,
              profileLoaded: _profileLoaded,
              onClose: () => Navigator.of(context).pop(),
              onProfileTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile).then((_) => _loadProfile());
              },
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
                      context
                          .push(AppRoutes.profile)
                          .then((_) => _loadProfile());
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
                    icon: Icons.receipt_long_outlined,
                    label: 'Daily Orders',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.delivery);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.groups_outlined,
                    label: 'Delivery Staff',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.deliveryStaff);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.restaurant_menu,
                    label: 'Menu Items',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.items);
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
                    onTap: () async {
                      Navigator.of(context).pop();
                      await AuthApi.logout();
                      await SecureStorage.clearAll();
                      if (context.mounted) context.go(AppRoutes.login);
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
  const _DrawerHeader({
    required this.businessName,
    required this.ownerName,
    required this.profileLoaded,
    required this.onClose,
    required this.onProfileTap,
  });

  final String businessName;
  final String ownerName;
  final bool profileLoaded;
  final VoidCallback onClose;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      color: const Color(0xFFFAFBFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !profileLoaded
                          ? Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : Text(
                              businessName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        ownerName.isNotEmpty
                            ? ownerName
                            : 'Tap to complete profile',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
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
                  const Icon(
                    Icons.radio_button_unchecked,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Free Tier • 0/25 Orders Processed Today',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF6B7280),
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
      leading: Icon(icon, color: const Color(0xFF1F2937), size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1F2937),
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
    return const Divider(
      color: Color(0xFFE5E7EB),
      height: 24,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
