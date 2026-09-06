import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../history/transaction_repository.dart';
import '../inventory/inventory_repository.dart';
import 'widgets/budget_card.dart';
import 'widgets/category_card.dart';
import 'widgets/expense_pie_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static final InventoryRepository _repository = InventoryRepository();
  static final TransactionRepository _transactionRepository =
      TransactionRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AKSA GUDANG'), centerTitle: true),
      body: FutureBuilder<List<Object>>(
        future: Future.wait<Object>([
          _repository.getAllItems(),
          _transactionRepository.getDivisionPickupCounts(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat dashboard: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          return _buildDashboard(
            context,
            data[0] as List<InventoryItem>,
            data[1] as Map<String, int>,
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<InventoryItem> items,
    Map<String, int> divisionPickupCounts,
  ) {
    final criticalItems =
        items.where((item) => item.stok <= item.stokMinimum).toList()
          ..sort((a, b) => a.stok.compareTo(b.stok));
    final totalValue = items.fold<double>(
      0,
      (total, item) => total + item.nilaiStok,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BudgetCard(totalValue: totalValue),

        const SizedBox(height: 28),

        const Text(
          'Ringkasan Inventaris',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            CategoryCard(
              title: 'APD',
              total: '${_countCategory(items, 'APD')}',
              icon: Icons.health_and_safety,
              color: const Color(0xFF63B3ED),
            ),
            CategoryCard(
              title: 'Alat Panen',
              total: '${_countCategory(items, 'Alat Panen')}',
              icon: Icons.agriculture,
              color: const Color(0xFF50C878),
            ),
            CategoryCard(
              title: 'Barang Umum',
              total: '${_countCategory(items, 'Umum')}',
              icon: Icons.inventory_2,
              color: const Color(0xFFE8B44F),
            ),
            CategoryCard(
              title: 'Stok Kritis',
              total: '${criticalItems.length}',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFE87968),
            ),
          ],
        ),

        const SizedBox(height: 28),

        ExpensePieChart(divisionPickupCounts: divisionPickupCounts),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stok Kritis',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 16),

              if (criticalItems.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Tidak ada stok kritis'),
                )
              else
                ...criticalItems
                    .take(5)
                    .expand(
                      (item) => [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: item.stok == 0
                                ? const Color(0xFFE87968)
                                : const Color(0xFFE8B44F),
                          ),
                          title: Text(item.nama),
                          subtitle: Text('Sisa ${item.stok} ${item.satuan}'),
                          trailing: Text(item.kategori),
                        ),
                        const Divider(),
                      ],
                    ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi Terakhir',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 16),

              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Belum ada data transaksi'),
                subtitle: Text(
                  'Transaksi akan tampil setelah fitur transaksi digunakan.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  int _countCategory(List<InventoryItem> items, String category) {
    return items.where((item) => item.kategori == category).length;
  }
}
