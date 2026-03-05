import 'package:tiffin_crm/core/network/api_client.dart';

class AuthRepository {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.post("auth/send-otp", data: {"phone": phone});

    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await _dio.post(
      "auth/verify-otp",
      data: {"phone": phone, "otp": otp},
    );

    return response.data;
  }
}
