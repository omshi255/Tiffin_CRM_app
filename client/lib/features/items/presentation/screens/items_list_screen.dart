import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../data/item_api.dart';
import '../../models/item_model.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  // ── Violet palette ────────────────────────────────────────────────────────
  static const _violet900 = Color(0xFF2D1B69);
  static const _violet700 = Color(0xFF4C2DB8);
  static const _violet600 = Color(0xFF5B35D5);
  static const _violet500 = Color(0xFF6C42F5);
  static const _violet100 = Color(0xFFEDE8FD);
  static const _violet50 = Color(0xFFF5F2FF);
  static const _bg = Color(0xFFF6F4FF);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE4DFF7);
  static const _divider = Color(0xFFEEEBFA);
  static const _textPrimary = Color(0xFF1A0E45);
  static const _textSecondary = Color(0xFF7B6DAB);
  static const _success = Color(0xFF0F7B0F);
  static const _successSoft = Color(0xFFE6F4EA);
  static const _danger = Color(0xFFD93025);
  static const _dangerSoft = Color(0xFFFCECEB);

  // ── State ─────────────────────────────────────────────────────────────────
  List<ItemModel> _items = [];
  bool _isLoading = true;
  String? _categoryFilter;
  bool? _activeFilter = true;

  static const _categories = ['roti', 'sabji', 'dal', 'rice', 'other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await ItemApi.list(
        limit: 50,
        isActive: _activeFilter,
        category: _categoryFilter,
      );
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditSheet({ItemModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditItemSheet(
        item: item,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
        onError: (e) => ErrorHandler.show(ctx, e),
      ),
    );
  }

  void _confirmDelete(ItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Item',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ItemApi.delete(item.id);
                if (mounted) {
                  AppSnackbar.success(context, 'Item deleted');
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  final msg = e.toString();
                  ErrorHandler.show(
                    context,
                    msg.contains('active plan') || msg.contains('400')
                        ? ApiException(
                            'Cannot delete — item is used in an active plan. Disable it instead.',
                          )
                        : e,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ItemModel item, bool value) async {
    final prev = item.isActive;
    setState(
      () => _items = _items
          .map(
            (i) => i.id == item.id
                ? ItemModel(
                    id: i.id,
                    name: i.name,
                    unitPrice: i.unitPrice,
                    unit: i.unit,
                    category: i.category,
                    isActive: value,
                    vendorId: i.vendorId,
                  )
                : i,
          )
          .toList(),
    );
    try {
      await ItemApi.update(item.id, {
        'isActive': value,
        'name': item.name,
        'unitPrice': item.unitPrice,
        'unit': item.unit,
        'category': item.category,
      });
    } catch (e) {
      setState(
        () => _items = _items
            .map(
              (i) => i.id == item.id
                  ? ItemModel(
                      id: i.id,
                      name: i.name,
                      unitPrice: i.unitPrice,
                      unit: i.unit,
                      category: i.category,
                      isActive: prev,
                      vendorId: i.vendorId,
                    )
                  : i,
            )
            .toList(),
      );
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  // ── Category meta ─────────────────────────────────────────────────────────
  static (IconData, Color, Color) _catMeta(String cat) {
    switch (cat.toLowerCase()) {
      case 'roti':
        return (Icons.breakfast_dining, Color(0xFF854F0B), Color(0xFFFAEEDA));
      case 'sabji':
        return (Icons.lunch_dining, Color(0xFF3B6D11), Color(0xFFEAF3DE));
      case 'dal':
        return (Icons.soup_kitchen, Color(0xFF8B4513), Color(0xFFF5EBE0));
      case 'rice':
        return (Icons.rice_bowl, Color(0xFF4C2DB8), Color(0xFFEDE8FD));
      default:
        return (Icons.restaurant_rounded, Color(0xFF6B7A99), Color(0xFFF1F0F8));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _violet700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Menu Items',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_items.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
        // Filter strip in AppBar bottom
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Container(
            color: _violet700,
            child: Column(
              children: [
                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'All',
                        selected: _categoryFilter == null,
                        onTap: () {
                          setState(() => _categoryFilter = null);
                          _load();
                        },
                      ),
                      ..._categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _Chip(
                            label: c[0].toUpperCase() + c.substring(1),
                            selected: _categoryFilter == c,
                            onTap: () {
                              setState(() => _categoryFilter = c);
                              _load();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Active/Inactive filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Active',
                        selected: _activeFilter == true,
                        onTap: () {
                          setState(() => _activeFilter = true);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'Inactive',
                        selected: _activeFilter == false,
                        onTap: () {
                          setState(() => _activeFilter = false);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'All Status',
                        selected: _activeFilter == null,
                        onTap: () {
                          setState(() => _activeFilter = null);
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: _violet600,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _violet600,
                strokeWidth: 2.5,
              ),
            )
          : _items.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _violet600,
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _items.length,
                itemBuilder: (ctx, i) => _buildItemCard(_items[i]),
              ),
            ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _violet100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            size: 36,
            color: _violet600,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No items found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap + Add Item to get started',
          style: TextStyle(fontSize: 13, color: _textSecondary),
        ),
      ],
    ),
  );

  // ── Item card ─────────────────────────────────────────────────────────────
  Widget _buildItemCard(ItemModel item) {
    final (icon, iconColor, iconBg) = _catMeta(item.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _violet900.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Main row ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                  const SizedBox(width: 12),

                  // Name + price + category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '₹${item.unitPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _violet700,
                              ),
                            ),
                            Text(
                              ' / ${item.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Active toggle
                  GestureDetector(
                    onTap: () => _toggleActive(item, !item.isActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 26,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: item.isActive
                            ? _violet600
                            : const Color(0xFFD0C8E8),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: item.isActive
                              ? _violet700
                              : const Color(0xFFB0A8D0),
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: item.isActive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.isActive
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 10,
                            color: item.isActive
                                ? _violet600
                                : const Color(0xFFB0A8D0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider + action row ─────────────────────────────────────────
            Divider(
              color: _divider,
              height: 1,
              thickness: 1,
              indent: 14,
              endIndent: 14,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Status indicator
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.isActive ? _successSoft : _dangerSoft,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: item.isActive
                                ? _success.withValues(alpha: 0.25)
                                : _danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: item.isActive ? _success : _danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: item.isActive ? _success : _danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edit
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: _violet600,
                    bg: _violet50,
                    onTap: () => _showAddEditSheet(item: item),
                  ),
                  // Delete
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: _danger,
                    bg: _dangerSoft,
                    onTap: () => _confirmDelete(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? const Color(0xFF4C2DB8) : Colors.white,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddEditItemSheet extends StatefulWidget {
  const _AddEditItemSheet({
    this.item,
    required this.onSaved,
    required this.onError,
  });
  final ItemModel? item;
  final VoidCallback onSaved;
  final void Function(dynamic) onError;

  @override
  State<_AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<_AddEditItemSheet> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _violet700 = Color(0xFF4C2DB8);
  static const _violet600 = Color(0xFF5B35D5);
  static const _violet500 = Color(0xFF6C42F5);
  static const _violet100 = Color(0xFFEDE8FD);
  static const _violet50 = Color(0xFFF5F2FF);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE4DFF7);
  static const _divider = Color(0xFFEEEBFA);
  static const _textPrimary = Color(0xFF1A0E45);
  static const _textSecondary = Color(0xFF7B6DAB);
  static const _success = Color(0xFF0F7B0F);
  static const _successSoft = Color(0xFFE6F4EA);

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _unit = 'piece';
  String _category = 'roti';
  bool _isActive = true;
  bool _saving = false;

  static const _units = ['piece', 'bowl', 'plate', 'glass', 'other'];
  static const _categories = ['roti', 'sabji', 'dal', 'rice', 'other'];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      _nameCtrl.text = i.name;
      _priceCtrl.text = i.unitPrice.toStringAsFixed(0);
      _unit = i.unit;
      _category = i.category;
      _isActive = i.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty) {
      AppSnackbar.error(context, 'Name is required');
      return;
    }
    if (price == null || price < 0) {
      AppSnackbar.error(context, 'Enter a valid price');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'name': name,
        'unitPrice': price,
        'unit': _unit,
        'category': _category,
        'isActive': _isActive,
      };
      if (widget.item != null) {
        await ItemApi.update(widget.item!.id, body);
      } else {
        await ItemApi.create(body);
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) widget.onError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _violet100,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 18,
                    color: _violet700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Item' : 'Add Menu Item',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            _sheetField(_nameCtrl, 'Item Name', Icons.restaurant_outlined),
            const SizedBox(height: 10),

            // Price field
            _sheetField(
              _priceCtrl,
              'Unit Price (₹)',
              Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),

            // Unit chips
            _sheetLabel('Unit'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _units
                  .map(
                    (u) => _ChoiceChip(
                      label: u,
                      selected: _unit == u,
                      onTap: () => setState(() => _unit = u),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Category chips
            _sheetLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (c) => _ChoiceChip(
                      label: c[0].toUpperCase() + c.substring(1),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Status toggle row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _violet50,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isActive ? _successSoft : _divider,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _isActive
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      size: 16,
                      color: _isActive ? _success : _textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isActive ? 'Item is Active' : 'Item is Inactive',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isActive = !_isActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 26,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _isActive ? _violet600 : const Color(0xFFD0C8E8),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _isActive
                              ? _violet700
                              : const Color(0xFFB0A8D0),
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _isActive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isActive
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 10,
                            color: _isActive
                                ? _violet600
                                : const Color(0xFFB0A8D0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_violet700, _violet500],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _violet600.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? 'Save Changes' : 'Add Item',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: _textSecondary),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, size: 17, color: _violet600),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: _violet50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _violet500, width: 1.5),
      ),
    ),
  );

  Widget _sheetLabel(String text) => Row(
    children: [
      Container(
        width: 3,
        height: 12,
        decoration: BoxDecoration(
          color: _violet600,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Choice chip
// ─────────────────────────────────────────────────────────────────────────────

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _violet700 = Color(0xFF4C2DB8);
  static const _violet600 = Color(0xFF5B35D5);
  static const _violet50 = Color(0xFFF5F2FF);
  static const _border = Color(0xFFE4DFF7);
  static const _textPrimary = Color(0xFF1A0E45);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _violet600 : _violet50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _violet700 : _border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _textPrimary,
        ),
      ),
    ),
  );
}
