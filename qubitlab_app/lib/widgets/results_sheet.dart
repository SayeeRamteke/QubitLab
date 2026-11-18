import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bloch_sheet.dart';

void showResultsSheet(
  BuildContext context,
  Map<String, double> results, [
  List<Map<String, dynamic>> blochVectors = const [],
]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ResultsSheet(results: results, blochVectors: blochVectors),
  );
}

class _ResultsSheet extends StatefulWidget {
  final Map<String, double> results;
  final List<Map<String, dynamic>> blochVectors;

  const _ResultsSheet({
    required this.results,
    required this.blochVectors,
  });

  @override
  State<_ResultsSheet> createState() => _ResultsSheetState();
}

class _ResultsSheetState extends State<_ResultsSheet> {
  int _selectedQubit = 0;

  @override
  Widget build(BuildContext context) {
    final keys = widget.results.keys.toList()..sort();
    final barWidth = keys.length <= 4 ? 28.0 : (keys.length <= 8 ? 18.0 : 8.0);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulation Output',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('Aer simulator shots & Bloch sphere state',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ----- SECTION 1: PROBABILITIES -----
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.indigo),
                SizedBox(width: 8),
                Text('Measurement Probabilities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
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
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < keys.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: widget.results[keys[i]] ?? 0,
                          width: barWidth,
                          color: AppColors.indigo,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in keys)
                  Chip(
                    label: Text('|$k>  ${((widget.results[k] ?? 0) * 100).toStringAsFixed(1)}%'),
                    backgroundColor: const Color(0xFFEDEDFD),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Bit order: the rightmost bit is q0.',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),

            // ----- SECTION 2: BLOCH SPHERE -----
            const Row(
              children: [
                Icon(Icons.public_rounded, size: 20, color: AppColors.indigo),
                SizedBox(width: 8),
                Text('Bloch Sphere State',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Visual representation of quantum state vector on the unit sphere',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 14),

            if (widget.blochVectors.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('Bloch vectors not available for this run.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              )
            else ...[
              if (widget.blochVectors.length > 1) ...[
                Row(
                  children: [
                    const Text('Select Qubit:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var idx = 0; idx < widget.blochVectors.length; idx++) ...[
                              ChoiceChip(
                                label: Text('q${widget.blochVectors[idx]['qubit']}'),
                                selected: _selectedQubit == idx,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedQubit = idx);
                                },
                                selectedColor: AppColors.indigo.withAlpha(40),
                                side: BorderSide(
                                  color: _selectedQubit == idx
                                      ? AppColors.indigo
                                      : Colors.black12,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _buildSelectedBlochView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBlochView() {
    final idx = _selectedQubit.clamp(0, widget.blochVectors.length - 1);
    final data = widget.blochVectors[idx];
    final q = data['qubit'] as int;
    final x = (data['x'] as num).toDouble();
    final y = (data['y'] as num).toDouble();
    final z = (data['z'] as num).toDouble();

    return Center(
      child: BlochView(
        qubit: q,
        x: x,
        y: y,
        z: z,
        size: 190,
        showHeader: true,
      ),
    );
  }
}
