import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../transactions/data/transaction_provider.dart';
import '../../transactions/models/transaction.dart';
import 'dashboard_screen.dart'; // For CurrencyFormatter

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Insights"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: txState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading insights: $err")),
        data: (transactions) {
          // 1. Filter for expenses (Case-Insensitive)
          final expenses = transactions.where((t) => t.type.toLowerCase() == 'expense').toList();

          if (expenses.isEmpty) {
            return const Center(child: Text("No expense data found for analysis."));
          }

          // 2. Data Processing
          final categoryMap = _getCategoryData(expenses);
          final highestCategory = _getHighestCategory(categoryMap);
          final weeklyComparison = _getWeeklyComparison(expenses);

          return RefreshIndicator(
            onRefresh: () async {
              // Correct way to refresh StateNotifierProvider
              ref.invalidate(transactionProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightHeader("Quick Summary"),
                  _buildTopCategoryCard(highestCategory),
                  const SizedBox(height: 20),
                  
                  _buildInsightHeader("Weekly Comparison"),
                  _buildComparisonCard(weeklyComparison),
                  const SizedBox(height: 20),
            
                  _buildInsightHeader("Spending by Category"),
                  const Text("Slide horizontally to see all categories", 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  // Horizontal scroll for the bar chart
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (categoryMap.length * 75.0).clamp(MediaQuery.of(context).size.width - 32, 1200.0),
                      height: 350,
                      child: _buildCategoryBarChart(categoryMap),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper Logic ---

  Map<String, double> _getCategoryData(List<Transaction> expenses) {
    Map<String, double> data = {};
    for (var tx in expenses) {
      final cat = tx.category.trim().isEmpty ? "General" : tx.category;
      data[cat] = (data[cat] ?? 0) + tx.amount;
    }
    return data;
  }

  MapEntry<String, double> _getHighestCategory(Map<String, double> map) {
    if (map.isEmpty) return const MapEntry("None", 0.0);
    return map.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  // --- REFINED WEEKLY LOGIC (LOCAL TIME & MIDNIGHT NORMALIZATION) ---
  Map<String, double> _getWeeklyComparison(List<Transaction> expenses) {
    final now = DateTime.now();
    // Midnight Today (Local Time: April 6, 2026)
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Start of This Week (Monday April 6)
    final thisWeekMonday = todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));
    
    // Start of Last Week (Monday March 30)
    final lastWeekMonday = thisWeekMonday.subtract(const Duration(days: 7));

    double thisWeekTotal = 0;
    double lastWeekTotal = 0;

    for (var t in expenses) {
      // 1. Convert DB date to Local Phone Time
      final localDate = t.date.toLocal();
      // 2. Strip Time to compare by Calendar Day
      final txDate = DateTime(localDate.year, localDate.month, localDate.day);

      // logic: If txDate is Today (Monday) -> This Week
      if (txDate.isAtSameMomentAs(thisWeekMonday) || txDate.isAfter(thisWeekMonday)) {
        thisWeekTotal += t.amount;
      } 
      // logic: If txDate is between Last Monday and Yesterday (Sunday) -> Last Week
      else if (txDate.isAtSameMomentAs(lastWeekMonday) || txDate.isAfter(lastWeekMonday)) {
        lastWeekTotal += t.amount;
      }
    }

    return {"thisWeek": thisWeekTotal, "lastWeek": lastWeekTotal};
  }

  // --- UI Components ---

  Widget _buildInsightHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
    );
  }

  Widget _buildTopCategoryCard(MapEntry<String, double> top) {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.trending_up, color: Colors.white)),
        title: const Text("Top Expense Source"),
        subtitle: Text(top.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Text(CurrencyFormatter.format(top.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildComparisonCard(Map<String, double> comparison) {
    final thisWeek = comparison['thisWeek'] ?? 0.0;
    final lastWeek = comparison['lastWeek'] ?? 0.0;
    final diff = thisWeek - lastWeek;
    final isHigher = diff > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _comparisonStat("Last Week", lastWeek, Colors.grey),
            Icon(
              thisWeek == lastWeek ? Icons.remove : (isHigher ? Icons.arrow_upward : Icons.arrow_downward), 
              color: thisWeek == lastWeek ? Colors.grey : (isHigher ? Colors.red : Colors.green)
            ),
            _comparisonStat("This Week", thisWeek, isHigher ? Colors.red : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _comparisonStat(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(CurrencyFormatter.format(val), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildCategoryBarChart(Map<String, double> data) {
    final List<BarChartGroupData> groups = [];
    final keys = data.keys.toList();
    final maxVal = data.isEmpty ? 100.0 : data.values.reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < keys.length; i++) {
      final val = data[keys[i]]!;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val, 
              color: Colors.indigo, 
              width: 22, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, 
                toY: maxVal, 
                color: Colors.indigo.withOpacity(0.05)
              ),
            )
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.3, 
        barGroups: groups,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                CurrencyFormatter.format(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              );
            }
          )
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= keys.length) return const SizedBox.shrink();
                
                String label = keys[index];
                if (label.length > 8) label = "${label.substring(0, 6)}..";

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 10,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}