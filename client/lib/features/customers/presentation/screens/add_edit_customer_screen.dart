import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../../../models/customer_model.dart';
import '../../data/customer_api.dart';
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
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _areaController = TextEditingController(text: c?.area ?? '');
    _landmarkController = TextEditingController(text: c?.landmark ?? '');
    _whatsappController = TextEditingController(text: c?.whatsapp ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _tagsController = TextEditingController(
      text: c?.tags?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _whatsappController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
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
            final digits = phone.replaceAll(RegExp(r'\D'), '');
            _phoneController.text = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
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

  Future<void> _bulkImportFromContacts() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    if (!status.isGranted) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => ContactsPermissionSheet(onCancel: () => Navigator.pop(ctx)),
      );
      return;
    }
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;
      final list = <Map<String, String>>[];
      for (final c in contacts) {
        if (c.phones.isEmpty) continue;
        final digits = c.phones.first.number.replaceAll(RegExp(r'\D'), '');
        final phone = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
        if (phone.length >= 10) list.add({'name': c.displayName, 'phone': phone, 'address': ''});
      }
      if (list.length > 100) list.removeRange(100, list.length);
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts with valid phone numbers')),
        );
        return;
      }
      final result = await CustomerApi.bulkImport(list);
      final imported = result['imported'] as int? ?? 0;
      final skipped = result['skipped'] as int? ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$imported imported, $skipped skipped (duplicates)')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 10 digit phone number')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': phone,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'area': _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
        'landmark': _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
        'whatsapp': _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim().replaceAll(RegExp(r'\D'), ''),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'status': 'active',
      };
      if (_emailController.text.trim().isNotEmpty) body['email'] = _emailController.text.trim();
      final tagsStr = _tagsController.text.trim();
      if (tagsStr.isNotEmpty) {
        body['tags'] = tagsStr.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
      }
      if (widget._isEditMode) {
        await CustomerApi.update(widget.customer!.id, body);
      } else {
        await CustomerApi.create(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget._isEditMode ? 'Customer updated' : 'Customer added')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _bulkImportFromContacts,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Bulk import from contacts'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(labelText: 'Landmark (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(labelText: 'WhatsApp number (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated, optional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget._isEditMode ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
