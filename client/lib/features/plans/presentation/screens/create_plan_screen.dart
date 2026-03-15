import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../items/data/item_api.dart';
import '../../../items/models/item_model.dart';
import '../../data/plan_api.dart';
import '../../models/plan_model.dart';

const List<String> _planTypes = ['monthly', 'weekly', 'daily'];
const List<String> _slotLabels = ['breakfast', 'lunch', 'dinner', 'evening'];

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key, this.plan});

  final PlanModel? plan;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  late String _planType;
  String? _color;
  final Set<String> _selectedSlots = {};
  final Map<String, List<MealSlotItemModel>> _slotItems = {};
  bool _isActive = true;
  bool _saving = false;
  List<ItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _nameController.text = p.planName;
      _priceController.text = p.price.toStringAsFixed(0);
      _planType = p.planType;
      _color = p.color;
      _isActive = p.isActive;
      for (final slot in p.mealSlots) {
        _selectedSlots.add(slot.slot);
        _slotItems[slot.slot] = List.from(slot.items);
      }
    } else {
      _planType = 'monthly';
    }
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final list = await ItemApi.list(limit: 100, isActive: true);
      if (mounted) setState(() => _items = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final mealSlots = _selectedSlots.map((slot) {
      final items = _slotItems[slot] ?? [];
      return {
        'slot': slot,
        'items': items.map((e) => e.toJson()).toList(),
      };
    }).toList();
    return {
      'planName': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'planType': _planType,
      if (_color != null && _color!.isNotEmpty) 'color': _color,
      'mealSlots': mealSlots,
      'isActive': _isActive,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter plan name')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = _buildBody();
      if (widget.plan != null) {
        await PlanApi.update(widget.plan!.id, body);
      } else {
        await PlanApi.create(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.plan != null ? 'Plan updated' : 'Plan created')),
        );
        if (context.mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickItemForSlot(String slot) async {
    if (_items.isEmpty) return;
    final item = await showModalBottomSheet<ItemModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ItemPickerSheet(items: _items),
    );
    if (item == null || !mounted) return;
    setState(() {
      _slotItems[slot] ??= [];
      _slotItems[slot]!.add(MealSlotItemModel(itemId: item.id, itemName: item.name, quantity: 1, unitPrice: item.unitPrice));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.plan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Plan' : 'Create Plan'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plan Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isEdit)
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: 16),
            Text('Plan type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _planTypes.map((t) {
                final selected = _planType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => _planType = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Meal slots', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _slotLabels.map((slot) {
                final selected = _selectedSlots.contains(slot);
                return FilterChip(
                  label: Text(slot[0].toUpperCase() + slot.substring(1)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSlots.add(slot);
                    } else {
                      _selectedSlots.remove(slot);
                      _slotItems.remove(slot);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ..._selectedSlots.map((slot) {
              final items = _slotItems[slot] ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            slot[0].toUpperCase() + slot.substring(1),
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _pickItemForSlot(slot),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add item'),
                          ),
                        ],
                      ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No items',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...items.asMap().entries.map((e) {
                          final idx = e.key;
                          final it = e.value;
                          return ListTile(
                            dense: true,
                            title: Text(it.itemName ?? it.itemId),
                            subtitle: Text('Qty: ${it.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      final list = _slotItems[slot]!;
                                      if (it.quantity > 1) {
                                        list[idx] = MealSlotItemModel(
                                          itemId: it.itemId,
                                          itemName: it.itemName,
                                          quantity: it.quantity - 1,
                                          unitPrice: it.unitPrice,
                                        );
                                      } else {
                                        list.removeAt(idx);
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      final list = _slotItems[slot]!;
                                      list[idx] = MealSlotItemModel(
                                        itemId: it.itemId,
                                        itemName: it.itemName,
                                        quantity: it.quantity + 1,
                                        unitPrice: it.unitPrice,
                                      );
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () {
                                    setState(() => _slotItems[slot]!.removeAt(idx));
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Update Plan' : 'Create Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  const _ItemPickerSheet({required this.items});

  final List<ItemModel> items;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('₹${item.unitPrice} / ${item.unit}'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
