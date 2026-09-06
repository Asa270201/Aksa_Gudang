// lib/features/dashboard/widgets/expense_pie_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, int> divisionPickupCounts;

  const ExpensePieChart({super.key, required this.divisionPickupCounts});

  static const divisions = [
    'Divisi 1',
    'Divisi 2',
    'Divisi 3',
    'Divisi 4',
    'Kantor Umum',
  ];

  static const colors = [
    Color(0xFF63B3ED),
    Color(0xFF50C878),
    Color(0xFFE8B44F),
    Color(0xFFE87968),
    Color(0xFF9AD64D),
  ];

  @override
  Widget build(BuildContext context) {
    final totalPickups = divisions.fold<int>(
      0,
      (total, division) => total + (divisionPickupCounts[division] ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(
            'Pengambilan Barang per Divisi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 24),

          if (totalPickups == 0)
            const SizedBox(
              height: 220,
              child: Center(child: Text('Belum ada data pengambilan')),
            )
          else
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 45,
                  startDegreeOffset: -90,
                  sections: [
                    for (var index = 0; index < divisions.length; index++)
                      PieChartSectionData(
                        value: (divisionPickupCounts[divisions[index]] ?? 0)
                            .toDouble(),
                        color: colors[index],
                        title: _percentage(
                          divisionPickupCounts[divisions[index]] ?? 0,
                          totalPickups,
                        ),
                        radius: 75,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 28),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var index = 0; index < divisions.length; index++)
                _Legend(color: colors[index], title: divisions[index]),
            ],
          ),
        ],
      ),
    );
  }

  String _percentage(int value, int total) {
    return '${(value / total * 100).round()}%';
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String title;

  const _Legend({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
