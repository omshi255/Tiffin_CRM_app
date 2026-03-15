import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/data/auth_api.dart';
import '../../../auth/models/user_model.dart';
import '../../data/delivery_api.dart';
import '../../../../core/router/app_routes.dart';
import 'package:go_router/go_router.dart';

class DeliveryProfileScreen extends StatefulWidget {
  const DeliveryProfileScreen({super.key});

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _updatingActive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AuthApi.getProfile();
      if (mounted) setState(() => _user = user);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setActive(bool value) async {
    setState(() => _updatingActive = true);
    try {
      await DeliveryApi.updateMe({'isActive': value});
      if (mounted) {
        setState(() => _user = _user != null
            ? UserModel(
                id: _user!.id,
                phone: _user!.phone,
                role: _user!.role,
                name: _user!.name,
                businessName: _user!.businessName,
                email: _user!.email,
                logoUrl: _user!.logoUrl,
                isActive: value,
                fcmToken: _user!.fcmToken,
              )
            : null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'You are active' : 'You are inactive')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _updatingActive = false);
    }
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    await SecureStorage.clearAll();
    if (!mounted) return;
    GoRouter.of(context).go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final u = _user;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'My Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (u != null) ...[
                    _ProfileRow(
                      label: 'Name',
                      value: u.name.isEmpty ? '—' : u.name,
                    ),
                    const SizedBox(height: 12),
                    _ProfileRow(
                      label: 'Phone',
                      value: u.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_updatingActive)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Switch(
                            value: u.isActive,
                            onChanged: _setActive,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
