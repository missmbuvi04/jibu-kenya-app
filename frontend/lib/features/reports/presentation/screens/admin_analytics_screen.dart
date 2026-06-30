import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/reports_provider.dart';
import '../widgets/officer_web_shell.dart';
import 'admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return OfficerWebShell(
      pageTitle: 'Analytics',
      pageSubtitle: 'Infrastructure damage analysis across all counties',
      selectedIndex: 4,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text('No report data available yet.',
                  style: TextStyle(color: AppColors.grey, fontSize: 15)),
            );
          }

          // ── Computed data ──────────────────────────────────────────
          final categories = ['roads', 'water', 'bridges', 'streetlights', 'public_facilities', 'safety', 'other'];
          final categoryLabels = {
            'roads': 'Roads', 'water': 'Water', 'bridges': 'Bridges',
            'streetlights': 'Lights', 'public_facilities': 'Facilities',
            'safety': 'Safety', 'other': 'Other',
          };
          final categoryCounts = {for (var c in categories) c: reports.where((r) => r.category == c).length};

          final statusColors = {
            'submitted': AppColors.amber,
            'assigned': AppColors.purple,
            'in_progress': AppColors.teal,
            'resolved': AppColors.green,
            'closed': AppColors.grey,
          };
          final statusLabels = {
            'submitted': 'Submitted', 'assigned': 'Assigned',
            'in_progress': 'In Progress', 'resolved': 'Resolved', 'closed': 'Closed',
          };
          final statusCounts = statusLabels.keys.map((s) =>
              MapEntry(s, reports.where((r) => r.status == s).length)).toList();

          final countyCounts = <String, int>{};
          for (final r in reports) {
            countyCounts[r.county] = (countyCounts[r.county] ?? 0) + 1;
          }
          final topCounties = countyCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5 = topCounties.take(5).toList();

          final resolved = reports.where((r) => r.status == 'resolved').length;
          final resolutionRate = reports.isEmpty ? 0.0 : resolved / reports.length;

          // Weekly trend
          final now = DateTime.now();
          final weekCounts = List.filled(6, 0);
          for (final r in reports) {
            try {
              final created = DateTime.parse(r.createdAt);
              final weeksAgo = now.difference(created).inDays ~/ 7;
              if (weeksAgo < 6) weekCounts[5 - weeksAgo]++;
            } catch (_) {}
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Resolution Rate + Status Breakdown ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resolution rate card
                  Expanded(
                    flex: 1,
                    child: _card(
                      title: 'Resolution Rate',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(resolutionRate * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.green),
                          ),
                          const SizedBox(height: 8),
                          Text('$resolved of ${reports.length} reports resolved',
                              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: resolutionRate,
                              backgroundColor: AppColors.lightBg,
                              color: AppColors.green,
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Status breakdown legend
                          ...statusCounts.map((entry) {
                            final color = statusColors[entry.key] ?? AppColors.grey;
                            final label = statusLabels[entry.key] ?? entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.dark))),
                                Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.dark)),
                              ]),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Status pie chart
                  Expanded(
                    flex: 2,
                    child: _card(
                      title: 'Reports by Status',
                      child: SizedBox(
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: statusCounts
                                .where((e) => e.value > 0)
                                .map((e) => PieChartSectionData(
                                      value: e.value.toDouble(),
                                      color: statusColors[e.key] ?? AppColors.grey,
                                      title: '${e.value}',
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      radius: 80,
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Row 2: Reports by Category ──────────────────────────
              _card(
                title: 'Reports by Infrastructure Category',
                child: SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (categoryCounts.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.grey)))),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              final key = categories[v.toInt()];
                              return Padding(padding: const EdgeInsets.only(top: 4),
                                  child: Text(categoryLabels[key] ?? key, style: const TextStyle(fontSize: 10, color: AppColors.grey)));
                            })),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.lightBg, strokeWidth: 1)),
                      borderData: FlBorderData(show: false),
                      barGroups: categories.asMap().entries.map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [BarChartRodData(
                              toY: categoryCounts[e.value]!.toDouble(),
                              color: AppColors.teal,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            )],
                          )).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Row 3: Top Counties + Weekly Trend ─────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top counties
                  Expanded(
                    flex: 1,
                    child: _card(
                      title: 'Top 5 Counties by Reports',
                      child: Column(
                        children: top5.map((entry) {
                          final maxVal = top5.first.value;
                          final ratio = maxVal == 0 ? 0.0 : entry.value / maxVal;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key, style: const TextStyle(fontSize: 13, color: AppColors.dark)),
                                      Text('${entry.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.teal)),
                                    ]),
                                const SizedBox(height: 4),
                                ClipRRect(borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(value: ratio, backgroundColor: AppColors.lightBg, color: AppColors.teal, minHeight: 8)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Weekly trend
                  Expanded(
                    flex: 2,
                    child: _card(
                      title: 'Reports Submitted — Last 6 Weeks',
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.lightBg, strokeWidth: 1)),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.grey)))),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                                  getTitlesWidget: (v, _) {
                                    final weeksAgo = 5 - v.toInt();
                                    return Padding(padding: const EdgeInsets.only(top: 4),
                                        child: Text(weeksAgo == 0 ? 'This\nweek' : '-${weeksAgo}w',
                                            style: const TextStyle(fontSize: 10, color: AppColors.grey), textAlign: TextAlign.center));
                                  })),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: weekCounts.asMap().entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                                    .toList(),
                                isCurved: true,
                                color: AppColors.teal,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.teal.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}