// import 'dart:async';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/notifications/notification_badge_service.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/storage/secure_storage.dart';
// import '../../../../core/utils/app_snackbar.dart';
// import '../../../../core/utils/error_handler.dart';
// import '../../data/auth_api.dart';
// import '../../models/user_model.dart';
// import '../../../customer_portal/data/customer_portal_api.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key, required this.phone, this.selectedRole = 'vendor'});

//   final String phone;
//   final String selectedRole;

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
//   final _otpController = TextEditingController();
//   int _seconds = 30;
//   Timer? _timer;
//   bool _isVerifying = false;

//   @override
//   void initState() {
//     super.initState();
//     startTimer();
//   }

//   void startTimer() {
//     _seconds = 30;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_seconds == 0) {
//         timer.cancel();
//       } else {
//         setState(() => _seconds--);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _otpController.dispose();
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> _updateFcmToken(String role) async {
//     try {
//       final token = await FirebaseMessaging.instance.getToken();
//       if (token != null && token.isNotEmpty) {
//         if (role == 'customer') {
//           await CustomerPortalApi.updateMyProfile({'fcmToken': token});
//         } else {
//           await AuthApi.updateProfile({'fcmToken': token});
//         }
//       }
//     } catch (_) {}
//   }

//   Future<void> verifyOtp() async {
//     final otp = _otpController.text.trim();
//     if (otp.length != 6) {
//       _showError("Enter 6 digit OTP");
//       return;
//     }

//     setState(() => _isVerifying = true);

//     try {
//       final response = await AuthApi.verifyOtp(widget.phone, otp);

//       await SecureStorage.saveAccessToken(response.accessToken);
//       await SecureStorage.saveRefreshToken(response.refreshToken);
//       final user = response.user;
//       final role = user.role;
//       await SecureStorage.saveUserRole(role);
//       await SecureStorage.saveUserId(user.id);

//       await NotificationBadgeService.refreshNow();

//       await _updateFcmToken(role);

//       if (!mounted) return;
//       setState(() => _isVerifying = false);

//       await _navigateAfterLogin(context, user);
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isVerifying = false);
//         ErrorHandler.show(context, e);
//       }
//     }
//   }

//   Future<void> _navigateAfterLogin(BuildContext context, UserModel user) async {
//     final role = user.role;
//     if (role == 'vendor') {
//       // Source of truth: GET /auth/me (login payload can omit or stale-fill profile fields).
//       UserModel profile;
//       try {
//         profile = await AuthApi.getProfile();
//       } catch (_) {
//         profile = user;
//       }
//       if (!context.mounted) return;
//       if (!profile.isVendorProfileComplete) {
//         context.go(AppRoutes.vendorOnboarding, extra: widget.phone);
//       } else {
//         context.go(AppRoutes.dashboard);
//       }
//       return;
//     }
//     if (!context.mounted) return;
//     switch (role) {
//       case 'customer':
//         context.go(AppRoutes.customerHome);
//         break;
//       case 'delivery_staff':
//         context.go(AppRoutes.deliveryDashboard);
//         break;
//       case 'admin':
//         context.go(AppRoutes.adminDashboard);
//         break;
//       default:
//         context.go(AppRoutes.dashboard);
//     }
//   }

//   void _showError(String msg) {
//     AppSnackbar.error(context, msg);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const SizedBox(height: 40),
//             Text(
//               "Verify OTP",
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 10),
//             Text(
//               "OTP sent to +91 ${widget.phone}",
//               style: theme.textTheme.bodyMedium,
//             ),

//             const SizedBox(height: 40),

//             TextField(
//               controller: _otpController,
//               keyboardType: TextInputType.number,
//               maxLength: 6,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 22, letterSpacing: 8),
//               decoration: InputDecoration(
//                 hintText: "------",
//                 counterText: "",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: _isVerifying ? null : verifyOtp,
//                 child: _isVerifying
//                     ? const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Text("Verify OTP"),
//               ),
//             ),

//             const SizedBox(height: 20),

//             TextButton(
//               onPressed: _seconds == 0
//                   ? () {
//                       startTimer();
//                     }
//                   : null,
//               child: Text(
//                 _seconds == 0 ? "Resend OTP" : "Resend in $_seconds sec",
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_badge_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/auth_api.dart';
import '../../models/user_model.dart';
import '../../../customer_portal/data/customer_portal_api.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.selectedRole = 'vendor',
  });

  final String phone;
  final String selectedRole;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  // ── ORIGINAL: single controller kept, UI splits into 6 boxes visually
  final _otpController = TextEditingController();

  // 6 individual controllers + focus nodes for the new UI
  final List<TextEditingController> _boxControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _seconds = 60; // ← changed to 60 (1 min) as requested
  Timer? _timer;
  bool _isVerifying = false;
  int _filledCount = 0;

  // ── Role helpers ─────────────────────────────────────────────
  Color get _roleColor {
    switch (widget.selectedRole) {
      case 'customer':
        return const Color(0xFF1D9E75);
      case 'delivery_staff':
        return const Color(0xFFBA7517);
      case 'admin':
        return const Color(0xFFA32D2D);
      default:
        return const Color(0xFF5B2D8E);
    }
  }

  List<Color> get _roleGradient {
    switch (widget.selectedRole) {
      case 'customer':
        return [const Color(0xFF1DB87A), const Color(0xFF0A5C3A)];
      case 'delivery_staff':
        return [const Color(0xFFE8A020), const Color(0xFF8B4A00)];
      case 'admin':
        return [const Color(0xFFD64444), const Color(0xFF7A1212)];
      default:
        return [const Color(0xFF7C3AED), const Color(0xFF3B1472)];
    }
  }

  String get _roleName {
    switch (widget.selectedRole) {
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

  IconData get _roleIcon {
    switch (widget.selectedRole) {
      case 'customer':
        return Icons.person_outline_rounded;
      case 'delivery_staff':
        return Icons.delivery_dining_rounded;
      case 'admin':
        return Icons.shield_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    for (final c in _boxControllers) {
      c.addListener(_updateFilledCount);
    }
  }

  void _updateFilledCount() {
    final count = _boxControllers.where((c) => c.text.isNotEmpty).length;
    if (count != _filledCount) setState(() => _filledCount = count);
    // Keep original single controller in sync
    _otpController.text = _boxControllers.map((c) => c.text).join();
  }

  // ── ORIGINAL startTimer — unchanged ─────────────────────────
  void startTimer() {
    _seconds = 60;
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
    for (final c in _boxControllers) {
      c.removeListener(_updateFilledCount);
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // ── ORIGINAL FCM update — unchanged ─────────────────────────
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

  // ── ORIGINAL verifyOtp — unchanged ──────────────────────────
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
      await NotificationBadgeService.refreshNow();
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

  // ── ORIGINAL navigation — unchanged ─────────────────────────
  Future<void> _navigateAfterLogin(BuildContext context, UserModel user) async {
    final role = user.role;
    if (role == 'vendor') {
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

  // ── ORIGINAL showError — unchanged ──────────────────────────
  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }

  // ── OTP box input handler ────────────────────────────────────
  void _onBoxChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.length > 1) {
      _boxControllers[index].text = digit[digit.length - 1];
      _boxControllers[index].selection = const TextSelection.collapsed(
        offset: 1,
      );
    }
    if (digit.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTimerDone = _seconds == 0;
    final isAllFilled = _filledCount == 6;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _roleColor,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top light section ──────────────────────────────
              Container(
                color: const Color(0xFFF4F1FB),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _roleColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _roleColor.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _roleColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logging in as $_roleName',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _roleColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(_roleIcon, size: 14, color: _roleColor),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Icon + text row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: _roleColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP Verification',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A0A2E),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '6-digit code sent to',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8B7BAE),
                                ),
                              ),
                              Text(
                                '+91 ${widget.phone}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1A0A2E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Form section ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label
                    const Text(
                      'ENTER VERIFICATION CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7BAE),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6 OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        final isFilled = _boxControllers[i].text.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? _roleColor.withValues(alpha: 0.06)
                                : const Color(0xFFFAFAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFilled
                                  ? _roleColor
                                  : const Color(0xFFE0DAF0),
                              width: isFilled ? 1.8 : 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _boxControllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isFilled
                                  ? _roleColor
                                  : const Color(0xFF1A0A2E),
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none, // ADD THIS
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) => _onBoxChanged(i, v),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _filledCount / 6,
                        backgroundColor: const Color(0xFFF0EBF9),
                        valueColor: AlwaysStoppedAnimation<Color>(_roleColor),
                        minHeight: 3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timer row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isTimerDone
                                ? const Color(0xFFE24B4A)
                                : const Color(0xFF8B7BAE),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isTimerDone ? 'Code expired' : 'Code expires in',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTimerDone
                                  ? const Color(0xFFE24B4A)
                                  : const Color(0xFF8B7BAE),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            isTimerDone ? '00:00' : _timerText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isTimerDone
                                  ? const Color(0xFFE24B4A)
                                  : _roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Verify button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAllFilled && !_isVerifying
                              ? _roleGradient
                              : [
                                  _roleColor.withValues(alpha: 0.35),
                                  _roleColor.withValues(alpha: 0.25),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isAllFilled && !_isVerifying
                            ? [
                                BoxShadow(
                                  color: _roleColor.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isAllFilled && !_isVerifying
                              ? verifyOtp
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFF0EBF9),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'having trouble?',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFC4BAD9),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFF0EBF9),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Resend row — same logic as original
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFF0EBF9),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A0A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isTimerDone
                                      ? 'Tap to get a new code'
                                      : 'Resend in $_seconds sec',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isTimerDone
                                        ? _roleColor
                                        : const Color(0xFFB0A3C8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ORIGINAL: same onPressed logic
                          GestureDetector(
                            onTap: isTimerDone
                                ? () {
                                    startTimer();
                                    for (final c in _boxControllers) {
                                      c.clear();
                                    }
                                    _focusNodes[0].requestFocus();
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isTimerDone
                                    ? _roleColor
                                    : const Color(0xFFF0EBF9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Send',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isTimerDone
                                      ? Colors.white
                                      : const Color(0xFFC4BAD9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer
                    const Text(
                      'Protected by 256-bit SSL encryption',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFFC4BAD9)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This code is valid for 10 minutes only',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF8B7BAE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
