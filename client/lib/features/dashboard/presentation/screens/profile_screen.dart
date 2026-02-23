import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  'U',
                  style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin User',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '+91 9876543210',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
