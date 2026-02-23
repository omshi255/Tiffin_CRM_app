import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../../../models/customer_model.dart';
import '../widgets/contact_picker_bottom_sheet.dart';
import '../widgets/contacts_permission_sheet.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({super.key, this.customer});

  final CustomerModel? customer;

  bool get _isEditMode => customer != null;

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _importFromContacts() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (status.isGranted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ContactPickerBottomSheet(
          onContactSelected: (name, phone) {
            _nameController.text = name;
            _phoneController.text = phone;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact imported successfully')),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => ContactsPermissionSheet(
          onCancel: () => Navigator.pop(ctx),
        ),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // API_INTEGRATION
    // Endpoint: POST /api/customers (create) or PUT /api/customers/:id (update)
    // Purpose: Create or update customer
    // Request: { name: String, phone: String, email?: String, address?: String }
    // Response: { id: String, name: String, ... }
    if (widget._isEditMode) {
      context.pop();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._isEditMode ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget._isEditMode) ...[
                OutlinedButton.icon(
                  onPressed: _importFromContacts,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Import from Contacts'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: ThinDivider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: ThinDivider()),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Enter phone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(widget._isEditMode ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
