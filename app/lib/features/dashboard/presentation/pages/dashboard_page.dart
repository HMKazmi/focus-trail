import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_provider.dart';
import '../../../tasks/data/datasource/task_remote_datasource.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data on init
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Period selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select period',
            onSelected: (period) => ref.read(dashboardProvider.notifier).changePeriod(period),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'day',
                child: Row(
                  children: [
                    if (state.selectedPeriod == 'day')
                      Icon(Icons.check, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Today'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    if (state.selectedPeriod == 'week')
                      Icon(Icons.check, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('This Week'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    if (state.selectedPeriod == 'month')
                      Icon(Icons.check, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('This Month'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : () => ref.read(dashboardProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.stats == null
          ? _buildLoadingShimmer(context)
          : state.error != null && state.stats == null
              ? _buildError(context, state.error!)
              : RefreshIndicator(
                  onRefresh: () => ref.read(dashboardProvider.notifier).load(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards row
                        _buildStatsRow(context, state.stats),
                        const SizedBox(height: 24),

                        // Streak and completion rate
                        _buildStreakAndCompletion(context, state.stats),
                        const SizedBox(height: 24),

                        // Status distribution pie chart
                        _buildSectionTitle(context, 'Task Distribution'),
                        const SizedBox(height: 12),
                        _buildStatusPieChart(context, state.stats),
                        const SizedBox(height: 24),

                        // Completion trend chart
                        _buildSectionTitle(context, 'Completion Trend'),
                        const SizedBox(height: 12),
                        _buildCompletionTrendChart(context, state.completionTrend),
                        const SizedBox(height: 24),

                        // Created vs completed chart
                        _buildSectionTitle(context, 'Created vs Completed'),
                        const SizedBox(height: 12),
                        _buildCreatedVsCompletedChart(context, state.createdVsCompletedTrend),
                        const SizedBox(height: 24),

                        // Priority distribution
                        _buildSectionTitle(context, 'Priority Breakdown'),
                        const SizedBox(height: 12),
                        _buildPriorityBars(context, state.stats),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStatsRow(BuildContext context, DashboardStats? stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              width: cardWidth,
              title: 'Total Tasks',
              value: '${stats?.total ?? 0}',
              icon: Icons.list_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Completed Today',
              value: '${stats?.completedToday ?? 0}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Overdue',
              value: '${stats?.overdue ?? 0}',
              icon: Icons.warning_amber,
              color: Colors.red,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Due Soon',
              value: '${stats?.dueSoon ?? 0}',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakAndCompletion(BuildContext context, DashboardStats? stats) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 400;
    
    // On narrow screens, use a horizontal scrollable row or wrap
    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStreakCard(context, stats, cs),
            const SizedBox(width: 12),
            _buildCompletionRateCard(context, stats, cs),
            const SizedBox(width: 12),
            _buildAvgCompletionCard(context, stats, cs),
          ],
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildStreakCard(context, stats, cs)),
        const SizedBox(width: 12),
        Expanded(child: _buildCompletionRateCard(context, stats, cs)),
        const SizedBox(width: 12),
        Expanded(child: _buildAvgCompletionCard(context, stats, cs)),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, DashboardStats? stats, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                const SizedBox(width: 6),
                Text(
                  '${stats?.streak ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Day Streak',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateCard(BuildContext context, DashboardStats? stats, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: (stats?.completionRate ?? 0) / 100,
                    strokeWidth: 5,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                ),
                Text(
                  '${stats?.completionRate.toStringAsFixed(0) ?? 0}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Completion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgCompletionCard(BuildContext context, DashboardStats? stats, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 6),
                Text(
                  stats?.avgCompletionTime != null
                      ? '${stats!.avgCompletionTime!.toStringAsFixed(1)}h'
                      : '-',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Avg. Time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context, DashboardStats? stats) {
    final cs = Theme.of(context).colorScheme;
    final todo = stats?.todo ?? 0;
    final inProgress = stats?.inProgress ?? 0;
    final done = stats?.done ?? 0;
    final total = todo + inProgress + done;

    if (total == 0) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            'No tasks yet',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Pie chart
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: todo.toDouble(),
                        title: todo > 0 ? '$todo' : '',
                        color: Colors.blue,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: inProgress.toDouble(),
                        title: inProgress > 0 ? '$inProgress' : '',
                        color: Colors.orange,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: done.toDouble(),
                        title: done > 0 ? '$done' : '',
                        color: Colors.green,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Legend
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: Colors.blue, label: 'To Do', value: todo),
                  const SizedBox(height: 8),
                  _LegendItem(color: Colors.orange, label: 'In Progress', value: inProgress),
                  const SizedBox(height: 8),
                  _LegendItem(color: Colors.green, label: 'Done', value: done),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionTrendChart(BuildContext context, List<TrendDataPoint> trend) {
    final cs = Theme.of(context).colorScheme;

    if (trend.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            'No completion data yet',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxY = trend.isEmpty ? 5.0 : (trend.map((e) => e.count).reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dataPoint = trend[groupIndex];
                    return BarTooltipItem(
                      '${_formatDateShort(dataPoint.date)}\n${dataPoint.count} completed',
                      TextStyle(color: cs.onPrimaryContainer, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= trend.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatDateShort(trend[value.toInt()].date),
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == maxY) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: cs.outlineVariant.withAlpha(50),
                  strokeWidth: 1,
                ),
              ),
              barGroups: trend.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: cs.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatedVsCompletedChart(BuildContext context, List<TrendDataPoint> trend) {
    final cs = Theme.of(context).colorScheme;

    if (trend.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            'No data yet',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final allValues = trend.expand((e) => [e.created ?? 0, e.completed ?? 0]).toList();
    final maxY = allValues.isEmpty ? 5.0 : (allValues.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isCreated = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isCreated ? 'Created' : 'Completed'}: ${spot.y.toInt()}',
                            TextStyle(color: isCreated ? Colors.blue : Colors.green, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withAlpha(50),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= trend.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatDateShort(trend[value.toInt()].date),
                              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Created line
                    LineChartBarData(
                      spots: trend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), (e.value.created ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(30),
                      ),
                    ),
                    // Completed line
                    LineChartBarData(
                      spots: trend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), (e.value.completed ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.blue, label: 'Created', value: null),
                const SizedBox(width: 24),
                _LegendItem(color: Colors.green, label: 'Completed', value: null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBars(BuildContext context, DashboardStats? stats) {
    final low = stats?.lowPriority ?? 0;
    final medium = stats?.mediumPriority ?? 0;
    final high = stats?.highPriority ?? 0;
    final total = low + medium + high;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PriorityBar(
              label: 'Low',
              value: low,
              total: total,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _PriorityBar(
              label: 'Medium',
              value: medium,
              total: total,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _PriorityBar(
              label: 'High',
              value: high,
              total: total,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MM/dd').format(date);
    } catch (_) {
      return dateStr.length > 5 ? dateStr.substring(5) : dateStr;
    }
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int? value;

  const _LegendItem({required this.color, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value != null ? '$label ($value)' : label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _PriorityBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
