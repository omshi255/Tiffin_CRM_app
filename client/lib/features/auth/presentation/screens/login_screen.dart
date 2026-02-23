import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = value?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
    if (v.isEmpty) return 'Enter your mobile number';
    if (v.length != 10) return 'Mobile number must be 10 digits';
    if (!_phoneRegex.hasMatch(v)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) return;
    // API_INTEGRATION
    // Endpoint: POST /api/auth/login
    // Purpose: Send OTP to phone number
    // Request: { phone: String }
    // Response: { success: bool, message: String }
    context.push(AppRoutes.otp, extra: '+91 $phone');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to TiffinCRM',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your mobile number to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '10-digit number',
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _sendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Send OTP'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.truecaller),
                  icon: const Icon(Icons.phone),
                  label: const Text('Truecaller'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.googleLogin),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Google'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.facebookLogin),
                  icon: const Icon(Icons.facebook),
                  label: const Text('Facebook'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
