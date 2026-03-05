import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tiffin_crm/features/auth/presentation/screens/data/auth_repository.dart'
    show AuthRepository;
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

  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;

  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  String? _validatePhone(String? value) {
    final v = value?.trim().replaceAll(RegExp(r'\D'), '') ?? '';

    if (v.isEmpty) return "Mobile number required";
    if (v.length != 10) return "Enter 10 digit number";
    if (!_phoneRegex.hasMatch(v)) return "Invalid mobile number";

    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await _authRepository.sendOtp(phone);

      setState(() => _isLoading = false);

      if (response["success"] == true) {
        context.push(AppRoutes.otp, extra: phone);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "OTP failed")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network Error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),

            Text("Get Started", style: theme.textTheme.headlineMedium),

            const SizedBox(height: 30),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validatePhone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixText: "+91 ",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
