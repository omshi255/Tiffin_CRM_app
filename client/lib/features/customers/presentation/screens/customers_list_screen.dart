import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/lottie_empty_state.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../../../models/customer_model.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted (mock)')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = mockCustomers
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query) ||
            (c.email?.toLowerCase().contains(_query.toLowerCase()) ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(57),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          ),
        ),
      ),
      body: customers.isEmpty
          ? LottieEmptyState(
              message: _query.isEmpty
                  ? 'No customers found'
                  : 'No results for "$_query"',
              lottieAsset: _query.isEmpty
                  ? 'assets/lottie/empty_state.json'
                  : 'assets/lottie/search_empty.json',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const ThinDivider(),
              itemBuilder: (context, index) {
                final customer = customers[index];
                final initials = _initials(customer.name);
                final avatarColor = colorFromName(customer.name);
                final borderColor = statusBorderColor(customer.status);
                return AnimatedListItem(
                  index: index,
                  child: Slidable(
                  key: ValueKey(customer.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.65,
                    children: [
                      SlidableAction(
                        onPressed: (_) =>
                            context.push(AppRoutes.editCustomer, extra: customer),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                      SlidableAction(
                        onPressed: (_) => _openWhatsApp(customer.phone),
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDelete(context, customer),
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.onError,
                        icon: Icons.delete_outlined,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: borderColor, width: 4),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: avatarColor,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      onTap: () =>
                          context.push(AppRoutes.customerDetail, extra: customer),
                    ),
                  ),
                ),
              );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addCustomer),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}
