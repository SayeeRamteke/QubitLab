import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showResultsSheet(BuildContext context, Map<String, double> results) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ResultsSheet(results: results),
  );
}

class _ResultsSheet extends StatelessWidget {
  final Map<String, double> results;
  const _ResultsSheet({required this.results});

  @override
  Widget build(BuildContext context) {
    final keys = results.keys.toList()..sort();
    final barWidth = keys.length <= 4 ? 28.0 : (keys.length <= 8 ? 18.0 : 8.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Text('1024 shots on the Aer simulator',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 1,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.25,
                      getTitlesWidget: (v, meta) => Text('${(v * 100).round()}%',
                          style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= keys.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('|${keys[i]}>',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < keys.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: results[keys[i]]!,
                        width: barWidth,
                        color: AppColors.indigo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in keys)
                Chip(
                  label: Text('|$k>  ${(results[k]! * 100).toStringAsFixed(1)}%'),
                  backgroundColor: const Color(0xFFEDEDFD),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Bit order: the rightmost bit is q0.',
              style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}
