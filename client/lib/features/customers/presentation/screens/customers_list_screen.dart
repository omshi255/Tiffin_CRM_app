// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
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

enum _CustomerSort {
  newest,
  oldest,
  nameAz,
  nameZa,
  lowestBalance,
  highestBalance,
  lowestTiffinCounts,
  highestTiffinCounts,
}

enum _CustomerStatusFilter {
  lowBalance,
  vegetarian,
  nonVegetarian,
  active,
  paused,
  blocked,
  inactiveMeals,
  customizedMeals,
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

  // ── Added local-only sort/filter state (does not affect API fetching) ──
  _CustomerSort _sort = _CustomerSort.newest;
  final Set<_CustomerStatusFilter> _statusFilters = <_CustomerStatusFilter>{};
  final Set<String> _timeSlotFilters = <String>{};

  // ── New: card field customization (local-only UI preference) ──
  static const String _prefsKeyCardFields = 'customers.card_fields.v1';
  Set<_CardField> _cardFields = <_CardField>{
    _CardField.name,
    _CardField.phone,
    _CardField.area,
    _CardField.balance,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadCardPrefs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCardPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKeyCardFields);
      if (raw == null || raw.isEmpty) return;
      final parsed =
          raw.map(_CardFieldX.tryParse).whereType<_CardField>().toSet();
      if (parsed.isEmpty) return;
      if (!mounted) return;
      setState(() => _cardFields = parsed);
    } catch (_) {}
  }

  Future<void> _saveCardPrefs(Set<_CardField> next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKeyCardFields,
        next.map((e) => e.key).toList(),
      );
    } catch (_) {}
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

  String _mainFilterLabel() {
    final i = _filterValues.indexOf(_filter);
    final label = (i >= 0) ? _filterLabels[i] : 'All';
    return 'Filter ($label)';
  }

  Future<void> _openMainFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget item(String value, String label) {
          final sel = _filter == value;
          return InkWell(
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _filter = value);
              _loadCustomers(reset: true);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    sel ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: sel ? _P.g1 : _P.s400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: sel ? _P.s900 : _P.s600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.s200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter',
                            style: TextStyle(
                              color: _P.s900,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: _P.s600,
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _P.s200),
                  item('all', 'All'),
                  Container(height: 1, color: _P.s200),
                  item('active', 'Active'),
                  Container(height: 1, color: _P.s200),
                  item('inactive', 'Inactive'),
                  Container(height: 1, color: _P.s200),
                  item('lowBalance', 'Low Balance'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _sheetBg = Color(0xFF1E1E1E);
  static const _sheetBorder = Color(0x33FFFFFF);

  static bool _isLowBalance(CustomerModel c) => c.effectiveWalletBalance < 100;

  static String? _diet(CustomerModel c) {
    final dt = c.dietType?.trim().toLowerCase();
    if (dt != null && dt.isNotEmpty) return dt;
    final tags = (c.tags ?? const []).map((e) => e.trim().toLowerCase()).toList();
    if (tags.contains('veg') || tags.contains('vegetarian')) return 'veg';
    if (tags.contains('non_veg') || tags.contains('non-veg') || tags.contains('nonvegetarian')) {
      return 'non_veg';
    }
    return null;
  }

  static bool _hasInactiveMeals(CustomerModel c) {
    if (c.hasInactiveMeals == true) return true;
    final tags = (c.tags ?? const []).map((e) => e.trim().toLowerCase());
    return tags.contains('inactive_meals') || tags.contains('inactive-meals');
  }

  static bool _hasCustomizedMeals(CustomerModel c) {
    if (c.hasCustomizedMeals == true) return true;
    final tags = (c.tags ?? const []).map((e) => e.trim().toLowerCase());
    return tags.contains('customized_meals') || tags.contains('custom-meals') || tags.contains('customized');
  }

  static Set<String> _customerTimeSlots(CustomerModel c) {
    final out = <String>{};
    for (final s in c.timeSlots ?? const <String>[]) {
      final v = s.trim();
      if (v.isNotEmpty) out.add(v);
    }
    // Also allow tags to contribute if backend uses tags for slots.
    for (final t in c.tags ?? const <String>[]) {
      final v = t.trim();
      if (v.isNotEmpty && (v.toLowerCase().contains('morning') || v.toLowerCase().contains('afternoon') || v.toLowerCase().contains('evening') || v.toLowerCase().contains('breakfast') || v.toLowerCase().contains('lunch') || v.toLowerCase().contains('dinner'))) {
        out.add(v);
      }
    }
    return out;
  }

  static int _tiffinCount(CustomerModel c) => c.tiffinCount ?? 0;

  List<CustomerModel> _applyLocalFiltersAndSort(List<CustomerModel> base) {
    final statusSel = _statusFilters;
    final timeSel = _timeSlotFilters;

    bool statusMatches(CustomerModel c) {
      if (statusSel.isEmpty) return true; // means "all 8/8"
      bool any = false;
      for (final f in statusSel) {
        switch (f) {
          case _CustomerStatusFilter.lowBalance:
            any = any || _isLowBalance(c);
            break;
          case _CustomerStatusFilter.vegetarian:
            any = any || (_diet(c) == 'veg' || _diet(c) == 'vegetarian');
            break;
          case _CustomerStatusFilter.nonVegetarian:
            any = any || (_diet(c) == 'non_veg' || _diet(c) == 'nonveg' || _diet(c) == 'non-veg');
            break;
          case _CustomerStatusFilter.active:
            any = any || c.status.toLowerCase() == 'active';
            break;
          case _CustomerStatusFilter.paused:
            any = any || c.status.toLowerCase() == 'paused';
            break;
          case _CustomerStatusFilter.blocked:
            any = any || c.status.toLowerCase() == 'blocked';
            break;
          case _CustomerStatusFilter.inactiveMeals:
            any = any || _hasInactiveMeals(c);
            break;
          case _CustomerStatusFilter.customizedMeals:
            any = any || _hasCustomizedMeals(c);
            break;
        }
      }
      return any;
    }

    bool timeMatches(CustomerModel c) {
      if (timeSel.isEmpty) return true;
      final slots = _customerTimeSlots(c).map((e) => e.toLowerCase()).toSet();
      for (final s in timeSel) {
        if (slots.contains(s.toLowerCase())) return true;
      }
      return false;
    }

    final out = base.where((c) => statusMatches(c) && timeMatches(c)).toList();

    int cmpString(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

    out.sort((a, b) {
      switch (_sort) {
        case _CustomerSort.newest:
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        case _CustomerSort.oldest:
          return (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        case _CustomerSort.nameAz:
          return cmpString(a.name, b.name);
        case _CustomerSort.nameZa:
          return cmpString(b.name, a.name);
        case _CustomerSort.lowestBalance:
          return a.effectiveWalletBalance.compareTo(b.effectiveWalletBalance);
        case _CustomerSort.highestBalance:
          return b.effectiveWalletBalance.compareTo(a.effectiveWalletBalance);
        case _CustomerSort.lowestTiffinCounts:
          return _tiffinCount(a).compareTo(_tiffinCount(b));
        case _CustomerSort.highestTiffinCounts:
          return _tiffinCount(b).compareTo(_tiffinCount(a));
      }
    });
    return out;
  }

  String _sortLabel() {
    final label = switch (_sort) {
      _CustomerSort.newest => 'Newest',
      _CustomerSort.oldest => 'Oldest',
      _CustomerSort.nameAz => 'Name (A-Z)',
      _CustomerSort.nameZa => 'Name (Z-A)',
      _CustomerSort.lowestBalance => 'Lowest Balance',
      _CustomerSort.highestBalance => 'Highest Balance',
      _CustomerSort.lowestTiffinCounts => 'Lowest Tiffin Counts',
      _CustomerSort.highestTiffinCounts => 'Highest Tiffin Counts',
    };
    return 'Sort By ($label)';
  }

  String _statusLabel() {
    final sel = _statusFilters.isEmpty ? _CustomerStatusFilter.values.length : _statusFilters.length;
    return 'Status ($sel/${_CustomerStatusFilter.values.length})';
  }

  String _timeSlotsLabel() {
    return _timeSlotFilters.isEmpty ? 'Time Slots' : 'Time Slots (${_timeSlotFilters.length})';
  }

  Widget _dropdownPill({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _P.s300,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _P.s600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _P.s600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSortSheet(BuildContext context, List<CustomerModel> base) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget option(_CustomerSort v, String label) {
          final selected = _sort == v;
          return GestureDetector(
            onTap: () {
              setState(() => _sort = v);
              Navigator.pop(ctx);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _P.g1 : _P.s200,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _P.v700 : _P.s900,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final mq = MediaQuery.of(ctx);
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: mq.size.height * 0.74, // prevents bottom overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Sort By',
                            style: TextStyle(
                              color: _P.s900,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _sort = _CustomerSort.newest);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Clear Selection',
                            style: TextStyle(
                              color: _P.v700,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.8, color: _P.s200),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        mq.padding.bottom + 16,
                      ),
                      children: [
                        option(_CustomerSort.newest, 'Newest'),
                        option(_CustomerSort.oldest, 'Oldest'),
                        option(_CustomerSort.nameAz, 'Name (A-Z)'),
                        option(_CustomerSort.nameZa, 'Name (Z-A)'),
                        option(_CustomerSort.lowestBalance, 'Lowest Balance'),
                        option(_CustomerSort.highestBalance, 'Highest Balance'),
                        option(_CustomerSort.lowestTiffinCounts, 'Lowest Tiffin Counts'),
                        option(_CustomerSort.highestTiffinCounts, 'Highest Tiffin Counts'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStatusSheet(BuildContext context, List<CustomerModel> base) async {
    Map<_CustomerStatusFilter, int> counts() {
      int countWhere(bool Function(CustomerModel c) pred) => base.where(pred).length;
      return <_CustomerStatusFilter, int>{
        _CustomerStatusFilter.lowBalance: countWhere(_isLowBalance),
        _CustomerStatusFilter.vegetarian: countWhere((c) => _diet(c) == 'veg' || _diet(c) == 'vegetarian'),
        _CustomerStatusFilter.nonVegetarian: countWhere((c) => _diet(c) == 'non_veg' || _diet(c) == 'nonveg' || _diet(c) == 'non-veg'),
        _CustomerStatusFilter.active: countWhere((c) => c.status.toLowerCase() == 'active'),
        _CustomerStatusFilter.paused: countWhere((c) => c.status.toLowerCase() == 'paused'),
        _CustomerStatusFilter.blocked: countWhere((c) => c.status.toLowerCase() == 'blocked'),
        _CustomerStatusFilter.inactiveMeals: countWhere(_hasInactiveMeals),
        _CustomerStatusFilter.customizedMeals: countWhere(_hasCustomizedMeals),
      };
    }

    final cMap = counts();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        Widget option(_CustomerStatusFilter v, String label) {
          final selected = _statusFilters.contains(v);
          final c = cMap[v] ?? 0;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _statusFilters.remove(v);
                } else {
                  _statusFilters.add(v);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _P.g1 : _P.s200,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$label ($c)',
                      style: TextStyle(
                        color: selected ? _P.v700 : _P.s900,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_rounded, color: _P.v700, size: 18),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        color: _P.s900,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _statusFilters.clear());
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(
                        color: _P.v700,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              option(_CustomerStatusFilter.lowBalance, 'Low Balance'),
              option(_CustomerStatusFilter.vegetarian, 'Vegetarian'),
              option(_CustomerStatusFilter.nonVegetarian, 'Non Vegetarian'),
              option(_CustomerStatusFilter.active, 'Active'),
              option(_CustomerStatusFilter.paused, 'Paused'),
              option(_CustomerStatusFilter.blocked, 'Blocked'),
              option(_CustomerStatusFilter.inactiveMeals, 'Inactive Meals'),
              option(_CustomerStatusFilter.customizedMeals, 'Customized Meals'),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _P.g1,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTimeSlotsSheet(BuildContext context, List<CustomerModel> base) async {
    final allSlots = <String, int>{};
    for (final c in base) {
      for (final s in _customerTimeSlots(c)) {
        final key = s.trim();
        if (key.isEmpty) continue;
        allSlots[key] = (allSlots[key] ?? 0) + 1;
      }
    }
    final keys = allSlots.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        Widget option(String slot) {
          final selected = _timeSlotFilters.contains(slot);
          final c = allSlots[slot] ?? 0;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _timeSlotFilters.remove(slot);
                } else {
                  _timeSlotFilters.add(slot);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _P.g1 : _P.s200,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$slot ($c)',
                      style: TextStyle(
                        color: selected ? _P.v700 : _P.s900,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_rounded, color: _P.v700, size: 18),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Time Slots',
                      style: TextStyle(
                        color: _P.s900,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _timeSlotFilters.clear());
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(
                        color: _P.v700,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (keys.isEmpty)
                const Text(
                  'No time slots found',
                  style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
                )
              else
                ...keys.map(option),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _P.g1,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3-dot menu + actions (local-only, uses already loaded customers) ──

  Future<void> _openMoreMenu(List<CustomerModel> current) async {
    const bg = Colors.white;
    const card = Colors.white;
    const divider = _P.s200;
    const text = _P.s900;

    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: _P.v700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _P.s400,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: card,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Customers',
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _P.s600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.settings_outlined,
                    label: 'Customize Card Info',
                    onTap: _openCustomizeCardInfo,
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.download_rounded,
                    label: 'Download Backup',
                    onTap: () => _openDownloadBackup(current),
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.donut_large_rounded,
                    label: 'Customer Analytics',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _CustomerAnalyticsScreen(customers: current),
                      ),
                    ),
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.inventory_2_outlined,
                    label: 'Archived Customers',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _ArchivedCustomersScreen(),
                      ),
                    ),
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.upload_rounded,
                    label: 'Import Bulk Data',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ImportCustomersScreen(
                          onImported: (items) {
                            setState(() => _customers = [...items, ..._customers]);
                          },
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.info_outline_rounded,
                    label: 'Learn More',
                    onTap: _openLearnMore,
                  ),
                  Container(height: 1, color: divider),
                  item(
                    icon: Icons.lock_outline_rounded,
                    label: 'Total Tiffins Outside',
                    onTap: () => _openTotalTiffinsOutside(current),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCustomizeCardInfo() async {
    const bg = Colors.white;
    const divider = _P.s200;
    var temp = Set<_CardField>.from(_cardFields);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Widget row(_CardField f) {
              final sel = temp.contains(f);
              return InkWell(
                onTap: () => setModal(() {
                  if (sel) {
                    if (temp.length > 1) temp.remove(f);
                  } else {
                    temp.add(f);
                  }
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: sel,
                        onChanged: (_) => setModal(() {
                          if (sel) {
                            if (temp.length > 1) temp.remove(f);
                          } else {
                            temp.add(f);
                          }
                        }),
                        activeColor: _P.g1,
                        checkColor: Colors.white,
                        side: const BorderSide(color: _P.s300, width: 1),
                      ),
                      Expanded(
                        child: Text(
                          f.label,
                          style: const TextStyle(
                            color: _P.s900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Customize Card Info',
                                style: TextStyle(
                                  color: _P.s900,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setModal(() {
                                temp = <_CardField>{
                                  _CardField.name,
                                  _CardField.phone,
                                  _CardField.area,
                                  _CardField.balance,
                                };
                              }),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: _P.v700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(height: 1, color: divider),
                      row(_CardField.name),
                      row(_CardField.phone),
                      row(_CardField.area),
                      row(_CardField.balance),
                      Container(height: 1, color: divider),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              setState(() => _cardFields = temp);
                              await _saveCardPrefs(temp);
                              if (context.mounted) Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _P.g1,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDownloadBackup(List<CustomerModel> current) async {
    const bg = Colors.white;
    const divider = _P.s200;
    const subText = _P.s600;

    Future<void> saveCsv() async {
      final header = [
        'Name',
        'Phone',
        'Address',
        'Zone',
        'Balance',
        'Status',
        'Meal Plan',
        'Time Slot',
      ];
      String esc(String v) {
        final s = v.replaceAll('"', '""');
        return '"$s"';
      }

      final lines = <String>[header.map(esc).join(',')];
      for (final c in current) {
        final slots = (c.timeSlots ?? const <String>[]).join(' | ');
        final addr = [c.address ?? '', c.area ?? '']
            .where((e) => e.trim().isNotEmpty)
            .join(', ');
        lines.add([
          c.name,
          c.phone,
          addr,
          c.area ?? '',
          c.effectiveWalletBalance.toStringAsFixed(2),
          c.status,
          (c.tags ?? const <String>[]).join(' | '),
          slots,
        ].map((e) => esc(e.toString())).join(','));
      }

      final bytes = Uint8List.fromList(lines.join('\n').codeUnits);
      await FileSaver.instance.saveFile(
        name: 'customers_backup_${DateTime.now().millisecondsSinceEpoch}.csv',
        bytes: bytes,
        mimeType: MimeType.csv,
      );
      if (mounted) {
        AppSnackbar.success(context, 'Backup downloaded successfully');
      }
    }

    Future<void> savePdf() async {
      final doc = pw.Document();
      final now = DateTime.now();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            return [
              pw.Text(
                'TiffinCRM — Customers Backup',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${now.day}/${now.month}/${now.year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Name',
                  'Phone',
                  'Address/Zone',
                  'Balance',
                  'Status',
                  'Time Slot',
                ],
                data: [
                  for (final c in current)
                    [
                      c.name,
                      c.phone,
                      '${c.address ?? ''} ${c.area ?? ''}'.trim(),
                      '₹${c.effectiveWalletBalance.toStringAsFixed(2)}',
                      c.status,
                      (c.timeSlots ?? const <String>[]).join(' | '),
                    ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
              ),
            ];
          },
        ),
      );
      final bytes = await doc.save();
      await FileSaver.instance.saveFile(
        name: 'customers_backup_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.pdf,
      );
      if (mounted) AppSnackbar.success(context, 'PDF downloaded successfully');
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Download Backup',
                            style: TextStyle(
                              color: _P.s900,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: divider),
                  ListTile(
                    leading: const Icon(Icons.table_view_rounded,
                        color: _P.v700),
                    title: const Text('Download as CSV/Excel',
                        style: TextStyle(
                            color: _P.s900,
                            fontWeight: FontWeight.w600)),
                    subtitle: const Text('Exports current loaded customers',
                        style: TextStyle(color: subText)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await saveCsv();
                    },
                  ),
                  Container(height: 1, color: divider),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded,
                        color: _P.v700),
                    title: const Text('Download as PDF',
                        style: TextStyle(
                            color: _P.s900,
                            fontWeight: FontWeight.w600)),
                    subtitle: const Text('Generates a clean PDF table',
                        style: TextStyle(color: subText)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await savePdf();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLearnMore() async {
    const bg = Colors.white;
    const divider = _P.s200;
    const subText = _P.s600;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn More',
                  style: TextStyle(
                    color: _P.s900,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Customers helps you manage zones, meal plans, balances and delivery timing.\n\n'
                  '- Use filters to find active/paused/blocked customers.\n'
                  '- Use Time Slots to group delivery timings.\n'
                  '- Low balance helps you track who needs recharge.\n'
                  '- Swipe a customer to Edit, Chat or Delete.\n',
                  style: TextStyle(
                    color: subText,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTotalTiffinsOutside(List<CustomerModel> current) {
    final outside = current.where((c) => (c.tiffinCount ?? 0) > 0).toList()
      ..sort((a, b) => (b.tiffinCount ?? 0).compareTo(a.tiffinCount ?? 0));
    final total = outside.fold<int>(0, (s, c) => s + (c.tiffinCount ?? 0));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TiffinsOutsideScreen(customers: outside, total: total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searched = _query.isEmpty
        ? _customers
        : _customers.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.phone.contains(_query) ||
                (c.email?.toLowerCase().contains(q) ?? false);
          }).toList();

    final filtered = _applyLocalFiltersAndSort(searched);

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
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _openMoreMenu(filtered),
            tooltip: 'More',
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
                // Added: Sort / Status / Time Slot dropdown pills (local-only)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      _dropdownPill(
                        label: _sortLabel(),
                        onTap: () => _openSortSheet(context, searched),
                      ),
                      const SizedBox(width: 8),
                      _dropdownPill(
                        label: _mainFilterLabel(),
                        onTap: () => _openMainFilterSheet(context),
                      ),
                      const SizedBox(width: 8),
                      _dropdownPill(
                        label: _statusLabel(),
                        onTap: () => _openStatusSheet(context, searched),
                      ),
                      const SizedBox(width: 8),
                      _dropdownPill(
                        label: _timeSlotsLabel(),
                        onTap: () => _openTimeSlotsSheet(context, searched),
                      ),
                    ],
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
                            separatorBuilder: (context, index) => const Divider(
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
                                  fields: _cardFields,
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
    required this.fields,
    required this.onTap,
    required this.onEdit,
    required this.onWhatsApp,
    required this.onDelete,
  });

  final CustomerModel customer;
  final Set<_CardField> fields;
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
    final showName = fields.contains(_CardField.name);
    final showPhone = fields.contains(_CardField.phone);
    final showArea = fields.contains(_CardField.area);
    final showBalance = fields.contains(_CardField.balance);

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
                            if (showName)
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
                            if (showPhone) ...[
                              const SizedBox(height: 2),
                              Text(
                                customer.phone,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                            if (showArea && hasArea) ...[
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
                      if (showBalance)
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

// ─────────────────────────────────────────────────────────────────────────────
// Customer menu helpers / screens (added feature)
// ─────────────────────────────────────────────────────────────────────────────

enum _CardField { name, phone, area, balance }

extension _CardFieldX on _CardField {
  String get key => switch (this) {
        _CardField.name => 'name',
        _CardField.phone => 'phone',
        _CardField.area => 'area',
        _CardField.balance => 'balance',
      };

  String get label => switch (this) {
        _CardField.name => 'Name',
        _CardField.phone => 'Phone',
        _CardField.area => 'Zone/Area',
        _CardField.balance => 'Balance',
      };

  static _CardField? tryParse(String raw) {
    switch (raw) {
      case 'name':
        return _CardField.name;
      case 'phone':
        return _CardField.phone;
      case 'area':
        return _CardField.area;
      case 'balance':
        return _CardField.balance;
      default:
        return null;
    }
  }
}

final class _CustomerAnalyticsScreen extends StatelessWidget {
  const _CustomerAnalyticsScreen({required this.customers});

  final List<CustomerModel> customers;

  @override
  Widget build(BuildContext context) {
    int countWhere(bool Function(CustomerModel) test) =>
        customers.where(test).length;

    final active =
        countWhere((c) => (c.status).toLowerCase() == 'active');
    final paused = countWhere((c) => (c.status).toLowerCase() == 'paused');
    final blocked = countWhere((c) => (c.status).toLowerCase() == 'blocked');
    final lowBal = countWhere((c) => c.effectiveWalletBalance < 100);

    final veg =
        countWhere((c) => (c.dietType ?? '').toLowerCase().contains('veg'));
    final nonVeg = countWhere((c) {
      final d = (c.dietType ?? '').toLowerCase();
      return d.contains('non') || d.contains('nv');
    });

    final zones = <String, int>{};
    for (final c in customers) {
      final z = (c.area ?? '').trim();
      if (z.isEmpty) continue;
      zones[z] = (zones[z] ?? 0) + 1;
    }
    final zoneList = zones.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget card(String label, String value) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.s200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _P.s900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _P.s600,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.g1,
        foregroundColor: Colors.white,
        title: const Text('Customer Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(child: card('Total customers', '${customers.length}')),
              const SizedBox(width: 10),
              Expanded(child: card('Low balance', '$lowBal')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: card('Active', '$active')),
              const SizedBox(width: 10),
              Expanded(child: card('Paused', '$paused')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: card('Blocked', '$blocked')),
              const SizedBox(width: 10),
              Expanded(child: card('Veg / Non-Veg', '$veg / $nonVeg')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Zone wise distribution',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _P.s600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          if (zoneList.isEmpty)
            const Text(
              'No zones available',
              style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
            )
          else
            ...zoneList.take(12).map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _P.s200, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _P.s900,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _P.v700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

final class _ArchivedCustomersScreen extends StatelessWidget {
  const _ArchivedCustomersScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.g1,
        foregroundColor: Colors.white,
        title: const Text('Archived Customers'),
      ),
      body: const Center(
        child: Text(
          'No archived customers yet',
          style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

final class _ImportCustomersScreen extends StatefulWidget {
  const _ImportCustomersScreen({required this.onImported});

  final void Function(List<CustomerModel>) onImported;

  @override
  State<_ImportCustomersScreen> createState() => _ImportCustomersScreenState();
}

final class _ImportCustomersScreenState extends State<_ImportCustomersScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, String>> _preview = const [];
  bool _importing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> _parseCsv(String csv) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    List<String> splitLine(String line) {
      final out = <String>[];
      final buf = StringBuffer();
      var inQuotes = false;
      for (var i = 0; i < line.length; i += 1) {
        final ch = line[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
          continue;
        }
        if (ch == ',' && !inQuotes) {
          out.add(buf.toString().trim());
          buf.clear();
          continue;
        }
        buf.write(ch);
      }
      out.add(buf.toString().trim());
      return out;
    }

    final headers = splitLine(lines.first).map((e) => e.toLowerCase()).toList();
    final rows = <Map<String, String>>[];
    for (final l in lines.skip(1)) {
      final cells = splitLine(l);
      final m = <String, String>{};
      for (var i = 0; i < headers.length && i < cells.length; i += 1) {
        m[headers[i]] = cells[i];
      }
      rows.add(m);
    }
    return rows;
  }

  void _updatePreview() {
    setState(() => _preview = _parseCsv(_ctrl.text));
  }

  Future<void> _import() async {
    if (_preview.isEmpty || _importing) return;
    setState(() => _importing = true);
    try {
      final result = await CustomerApi.bulkImportCsv(_ctrl.text.trim());
      final rawCustomers = result['customers'];
      final items = <CustomerModel>[];
      if (rawCustomers is List) {
        for (final e in rawCustomers) {
          if (e is CustomerModel) items.add(e);
        }
      }
      final imported = (result['imported'] as int?) ?? 0;
      final skipped = (result['skipped'] as int?) ?? 0;
      final warnings = result['warnings'];
      if (!mounted) return;
      widget.onImported(items);
      var msg = 'Imported $imported customer${imported == 1 ? '' : 's'}';
      if (skipped > 0) msg += ' ($skipped skipped)';
      if (warnings is List && warnings.isNotEmpty) {
        msg += '. ${warnings.length} zone name(s) did not match — customers were added without a zone.';
      }
      AppSnackbar.success(context, msg);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.g1,
        foregroundColor: Colors.white,
        title: const Text('Import Bulk Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Paste CSV data',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _P.s900,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'name,phone,address,zone\nJohn,9876543210,Street 1,Zone A',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _updatePreview(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preview',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _P.s900,
            ),
          ),
          const SizedBox(height: 8),
          if (_preview.isEmpty)
            const Text(
              'No rows found',
              style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
            )
          else
            ..._preview.take(8).map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _P.s200, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (r['name'] ?? '').isEmpty ? '(missing name)' : r['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _P.s900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (r['phone'] ?? r['mobile'] ?? '').toString(),
                          style: const TextStyle(color: _P.s600),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_preview.isEmpty || _importing) ? null : _import,
            style: FilledButton.styleFrom(
              backgroundColor: _P.g1,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _importing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirm Import',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

final class _TiffinsOutsideScreen extends StatelessWidget {
  const _TiffinsOutsideScreen({required this.customers, required this.total});

  final List<CustomerModel> customers;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.g1,
        foregroundColor: Colors.white,
        title: const Text('Total Tiffins Outside'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.s200, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: _P.v700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Total outside',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _P.s900,
                    ),
                  ),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _P.v700,
                    fontSize: 18,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (customers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'No tiffins outside right now',
                  style: TextStyle(color: _P.s600, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...customers.map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _P.s200, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _P.s900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.area ?? '',
                            style: const TextStyle(color: _P.s600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${c.tiffinCount ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _P.v700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
