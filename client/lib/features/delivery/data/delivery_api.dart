import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/delivery_staff_model.dart';
import '../../orders/models/order_model.dart';

abstract final class DeliveryApi {
  static Future<List<OrderModel>> getMyDeliveries() async {
    final response = await DioClient.instance.get(
      ApiEndpoints.deliveryMyDeliveries,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    if (data is Map<String, dynamic> && data['orders'] is List) {
      return (data['orders'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<OrderModel>> getAllDeliveries() async {
    final response = await DioClient.instance.get(ApiEndpoints.delivery);
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<DeliveryStaffModel>> listStaff({
    int page = 1,
    int limit = 20,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (isActive != null) query['isActive'] = isActive;

    final response = await DioClient.instance.get(
      ApiEndpoints.deliveryStaff,
      queryParameters: query,
    );

    final data = parseData(response); // returns { data: [...], total: N }
    List<dynamic> rawList = [];
    if (data is Map<String, dynamic>) {
      rawList = (data['data'] as List?) ?? (data['staff'] as List?) ?? [];
    } else if (data is List) {
      rawList = data;
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => DeliveryStaffModel.fromJson(e))
        .toList();
  }

  static Future<DeliveryStaffModel> getStaffById(String id) async {
    final response = await DioClient.instance.get(
      ApiEndpoints.deliveryStaffById(id),
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return DeliveryStaffModel.fromJson(data);
  }

  static Future<DeliveryStaffModel> createStaff(
    Map<String, dynamic> body,
  ) async {
    final response = await DioClient.instance.post(
      ApiEndpoints.deliveryStaff,
      data: body,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return DeliveryStaffModel.fromJson(data);
  }

  static Future<DeliveryStaffModel> updateStaff(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await DioClient.instance.put(
      ApiEndpoints.deliveryStaffById(id),
      data: body,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return DeliveryStaffModel.fromJson(data);
  }

  static Future<void> updateMe(Map<String, dynamic> body) async {
    await DioClient.instance.patch(ApiEndpoints.deliveryStaffMe, data: body);
  }

  static Future<void> deleteStaff(String id) async {
    await DioClient.instance.delete(ApiEndpoints.deliveryStaffById(id));
  }
}
