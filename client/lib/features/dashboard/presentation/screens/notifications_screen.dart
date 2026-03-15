import 'package:flutter/material.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: mockNotifications.length,
        itemBuilder: (context, index) {
          final n = mockNotifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: n.read
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerLowest,
            child: ListTile(
              title: Text(
                n.title,
                style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
                    ),
              ),
              subtitle: Text(
                n.body,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              trailing: Text(
                _formatTime(n.time),
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
