import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class CustomerApi {
  final Dio dio = ApiClient().dio;

  Future<dynamic> getCustomers() async {
    final res = await dio.get("customers?page=1&limit=10&status=active");
    return res.data;
  }

  Future<dynamic> createCustomer(Map<String, dynamic> data) async {
    final res = await dio.post("customers", data: data);
    return res.data;
  }

  Future<dynamic> updateCustomer(String id, Map<String, dynamic> data) async {
    final res = await dio.put("customers/$id", data: data);
    return res.data;
  }

  Future<dynamic> deleteCustomer(String id) async {
    final res = await dio.delete("customers/$id");
    return res.data;
  }
}
