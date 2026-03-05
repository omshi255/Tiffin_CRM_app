import '../../../models/customer_model.dart';
import 'customer_api.dart';

class CustomerRepository {
  final CustomerApi api = CustomerApi();

  Future<List<Customer>> getCustomers() async {
    final response = await api.getCustomers();

    final List customersJson = response["data"]["data"];

    return customersJson.map((e) => Customer.fromJson(e)).toList();
  }

  Future<void> createCustomer(Customer customer) async {
    await api.createCustomer(customer.toJson());
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    final response = await api.updateCustomer(id, customer.toJson());
    print(response);
  }

  Future<void> deleteCustomer(String id) async {
    await api.deleteCustomer(id);
  }
}
