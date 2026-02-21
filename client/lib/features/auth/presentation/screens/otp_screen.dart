import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/otp_input_field.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.phone});

  final String? phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  String _otp = '';
  bool _isVerifying = false;
  String? _otpError;
  int _resendSeconds = 30;
  Timer? _timer;
  bool _autoVerifyTriggered = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const int _otpLength = 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    if (widget.phone == null || widget.phone!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return;
    }
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  void _resendOtp() {
    if (_resendSeconds > 0) return;
    setState(() => _otpError = null);
    _startResendTimer();
    showAuthSuccess(context, 'OTP resent to +91 ${widget.phone}');
  }

  bool get _isOtpValid => _otp.length == _otpLength;

  Future<void> _verify() async {
    setState(() => _otpError = null);
    if (_otp.length != _otpLength) {
      setState(() => _otpError = 'Enter the 6-digit code');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isVerifying = false);
    await showAuthSuccessDialog(context, 'Signed in successfully');
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = widget.phone ?? '';

    if (phone.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: _isVerifying ? null : () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Verify OTP',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit code to +91 $phone',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _isVerifying ? null : () => context.pop(),
                  child: Text(
                    'Change number',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                OtpInputField(
                  length: _otpLength,
                  enabled: !_isVerifying,
                  onChanged: (v) {
                    setState(() {
                      _otp = v;
                      _otpError = null;
                      if (v.length == _otpLength && !_autoVerifyTriggered) {
                        _autoVerifyTriggered = true;
                        Future.microtask(() => _verify());
                      }
                      if (v.length < _otpLength) _autoVerifyTriggered = false;
                    });
                  },
                  onComplete: () => setState(() {}),
                ),
                if (_otpError != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 6),
                      Text(
                        _otpError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                AuthPrimaryButton(
                  label: 'Verify',
                  loading: _isVerifying,
                  loadingLabel: 'Verifying…',
                  onPressed: _isVerifying || !_isOtpValid ? null : _verify,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: (_resendSeconds > 0 || _isVerifying) ? null : _resendOtp,
                    child: Text(
                      _resendSeconds > 0
                          ? 'Resend code in ${_resendSeconds}s'
                          : 'Resend code',
                      style: TextStyle(
                        color: _resendSeconds > 0
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
