// import 'package:dio/dio.dart';
// import '../../../../../core/network/api_client.dart';

// class AuthApi {
//   final Dio _dio = ApiClient().dio;

//   Future sendOtp(String phone) async {
//     final response = await _dio.post("auth/send-otp", data: {"phone": phone});
//     return response.data;
//   }

//   Future verifyOtp(String phone, String otp) async {
//     final response = await _dio.post(
//       "auth/verify-otp",
//       data: {"phone": phone, "otp": otp},
//     );
//     return response.data;
//   }
// }
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';

class AuthApi {
  final Dio _dio = ApiClient().dio;

  Future sendOtp(String phone) async {
    final res = await _dio.post("auth/send-otp", data: {"phone": phone});

    return res.data;
  }

  Future verifyOtp(String phone, String otp) async {
    final res = await _dio.post(
      "auth/verify-otp",
      data: {"phone": phone, "otp": otp},
    );

    return res.data;
  }
}
