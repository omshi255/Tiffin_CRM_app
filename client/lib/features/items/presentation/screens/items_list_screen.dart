import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
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
  List<ItemModel> _items = [];
  bool _isLoading = true;
  String? _categoryFilter;
  bool? _activeFilter = true;

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
      builder: (ctx) => _AddEditItemBottomSheet(
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
        title: const Text('Delete Item'),
        content: Text('Delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
                        ? ApiException('Cannot delete — used in active plan. Disable it instead.')
                        : e,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ItemModel item, bool value) async {
    final previous = item.isActive;
    setState(() => _items = _items.map((i) => i.id == item.id ? ItemModel(id: i.id, name: i.name, unitPrice: i.unitPrice, unit: i.unit, category: i.category, isActive: value, vendorId: i.vendorId) : i).toList());
    try {
      await ItemApi.update(item.id, {'isActive': value, 'name': item.name, 'unitPrice': item.unitPrice, 'unit': item.unit, 'category': item.category});
    } catch (e) {
      setState(() => _items = _items.map((i) => i.id == item.id ? ItemModel(id: i.id, name: i.name, unitPrice: i.unitPrice, unit: i.unit, category: i.category, isActive: previous, vendorId: i.vendorId) : i).toList());
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'roti': return Icons.breakfast_dining;
      case 'sabji': return Icons.lunch_dining;
      case 'dal': return Icons.soup_kitchen;
      case 'rice': return Icons.rice_bowl;
      default: return Icons.restaurant;
    }
  }

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'roti': return AppColors.warning;
      case 'sabji': return AppColors.success;
      case 'dal': return const Color(0xFF8B4513);
      case 'rice': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Items'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _categoryFilter == null,
                  onTap: () {
                    setState(() => _categoryFilter = null);
                    _load();
                  },
                ),
                ...['roti', 'sabji', 'dal', 'rice', 'other'].map((c) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: _categoryFilter == c,
                    onTap: () {
                      setState(() => _categoryFilter = c);
                      _load();
                    },
                  ),
                )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Active',
                  selected: _activeFilter == true,
                  onTap: () {
                    setState(() => _activeFilter = true);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  selected: _activeFilter == false,
                  onTap: () {
                    setState(() => _activeFilter = false);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No items',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _categoryColor(item.category).withValues(alpha: 0.2),
                                    child: Icon(
                                      _categoryIcon(item.category),
                                      color: _categoryColor(item.category),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '₹${item.unitPrice.toStringAsFixed(0)} per ${item.unit}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(
                                            item.category,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: item.isActive,
                                    onChanged: (v) => _toggleActive(item, v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showAddEditSheet(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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

class _AddEditItemBottomSheet extends StatefulWidget {
  const _AddEditItemBottomSheet({
    this.item,
    required this.onSaved,
    required this.onError,
  });

  final ItemModel? item;
  final VoidCallback onSaved;
  final void Function(dynamic) onError;

  @override
  State<_AddEditItemBottomSheet> createState() => _AddEditItemBottomSheetState();
}

class _AddEditItemBottomSheetState extends State<_AddEditItemBottomSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'piece';
  String _category = 'roti';
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      _nameController.text = i.name;
      _priceController.text = i.unitPrice.toStringAsFixed(0);
      _unit = i.unit;
      _category = i.category;
      _isActive = i.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              Text(
                isEdit ? 'Edit Item' : 'Add Item',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
              ),
              const SizedBox(height: 12),
              Text('Unit', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: 8,
                children: ['piece', 'bowl', 'plate', 'glass', 'other'].map((u) {
                  return ChoiceChip(
                    label: Text(u),
                    selected: _unit == u,
                    onSelected: (_) => setState(() => _unit = u),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Category', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: 8,
                children: ['roti', 'sabji', 'dal', 'rice', 'other'].map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Active', style: theme.textTheme.bodyLarge),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : () async {
                  final name = _nameController.text.trim();
                  final price = double.tryParse(_priceController.text.trim());
                  if (name.isEmpty) {
                    AppSnackbar.error(context, 'Enter name');
                    return;
                  }
                  if (price == null || price < 0) {
                    AppSnackbar.error(context, 'Enter valid price');
                    return;
                  }
                  setState(() => _saving = true);
                  try {
                    if (isEdit) {
                      await ItemApi.update(widget.item!.id, {
                        'name': name,
                        'unitPrice': price,
                        'unit': _unit,
                        'category': _category,
                        'isActive': _isActive,
                      });
                    } else {
                      await ItemApi.create({
                        'name': name,
                        'unitPrice': price,
                        'unit': _unit,
                        'category': _category,
                        'isActive': _isActive,
                      });
                    }
                    if (mounted) widget.onSaved();
                  } catch (e) {
                    if (mounted) widget.onError(e);
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
