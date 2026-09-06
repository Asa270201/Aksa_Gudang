import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final double totalValue;

  const BudgetCard({super.key, required this.totalValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Nilai Inventaris', style: TextStyle(fontSize: 16)),

          const SizedBox(height: 10),

          Text(
            'Rp ${totalValue.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
