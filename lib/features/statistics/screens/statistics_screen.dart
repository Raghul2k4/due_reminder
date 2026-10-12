import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/category_provider.dart';
import '../../../app/providers/statistics_provider.dart';
import '../../../data/models/category.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = context.watch<StatisticsProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final data = statsProvider.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: statsProvider.isLoading || data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => statsProvider.loadStatistics(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Time Range Segmented Toggle
                  SegmentedButton<StatsTimeRange>(
                    segments: const [
                      ButtonSegment(value: StatsTimeRange.thisMonth, label: Text('This Month')),
                      ButtonSegment(value: StatsTimeRange.thisYear, label: Text('This Year')),
                      ButtonSegment(value: StatsTimeRange.allTime, label: Text('All Time')),
                    ],
                    selected: {statsProvider.timeRange},
                    onSelectionChanged: (set) => statsProvider.setTimeRange(set.first),
                  ),
                  const SizedBox(height: 16),

                  // Key Metrics Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMetricCard(
                        context,
                        title: 'Completed This Month',
                        value: '${data.completedThisMonth}',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _buildMetricCard(
                        context,
                        title: 'Completion Rate',
                        value: '${data.completionRate.toStringAsFixed(0)}%',
                        icon: Icons.pie_chart_outline,
                        color: theme.colorScheme.primary,
                      ),
                      _buildMetricCard(
                        context,
                        title: 'Current Streak',
                        value: '${data.currentStreak} ${data.currentStreak == 1 ? 'day' : 'days'}',
                        icon: Icons.local_fire_department_outlined,
                        color: Colors.orange,
                      ),
                      _buildMetricCard(
                        context,
                        title: 'Most Used Category',
                        value: data.mostUsedCategory?.name ?? 'None',
                        icon: data.mostUsedCategory != null ? Category.getIconData(data.mostUsedCategory!.iconKey) : Icons.category,
                        color: data.mostUsedCategory != null ? Color(data.mostUsedCategory!.colorValue) : theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 12-Week Completion Bar Chart Section
                  Text(
                    '12-Week Completion Activity',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: data.weeklyCompletionHistory.map((item) {
                                int maxVal = data.weeklyCompletionHistory.map((e) => e.count).fold(0, (a, b) => a > b ? a : b);
                                if (maxVal == 0) maxVal = 1;

                                final heightPercent = (item.count / maxVal).clamp(0.05, 1.0);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.count}',
                                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 14,
                                      height: 90 * heightPercent,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('d/M').format(item.date),
                                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown Section
                  Text(
                    'Category Distribution',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (data.categoryCounts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No completion data for the selected period.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: data.categoryCounts.entries.map((entry) {
                            final cat = categoryProvider.getCategoryById(entry.key) ?? Category.defaultCategory;
                            final total = data.categoryCounts.values.fold(0, (a, b) => a + b);
                            final percent = total > 0 ? (entry.value / total) : 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Category.getIconData(cat.iconKey), size: 16, color: Color(cat.colorValue)),
                                          const SizedBox(width: 8),
                                          Text(cat.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Text('${entry.value} (${(percent * 100).toStringAsFixed(0)}%)'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percent,
                                    color: Color(cat.colorValue),
                                    backgroundColor: Color(cat.colorValue).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
