import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: "http://192.168.0.166:5800/api/v1/",
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.getAccessToken();

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = await AuthStorage.getRefreshToken();

              final refreshDio = Dio();

              final response = await refreshDio.post(
                "http://192.168.0.166:5800/api/v1/auth/refresh-token",
                data: {"refreshToken": refreshToken},
              );

              final newAccessToken = response.data["data"]["accessToken"];

              await AuthStorage.saveTokens(newAccessToken, refreshToken!);

              error.requestOptions.headers["Authorization"] =
                  "Bearer $newAccessToken";

              final retry = await dio.fetch(error.requestOptions);

              return handler.resolve(retry);
            } catch (e) {
              await AuthStorage.clear();
            }
          }

          handler.next(error);
        },
      ),
    );
  }
}
