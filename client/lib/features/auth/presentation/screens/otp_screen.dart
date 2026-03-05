// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import '../../../../core/router/app_routes.dart';
// // import '../../../../core/theme/app_colors.dart';

// // class OtpScreen extends StatefulWidget {
// //   const OtpScreen({super.key, required this.phone});

// //   final String phone;

// //   @override
// //   State<OtpScreen> createState() => _OtpScreenState();
// // }

// // class _OtpScreenState extends State<OtpScreen> {
// //   final _otpController = TextEditingController();
// //   bool _isVerifying = false;

// //   @override
// //   void dispose() {
// //     _otpController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _verify() async {
// //     final otp = _otpController.text.trim();
// //     if (otp.length < 4) return;
// //     setState(() => _isVerifying = true);
// //     await Future.delayed(const Duration(milliseconds: 600));
// //     if (!mounted) return;
// //     setState(() => _isVerifying = false);
// //     context.go(AppRoutes.dashboard);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     return Scaffold(
// //       backgroundColor: theme.colorScheme.surface,
// //       appBar: AppBar(
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
// //           onPressed: _isVerifying ? null : () => context.pop(),
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               const SizedBox(height: 8),
// //               Text(
// //                 'Verify OTP',
// //                 style: theme.textTheme.headlineMedium?.copyWith(
// //                   fontWeight: FontWeight.w700,
// //                   color: AppColors.onSurface,
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               Text(
// //                 'Code sent to ${widget.phone}',
// //                 style: theme.textTheme.bodyLarge?.copyWith(
// //                   color: theme.colorScheme.onSurfaceVariant,
// //                 ),
// //               ),
// //               const SizedBox(height: 32),
// //               TextFormField(
// //                 controller: _otpController,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Enter 4-digit OTP',
// //                   hintText: '0000',
// //                 ),
// //                 keyboardType: TextInputType.number,
// //                 maxLength: 4,
// //               ),
// //               const SizedBox(height: 24),
// //               FilledButton(
// //                 onPressed: _isVerifying ? null : _verify,
// //                 style: FilledButton.styleFrom(
// //                   backgroundColor: AppColors.primary,
// //                   foregroundColor: AppColors.onPrimary,
// //                 ),
// //                 child: _isVerifying
// //                     ? const SizedBox(
// //                         height: 20,
// //                         width: 20,
// //                         child: CircularProgressIndicator(strokeWidth: 2),
// //                       )
// //                     : const Text('Verify'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/theme/app_colors.dart';

// class OtpScreen extends StatefulWidget {
//   final String phone;
//   const OtpScreen({super.key, required this.phone});

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
//   final _otpController = TextEditingController();
//   bool _isLoading = false;
//   int _seconds = 30;
//   Timer? _timer;

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

//   Future<void> verifyOtp() async {
//     if (_otpController.text.length != 6) {
//       _showError("Enter 6 digit OTP");
//       return;
//     }

//     setState(() => _isLoading = true);

//     await Future.delayed(const Duration(milliseconds: 1200));

//     setState(() => _isLoading = false);

//     if (!mounted) return;

//     _showSuccessDialog();
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Colors.red.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 msg,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         /// auto close after 4 sec
//         Future.delayed(const Duration(seconds: 4), () {
//           if (mounted) {
//             Navigator.of(context).pop();
//             context.go(AppRoutes.dashboard);
//           }
//         });

//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
//           content: Stack(
//             children: [
//               /// ❌ CROSS BUTTON TOP RIGHT
//               Positioned(
//                 right: 0,
//                 top: 0,
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.pop(context);
//                     context.go(AppRoutes.dashboard);
//                   },
//                   child: const Icon(Icons.close, size: 22),
//                 ),
//               ),

//               Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 10),

//                   /// GREEN SUCCESS ICON
//                   CircleAvatar(
//                     radius: 38,
//                     backgroundColor: Colors.green.shade50,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.green.shade100,
//                       ),
//                       padding: const EdgeInsets.all(8),
//                       child: const Icon(
//                         Icons.check_rounded,
//                         color: Colors.green,
//                         size: 44,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   const Text(
//                     "Login Successful",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),

//                   const SizedBox(height: 8),

//                   Text(
//                     "You have successfully verified your account",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),

//                   const SizedBox(height: 22),

//                   /// CONTINUE BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     child: FilledButton(
//                       style: FilledButton.styleFrom(
//                         backgroundColor: Colors.blueGrey.shade800,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         context.go(AppRoutes.dashboard);
//                       },
//                       child: const Text(
//                         "Continue",
//                         style: TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
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
//                 onPressed: _isLoading ? null : verifyOtp,
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tiffin_crm/features/auth/presentation/screens/data/auth_repository.dart' show AuthRepository;
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/local_storage.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _loading = false;

  Future<void> verifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() => _loading = true);

    try {
      final response = await _authRepository.verifyOtp(
        widget.phone,
        _otpController.text,
      );

      setState(() => _loading = false);

      if (response["success"] == true) {
        final accessToken = response["data"]["accessToken"];
        final refreshToken = response["data"]["refreshToken"];

        await AuthStorage.saveTokens(accessToken, refreshToken);

        if (!mounted) return;

        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            Text("OTP sent to ${widget.phone}"),

            const SizedBox(height: 30),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : verifyOtp,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify OTP"),
              ),
            )
          ],
        ),
      ),
    );
  }
}