import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const _SectionLabel(title: 'ACCOUNT'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Admin / User profile',
            onTap: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(title: 'BUSINESS'),
          _SettingsTile(
            icon: Icons.business_outlined,
            title: 'Business profile',
            onTap: () => context.push(AppRoutes.businessProfile),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Invoice settings',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          const _SectionLabel(title: 'GENERAL'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          const _SectionLabel(title: 'DATA'),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup & restore',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusExpired,
              side: const BorderSide(color: AppColors.statusExpired),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
