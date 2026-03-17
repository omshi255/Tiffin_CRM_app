import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/payment_model.dart';

abstract final class PaymentApi {
  static Future<List<PaymentModel>> list({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (customerId != null) query['customerId'] = customerId;
    if (fromDate != null) query['fromDate'] = fromDate;
    if (toDate != null) query['toDate'] = toDate;

    final response = await DioClient.instance.get(
      ApiEndpoints.payments,
      queryParameters: query,
    );

    final data = parseData(response); // returns { data: [...], total: N }
    List<dynamic> rawList = [];
    if (data is Map<String, dynamic>) {
      rawList = (data['data'] as List?) ?? (data['payments'] as List?) ?? [];
    } else if (data is List) {
      rawList = data;
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => PaymentModel.fromJson(e))
        .toList();
  }

  static Future<PaymentModel> create(Map<String, dynamic> body) async {
    final response = await DioClient.instance.post(
      ApiEndpoints.payments,
      data: body,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return PaymentModel.fromJson(data);
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? receipt,
    String? customerId,
    String? invoiceId,
  }) async {
    final response = await DioClient.instance.post(
      ApiEndpoints.paymentsCreateOrder,
      data: {
        'amount': amount,
        'receipt': ?receipt,
        'customerId': ?customerId,
        'invoiceId': ?invoiceId,
      },
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return data;
  }
}
