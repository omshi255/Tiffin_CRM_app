import 'package:flutter/material.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = mockReportsData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportTab(
            periodLabel: 'Daily',
            revenue: data.dailyRevenue,
          ),
          _ReportTab(
            periodLabel: 'Weekly',
            revenue: data.weeklyRevenue,
          ),
          _ReportTab(
            periodLabel: 'Monthly',
            revenue: data.monthlyRevenue,
          ),
        ],
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({
    required this.periodLabel,
    required this.revenue,
  });

  final String periodLabel;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$periodLabel Analytics',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue',
                    style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${revenue.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subscription Analytics',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 30,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final i = value.toInt();
                        if (i >= 0 && i < labels.length) {
                          return Text(labels[i], style: theme.textTheme.bodySmall);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 18, color: AppColors.primary)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 22, color: AppColors.primary)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 20, color: AppColors.primary)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 24, color: AppColors.primary)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 26, color: AppColors.primary)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 15, color: AppColors.primary)]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 12, color: AppColors.primary)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
