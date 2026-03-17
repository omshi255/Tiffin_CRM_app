import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../models/notification_model.dart';
import '../../data/customer_portal_api.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await CustomerPortalApi.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications =
              (res['notifications'] as List<NotificationModel>?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.show(context, e);
      }
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.read) return;
    try {
      await CustomerPortalApi.markNotificationRead(n.id);
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((e) => e.id == n.id ? NotificationModel(id: e.id, title: e.title, body: e.body, time: e.time, read: true, type: e.type) : e)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: _loading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 48),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You’ll see meal updates and alerts here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          color: n.read
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceContainerLowest,
                          child: InkWell(
                            onTap: () => _markRead(n),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(
                                n.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight:
                                      n.read ? FontWeight.normal : FontWeight.w600,
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
