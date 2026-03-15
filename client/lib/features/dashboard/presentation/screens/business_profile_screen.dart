import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: 'Tiffin Service Mumbai',
              decoration: const InputDecoration(labelText: 'Business name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '42, Lamington Road, Grant Road East, Mumbai 400007',
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '+91 9876543210',
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: 'contact@tiffinservice.com',
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '27AABCU9603R1ZM',
              decoration: const InputDecoration(labelText: 'GST number (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
