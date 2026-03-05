import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../models/customer_model.dart';
import '../../data/customer_repository.dart';
import 'add_edit_customer_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  String getInitials(String name) {
    List parts = name.split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  String generateCustomerLink(String id) {
    return "https://tiffincrm.app/customer/$id";
  }

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository();
    final shareLink = generateCustomerLink(customer.id);

    return Scaffold(
      appBar: AppBar(title: const Text("Customer Details")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Text(
                  getInitials(customer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text("Name", style: TextStyle(color: Colors.grey)),
            Text(
              customer.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text("Phone", style: TextStyle(color: Colors.grey)),
            Text(customer.phone, style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            const Text("Email", style: TextStyle(color: Colors.grey)),
            Text(customer.email),

            const SizedBox(height: 20),

            const Text("Address", style: TextStyle(color: Colors.grey)),
            Text(customer.address),

            const SizedBox(height: 30),

            const Text(
              "Share Customer Link",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link copied")),
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Share.share("Customer: ${customer.name}\n$shareLink");
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditCustomerScreen(customer: customer),
                        ),
                      );

                      Navigator.pop(context, true);
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await repo.deleteCustomer(customer.id);
                      Navigator.pop(context, true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
