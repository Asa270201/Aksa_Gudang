import 'package:aksa_gudang/features/import/import_page.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_page.dart';
import '../history/history_page.dart';
import '../inventory/inventory_page.dart';
import '../reports/reports_page.dart';
import '../stock_kritis/stock_kritis_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int currentIndex = 0;

  final pages = const [
    DashboardPage(),
    InventoryPage(),
    ImportPage(),
    HistoryPage(),
    ReportsPage(),
    StockKritisPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: currentIndex == 0,
                  onTap: () => _selectPage(0),
                ),
                const SizedBox(width: 10),
                _NavItem(
                  icon: Icons.inventory_2,
                  label: 'Inventory',
                  selected: currentIndex == 1,
                  onTap: () => _selectPage(1),
                ),
                const SizedBox(width: 10),
                _NavItem(
                  icon: Icons.upload_file,
                  label: 'Import',
                  selected: currentIndex == 2,
                  onTap: () => _selectPage(2),
                ),
                const SizedBox(width: 10),
                _NavItem(
                  icon: Icons.history,
                  label: 'History',
                  selected: currentIndex == 3,
                  onTap: () => _selectPage(3),
                ),
                const SizedBox(width: 10),
                _NavItem(
                  icon: Icons.description,
                  label: 'BA',
                  selected: currentIndex == 4,
                  onTap: () => _selectPage(4),
                ),
                const SizedBox(width: 10),
                _NavItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Stok Kritis',
                  selected: currentIndex == 5,
                  onTap: () => _selectPage(5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPage(int index) {
    setState(() => currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return SizedBox(
      width: 92,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
