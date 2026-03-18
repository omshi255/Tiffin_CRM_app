// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/theme/app_colors.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key, required this.phone});

//   final String phone;

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> {
//   final _otpController = TextEditingController();
//   bool _isVerifying = false;

//   @override
//   void dispose() {
//     _otpController.dispose();
//     super.dispose();
//   }

//   Future<void> _verify() async {
//     final otp = _otpController.text.trim();
//     if (otp.length < 4) return;
//     setState(() => _isVerifying = true);
//     await Future.delayed(const Duration(milliseconds: 600));
//     if (!mounted) return;
//     setState(() => _isVerifying = false);
//     context.go(AppRoutes.dashboard);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: theme.colorScheme.surface,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
//           onPressed: _isVerifying ? null : () => context.pop(),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 8),
//               Text(
//                 'Verify OTP',
//                 style: theme.textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.onSurface,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Code sent to ${widget.phone}',
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                   color: theme.colorScheme.onSurfaceVariant,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               TextFormField(
//                 controller: _otpController,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter 4-digit OTP',
//                   hintText: '0000',
//                 ),
//                 keyboardType: TextInputType.number,
//                 maxLength: 4,
//               ),
//               const SizedBox(height: 24),
//               FilledButton(
//                 onPressed: _isVerifying ? null : _verify,
//                 style: FilledButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: AppColors.onPrimary,
//                 ),
//                 child: _isVerifying
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Verify'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/auth_api.dart';
import '../../models/user_model.dart';
import '../../../customer_portal/data/customer_portal_api.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, this.selectedRole = 'vendor'});

  final String phone;
  final String selectedRole;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  int _seconds = 30;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateFcmToken(String role) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        if (role == 'customer') {
          await CustomerPortalApi.updateMyProfile({'fcmToken': token});
        } else {
          await AuthApi.updateProfile({'fcmToken': token});
        }
      }
    } catch (_) {}
  }

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError("Enter 6 digit OTP");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await AuthApi.verifyOtp(widget.phone, otp);

      await SecureStorage.saveAccessToken(response.accessToken);
      await SecureStorage.saveRefreshToken(response.refreshToken);
      final user = response.user;
      final role = user.role;
      await SecureStorage.saveUserRole(role);
      await SecureStorage.saveUserId(user.id);

      await _updateFcmToken(role);

      if (!mounted) return;
      setState(() => _isVerifying = false);

      await _navigateAfterLogin(context, user);
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ErrorHandler.show(context, e);
      }
    }
  }

  Future<void> _navigateAfterLogin(BuildContext context, UserModel user) async {
    final role = user.role;
    if (role == 'vendor') {
      // Source of truth: GET /auth/me (login payload can omit or stale-fill profile fields).
      UserModel profile;
      try {
        profile = await AuthApi.getProfile();
      } catch (_) {
        profile = user;
      }
      if (!context.mounted) return;
      if (!profile.isVendorProfileComplete) {
        context.go(AppRoutes.vendorOnboarding, extra: widget.phone);
      } else {
        context.go(AppRoutes.dashboard);
      }
      return;
    }
    if (!context.mounted) return;
    switch (role) {
      case 'customer':
        context.go(AppRoutes.customerHome);
        break;
      case 'delivery_staff':
        context.go(AppRoutes.deliveryDashboard);
        break;
      case 'admin':
        context.go(AppRoutes.adminDashboard);
        break;
      default:
        context.go(AppRoutes.dashboard);
    }
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "Verify OTP",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "OTP sent to +91 ${widget.phone}",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: "------",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isVerifying ? null : verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Verify OTP"),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: _seconds == 0
                  ? () {
                      startTimer();
                    }
                  : null,
              child: Text(
                _seconds == 0 ? "Resend OTP" : "Resend in $_seconds sec",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
