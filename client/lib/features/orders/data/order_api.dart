import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/order_model.dart';

abstract final class OrderApi {
  /// [mealPeriod] is one of: breakfast | lunch | dinner | snack.
  static Future<List<OrderModel>> getToday({String? mealPeriod}) async {
    final mp = mealPeriod?.trim().toLowerCase();
    final query = <String, dynamic>{};
    if (mp != null &&
        mp.isNotEmpty &&
        (mp == 'breakfast' || mp == 'lunch' || mp == 'dinner' || mp == 'snack')) {
      query['mealPeriod'] = mp;
    }

    final response = await DioClient.instance.get(
      ApiEndpoints.dailyOrdersToday,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['orders'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => OrderModel.fromJson(e))
            .toList();
      }
    }
    return [];
  }

  static Future<void> process({String? date}) async {
    await DioClient.instance.post(
      ApiEndpoints.dailyOrdersProcess,
      data: date != null ? {'date': date} : null,
    );
  }

  /// Cancels all non-delivered daily orders for [date] (YYYY-MM-DD) or today.
  /// Subscription/wallet deduction happens only when an order is marked delivered.
  static Future<int> cancelVendorHoliday({String? date}) async {
    final response = await DioClient.instance.post(
      ApiEndpoints.dailyOrdersCancelVendorHoliday,
      data: date != null ? {'date': date} : null,
    );
    final data = parseData(response);
    if (data is Map<String, dynamic>) {
      return (data['cancelledCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static Future<void> assign(String orderId, String deliveryStaffId) async {
    await DioClient.instance.patch(
      ApiEndpoints.dailyOrderAssign(orderId),
      data: {'deliveryStaffId': deliveryStaffId},
    );
  }

  static Future<void> assignBulk(
    List<String> orderIds,
    String deliveryStaffId,
  ) async {
    await DioClient.instance.post(
      ApiEndpoints.dailyOrdersAssignBulk,
      data: {'orderIds': orderIds, 'deliveryStaffId': deliveryStaffId},
    );
  }

  static Future<void> updateStatus(String orderId, String status) async {
    await DioClient.instance.patch(
      ApiEndpoints.dailyOrderStatus(orderId),
      data: {'status': status},
    );
  }

  static Future<void> updateQuantities(
    String orderId,
    List<Map<String, dynamic>> quantities,
  ) async {
    await DioClient.instance.patch(
      ApiEndpoints.dailyOrderQuantities(orderId),
      data: quantities,
    );
  }

  static Future<void> accept(String orderId) async {
    await DioClient.instance.post(ApiEndpoints.dailyOrderAccept(orderId));
  }

  static Future<void> reject(String orderId, {required String reason}) async {
    await DioClient.instance.post(
      ApiEndpoints.dailyOrderReject(orderId),
      data: {'reason': reason},
    );
  }

  static Future<void> generate({String? date}) async {
    await DioClient.instance.post(
      ApiEndpoints.dailyOrdersGenerate,
      data: date != null ? {'date': date} : null,
    );
  }
}
