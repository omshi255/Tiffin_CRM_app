import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.selectedRole = 'vendor'});

  final String selectedRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = value?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
    if (v.isEmpty) return "Mobile number required";
    if (v.length != 10) return "Enter 10 digit number";
    if (!_phoneRegex.hasMatch(v)) return "Invalid mobile number";
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) return;

    setState(() => _isLoading = true);

    try {
      await AuthApi.sendOtp(phone);
      if (!mounted) return;
      context.push(
        AppRoutes.otp,
        extra: <String, String>{
          'phone': phone,
          'selectedRole': widget.selectedRole,
        },
      );
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),

              /// Role badge (navigation helper only; backend sets actual role)
              _RoleBadge(selectedRole: widget.selectedRole),
              const SizedBox(height: 20),

              /// LOGO
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 700),
                tween: Tween(begin: 0.85, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      "assets/images/app_logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "Get started ",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Login using your mobile number",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 36),

              /// LOGIN CARD
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// PHONE FIELD
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: _validatePhone,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          prefixText: "+91  ",
                          counterText: "",
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Send OTP",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              /// TRUECALLER
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.truecaller),
                  style:
                      OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          Colors.grey.withValues(alpha: 0.08),
                        ),
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TRUECALLER WEBP LOGO
                      Image.asset(
                        "assets/images/truecaller.webp",
                        height: 40,
                        width: 40,
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        "Continue with Truecaller",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "By continuing you agree to Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.selectedRole});

  final String selectedRole;

  static IconData _icon(String role) {
    switch (role) {
      case 'customer':
        return Icons.person_rounded;
      case 'delivery_staff':
        return Icons.delivery_dining_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  static String _title(String role) {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'delivery_staff':
        return 'Delivery';
      case 'admin':
        return 'Admin';
      default:
        return 'Vendor';
    }
  }

  static Color _color(String role) {
    switch (role) {
      case 'customer':
        return AppColors.success;
      case 'delivery_staff':
        return AppColors.warning;
      case 'admin':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _color(selectedRole);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(selectedRole), size: 16, color: roleColor),
          const SizedBox(width: 6),
          Text(
            'Logging in as ${_title(selectedRole)}',
            style: theme.textTheme.labelMedium?.copyWith(color: roleColor),
          ),
        ],
      ),
    );
  }
}
