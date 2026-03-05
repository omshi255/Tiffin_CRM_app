// import 'package:shared_preferences/shared_preferences.dart';
// import './../../../../../core/network/api_client.dart';

// class AuthService {
//   Future<void> loginWithTruecaller(
//     String phone,
//     String name,
//     String? email,
//   ) async {
//     final response = await ApiClient().dio.post(
//       "auth/truecaller",
//       data: {"phone": phone, "name": name, "email": email},
//     );

//     final token = response.data["token"];

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("token", token);
//   }
// }
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
