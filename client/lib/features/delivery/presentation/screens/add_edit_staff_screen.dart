import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/delivery_api.dart';
import '../../models/delivery_staff_model.dart';

class AddEditStaffScreen extends StatefulWidget {
  const AddEditStaffScreen({super.key, this.staff});

  final DeliveryStaffModel? staff;

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areasController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    if (s != null) {
      _nameController.text = s.name;
      _phoneController.text = s.phone;
      _areasController.text = s.areas.join(', ');
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      AppSnackbar.error(context, 'Name and phone required');
      return;
    }
    final areasStr = _areasController.text.trim();
    final areas = areasStr.isEmpty
        ? <String>[]
        : areasStr.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();

    setState(() => _saving = true);
    try {
      final body = {'name': name, 'phone': phone, 'areas': areas, 'isActive': _isActive};
      if (widget.staff != null) {
        await DeliveryApi.updateStaff(widget.staff!.id, body);
      } else {
        await DeliveryApi.createStaff(body);
      }
      if (mounted) {
        AppSnackbar.success(context, widget.staff != null ? 'Updated' : 'Added');
        if (context.mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.staff != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Staff' : 'Add Delivery Staff'),
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
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areasController,
              decoration: const InputDecoration(
                labelText: 'Areas (comma-separated)',
                hintText: 'Area 1, Area 2',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
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
                  : Text(isEdit ? 'Update' : 'Add Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
