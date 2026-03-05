import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/customer_repository.dart';
import '../../../../models/customer_model.dart';
import 'add_edit_customer_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final CustomerRepository repo = CustomerRepository();

  List<Customer> customers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final data = await repo.getCustomers();

      if (!mounted) return;

      setState(() {
        customers = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load customers")));
    }
  }

  // ===============================
  // SHARE CUSTOMER LINK
  // ===============================
  void shareCustomer(Customer c) {
    final link = "https://tiffincrm.app/customer/${c.id}";

    final text =
        """
Customer: ${c.name}

View details:
$link
""";

    Share.share(text);
  }

  // ===============================
  // AVATAR INITIALS
  // ===============================
  String getInitials(String name) {
    final parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customers")),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
          );

          loadCustomers();
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? const Center(child: Text("No customers"))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade400,
                      child: Text(
                        getInitials(c.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    title: Text(c.name),
                    subtitle: Text(c.phone),

                    onTap: () async {
                      final result = await context.pushNamed(
                        'customerDetail',
                        extra: c,
                      );

                      if (result == true) {
                        loadCustomers();
                      }
                    },

                    trailing: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => shareCustomer(c),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
