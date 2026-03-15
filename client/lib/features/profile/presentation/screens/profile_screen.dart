import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileApi.getMe();
      setState(() {
        _businessNameController.text =
            data['businessName'] as String? ??
            data['tiffinCenterName'] as String? ??
            '';
        _ownerNameController.text =
            data['name'] as String? ??
            data['ownerName'] as String? ??
            '';
        _phoneController.text = data['phone'] as String? ?? '';
        final address = data['address'];
        if (address is Map<String, dynamic>) {
          _addressController.text = address['street'] as String? ?? '';
          _cityController.text = address['city'] as String? ?? '';
          _pincodeController.text = address['pincode'] as String? ?? '';
        } else {
          _addressController.text = address as String? ?? '';
          _cityController.text = data['city'] as String? ?? '';
          _pincodeController.text = data['pincode'] as String? ?? '';
        }
      });
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ProfileApi.updateProfile({
        'businessName': _businessNameController.text.trim(),
        'name': _ownerNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _businessNameController.text.isEmpty
                                      ? 'Your Tiffin Center'
                                      : _businessNameController.text,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete your profile to get started',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _SectionLabel(label: 'Business Details'),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _businessNameController,
                      label: 'Tiffin Center / Business Name',
                      icon: Icons.storefront_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _ownerNameController,
                      label: 'Owner Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 28),

                    _SectionLabel(label: 'Address'),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _addressController,
                      label: 'Street Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _FormField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            controller: _pincodeController,
                            label: 'Pincode',
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}