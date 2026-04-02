// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../screens/customer_details/customer_details_screen.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/lottie_empty_state.dart';
import '../../../../models/customer_model.dart';
import '../../data/customer_api.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const v700 = Color(0xFF5B21B6);
  static const v100 = Color(0xFFEDE9FE);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s400 = Color(0xFF94A3B8);
  static const s300 = Color(0xFFCBD5E1);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const bg = Color(0xFFF0EBFF);

  static const greenBg = Color(0xFFF0FDF4);

  static const greenTxt = Color(0xFF166534);

  static const greenBdr = Color(0xFF86EFAC);
  static const redBg = Color(0xFFFEF2F2);
  static const redTxt = Color(0xFF991B1B);
  static const redBdr = Color(0xFFFCA5A5);

  static const amberBg = Color(0xFFFFFBEB);

  static const amberTxt = Color(0xFF92400E);
  static const amberBdr = Color(0xFFFCD34D);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

Color _accentColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'active':
      return _P.green;
    case 'inactive':
      return _P.red;
    default:
      return _P.amber;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  // ── ALL LOGIC UNCHANGED ──
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  String _filter = 'active';
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
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
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
      debugPrint('_loadMore error: $e\n$stack');
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() => _loadCustomers(reset: true);

  // ignore: unused_element
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Customer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _P.s900,
          ),
        ),
        content: Text(
          'Delete ${customer.name}? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: _P.s600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () async {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _P.redBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _P.redBdr, width: 0.5),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: _P.redTxt,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _filterLabels = ['All', 'Active', 'Inactive', 'Low Balance'];
  static const _filterValues = ['all', 'active', 'inactive', 'lowBalance'];

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
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.g1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customers',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${_customers.where((c) => c.status == "active").length} active',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _isLoading ? null : () => _loadCustomers(reset: true),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
        children: [
          // ── Search + filter chips ──
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _P.s100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _P.s200, width: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: _P.s400,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _P.s900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search name, phone, email…',
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: _P.s400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onChanged: (v) => setState(() => _query = v),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: _P.s400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: List.generate(_filterLabels.length, (i) {
                      final active = _filter == _filterValues[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _filter = _filterValues[i]);
                            _loadCustomers(reset: true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active ? _P.g1 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? _P.g1 : _P.s300,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _filterLabels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : _P.s600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Bottom border
                Container(height: 0.5, color: _P.s200),
              ],
            ),
          ),
          // ── List body ──
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                      strokeWidth: 2,
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF7C3AED),
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
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 24,
                            ),
                            itemCount:
                                filtered.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, _) => const Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: _P.s200,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF7C3AED),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final customer = filtered[index];
                              return AnimatedListItem(
                                index: index,
                                child: _CustomerRow(
                                  customer: customer,
                                  onTap: () async {
                                    await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => CustomerDetailsScreen(
                                          customerId: customer.id,
                                          customerName: customer.name,
                                        ),
                                      ),
                                    );
                                    _loadCustomers(
                                      reset: true,
                                    ); // detail/edit se wapas aane pe list refresh
                                  },
                                  onEdit: () async {
                                    await context.push(
                                      AppRoutes.editCustomer,
                                      extra: customer,
                                    );
                                    _loadCustomers(reset: true);
                                  },
                                  onWhatsApp: () =>
                                      WhatsAppHelper.openChat(customer.phone),
                                  onDelete: () =>
                                      _confirmDelete(context, customer),
                                ),
                              );
                            },
                          ),
                  ), // RefreshIndicator / Center
          ), // Expanded
        ],
      ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers_fab_add',
        onPressed: () => context.push(AppRoutes.addCustomer),
        backgroundColor: _P.g1,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Add Customer',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

// ─── Customer row widget ──────────────────────────────────────────────────────
class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onWhatsApp,
    required this.onDelete,
  });

  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onWhatsApp;
  final VoidCallback onDelete;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name);
    final avatarColor = colorFromName(customer.name);
    final accent = _accentColor(customer.status);
    final hasArea = customer.area?.isNotEmpty == true;
    final walletShown = customer.effectiveWalletBalance;
    final isLowBal = walletShown < 100;

    return Slidable(
      key: ValueKey(customer.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.62,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: _P.v100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.edit_outlined, color: _P.v700, size: 18),
                SizedBox(height: 3),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _P.v700,
                  ),
                ),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => onWhatsApp(),
            backgroundColor: Color(0xFFDCFCE7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF166534),
                  size: 18,
                ),
                SizedBox(height: 3),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: _P.redBg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.delete_outline_rounded, color: _P.redTxt, size: 18),
                SizedBox(height: 3),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _P.redTxt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar — 3px, full height ──
              Container(width: 3, color: accent),

              // ── Row content ──
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      // Avatar with rounded square
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),

                      // Name + phone + area tag
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (hasArea) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFDDD6FE),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  customer.area!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5B21B6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Balance column (same source as detail: walletBalance ?? balance, ≥ 0)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${walletShown.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isLowBal
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'balance',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
