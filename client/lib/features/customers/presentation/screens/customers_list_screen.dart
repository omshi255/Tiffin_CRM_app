import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/lottie_empty_state.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../../../models/customer_model.dart';
import '../../data/customer_api.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  String _filter = 'active'; // 'all' | 'active' | 'inactive' | 'lowBalance'
  int _page = 1;
  static const int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<CustomerModel> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCustomers({bool reset = true}) async {
    if (_isLoading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => _isLoading = true);
    try {
      final result = await CustomerApi.list(
        page: 1,
        limit: _limit,
        status: _filter == 'all'
            ? null
            : (_filter == 'lowBalance' ? null : _filter),
        lowBalance: _filter == 'lowBalance',
      );

      // Handles both cases:
      // Case 1: CustomerApi returns raw JSON → result = { success, data: { data: [], total } }
      // Case 2: CustomerApi already unwraps once → result = { data: [], total }
      List<dynamic> rawList = [];
      int total = 0;

      if (result['data'] is Map) {
        // Case 1: raw response
        final inner = result['data'] as Map<String, dynamic>;
        rawList = inner['data'] as List? ?? [];
        total = inner['total'] as int? ?? rawList.length;
      } else if (result['data'] is List) {
        // Case 2: already unwrapped
        rawList = result['data'] as List;
        total = result['total'] as int? ?? rawList.length;
      } else if (result['customers'] is List) {
        // Case 3: mapped to 'customers' key
        rawList = result['customers'] as List;
        total = result['total'] as int? ?? rawList.length;
      }

      final list = rawList
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _customers = list;
        _hasMore = list.length >= _limit && list.length < total;
        _page = 1;
      });
    } catch (e, stack) {
      debugPrint('❌ _loadCustomers error: $e\n$stack');
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await CustomerApi.list(
        page: nextPage,
        limit: _limit,
        status: _filter == 'all'
            ? null
            : (_filter == 'lowBalance' ? null : _filter),
        lowBalance: _filter == 'lowBalance',
      );

      List<dynamic> rawList = [];
      int total = 0;

      if (result['data'] is Map) {
        final inner = result['data'] as Map<String, dynamic>;
        rawList = inner['data'] as List? ?? [];
        total = inner['total'] as int? ?? rawList.length;
      } else if (result['data'] is List) {
        rawList = result['data'] as List;
        total = result['total'] as int? ?? rawList.length;
      } else if (result['customers'] is List) {
        rawList = result['customers'] as List;
        total = result['total'] as int? ?? rawList.length;
      }

      final list = rawList
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _customers = [..._customers, ...list];
        _page = nextPage;
        _hasMore = _customers.length < total;
      });
    } catch (e, stack) {
      debugPrint(' _loadMore error: $e\n$stack');
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    await _loadCustomers(reset: true);
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await CustomerApi.delete(customer.id);
                if (context.mounted) {
                  AppSnackbar.success(context, 'Customer deleted');
                  _loadCustomers(reset: true);
                }
              } catch (e) {
                if (context.mounted) ErrorHandler.show(context, e);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _customers
        : _customers.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.phone.contains(_query) ||
                (c.email?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () {
                        setState(() => _filter = 'all');
                        _loadCustomers(reset: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      selected: _filter == 'active',
                      onTap: () {
                        setState(() => _filter = 'active');
                        _loadCustomers(reset: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactive',
                      selected: _filter == 'inactive',
                      onTap: () {
                        setState(() => _filter = 'inactive');
                        _loadCustomers(reset: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Low Balance',
                      selected: _filter == 'lowBalance',
                      onTap: () {
                        setState(() => _filter = 'lowBalance');
                        _loadCustomers(reset: true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: filtered.isEmpty
                  ? LottieEmptyState(
                      message: _query.isEmpty
                          ? 'No customers found'
                          : 'No results for "$_query"',
                      lottieAsset: _query.isEmpty
                          ? 'assets/lottie/empty_state.json'
                          : 'assets/lottie/search_empty.json',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, index) => const ThinDivider(),
                      itemBuilder: (context, index) {
                        if (index >= filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final customer = filtered[index];
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
                                  onPressed: (_) => context.push(
                                    AppRoutes.editCustomer,
                                    extra: customer,
                                  ),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                ),
                                SlidableAction(
                                  onPressed: (_) =>
                                      WhatsAppHelper.openChat(customer.phone),
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  icon: Icons.chat_outlined,
                                  label: 'WhatsApp',
                                ),
                                SlidableAction(
                                  onPressed: (_) =>
                                      _confirmDelete(context, customer),
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
                                  left: BorderSide(
                                    color: borderColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: avatarColor,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                title: Text(customer.name),
                                subtitle: Text(customer.phone),
                                onTap: () => context.push(
                                  AppRoutes.customerDetail,
                                  extra: customer,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
