import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../reports/data/report_api.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  Map<String, dynamic> _summary = {};
  List<dynamic> _todayDeliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await ReportApi.getSummary();
      final today = await ReportApi.getTodayDeliveries();
      if (mounted) {
        setState(() {
          _summary = summary;
          _todayDeliveries = List<dynamic>.from(today);
        });
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Summary'),
          const SizedBox(height: 8),
          if (_summary.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No summary data',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _summary.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            e.value?.toString() ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Today's deliveries"),
          const SizedBox(height: 8),
          if (_todayDeliveries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No deliveries for today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._todayDeliveries.map((e) {
              final map = e is Map<String, dynamic> ? e : <String, dynamic>{};
              final title = map['customerName']?.toString() ??
                  map['customerId']?.toString() ??
                  'Delivery';
              final subtitle = map['status']?.toString() ??
                  map['address']?.toString() ??
                  '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}
