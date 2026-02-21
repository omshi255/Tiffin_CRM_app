import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../core/theme/app_colors.dart';

/// Button to import name & phone from device contacts.
/// Requests permission before opening the native contact picker.
class ImportContactButton extends StatefulWidget {
  const ImportContactButton({
    super.key,
    required this.onImported,
  });

  final void Function(String fullName, String phoneNumber, String? email)
      onImported;

  @override
  State<ImportContactButton> createState() => _ImportContactButtonState();
}

class _ImportContactButtonState extends State<ImportContactButton> {
  bool _isLoading = false;

  Future<void> _pickContact() async {
    setState(() => _isLoading = true);

    try {
      // Request permission (required before opening picker on some devices)
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          _showError('Contact permission is required to import.');
        }
        return;
      }

      // Open native contact picker - user selects one contact
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || !mounted) return;

      // Fetch full contact details (phones, emails)
      final fullContact =
          await FlutterContacts.getContact(contact.id, withProperties: true);
      if (fullContact == null || !mounted) return;

      final fullName = fullContact.displayName;
      final phone = fullContact.phones.isNotEmpty
          ? fullContact.phones.first.number.replaceAll(RegExp(r'\D'), '')
          : '';
      final email = fullContact.emails.isNotEmpty
          ? fullContact.emails.first.address
          : null;

      if (fullName.isEmpty && phone.isEmpty) {
        if (mounted) _showError('Selected contact has no name or phone.');
        return;
      }

      if (phone.isEmpty) {
        if (mounted) _showError('Selected contact has no phone number.');
        return;
      }

      widget.onImported(
        fullName.isNotEmpty ? fullName : 'Unknown',
        phone,
        email,
      );
    } on Exception catch (e) {
      if (mounted) _showError('Could not import contact: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _pickContact,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(Icons.contacts_outlined),
      label: Text(_isLoading ? 'Opening contacts...' : 'Import from contacts'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
