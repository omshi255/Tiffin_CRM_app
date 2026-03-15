import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

abstract final class ReportApi {
  static Future<Map<String, dynamic>> getSummary({
    String period = 'monthly',
  }) async {
    final response = await DioClient.instance.get(
      ApiEndpoints.reportsSummary,
      queryParameters: {'period': period},
    );
    final data = parseData(response);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  static Future<List<dynamic>> getTodayDeliveries() async {
    final response =
        await DioClient.instance.get(ApiEndpoints.reportsTodayDeliveries);
    final data = parseData(response);
    if (data is List) return data;
    return [];
  }

  static Future<List<dynamic>> getExpiringSubscriptions({int days = 7}) async {
    final response = await DioClient.instance.get(
      ApiEndpoints.reportsExpiringSubscriptions,
      queryParameters: {'days': days},
    );
    final data = parseData(response);
    if (data is List) return data;
    return [];
  }

  static Future<List<dynamic>> getPendingPayments() async {
    final response =
        await DioClient.instance.get(ApiEndpoints.reportsPendingPayments);
    final data = parseData(response);
    if (data is List) return data;
    return [];
  }
}
