import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Root screen when no token. Role selection is navigation helper only;
/// actual role comes from backend on verify-otp.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Map<String, _RoleDef> _roles = {
    'vendor': _RoleDef(
      icon: Icons.store_rounded,
      title: 'Vendor',
      subtitle: 'Manage your\ntiffin business',
      color: AppColors.primary,
    ),
    'customer': _RoleDef(
      icon: Icons.person_rounded,
      title: 'Customer',
      subtitle: 'Order your\ndaily meals',
      color: AppColors.success,
    ),
    'delivery_staff': _RoleDef(
      icon: Icons.delivery_dining_rounded,
      title: 'Delivery',
      subtitle: 'Manage your\ndeliveries',
      color: AppColors.warning,
    ),
    'admin': _RoleDef(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Admin',
      subtitle: 'System\nadministration',
      color: AppColors.danger,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TiffinCRM',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your role to continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _roles.entries.map((e) {
                  return _RoleCard(
                    icon: e.value.icon,
                    title: e.value.title,
                    subtitle: e.value.subtitle,
                    roleColor: e.value.color,
                    onTap: () {
                      context.push(
                        AppRoutes.login,
                        extra: <String, String>{'selectedRole': e.key},
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleDef {
  const _RoleDef({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.roleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color roleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shadowColor: AppColors.shadow.withValues(alpha: 0.06),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: roleColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
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
