import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import 'add_item_page.dart';
import 'inventory_repository.dart';
import 'take_item_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'take-item',
              tooltip: 'Ambil barang',
              onPressed: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeItemPage()),
                ).then((itemTaken) {
                  if (itemTaken == true && mounted) setState(() {});
                });
              },
              child: const Icon(Icons.output),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'add-item',
              tooltip: 'Tambah barang',
              onPressed: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemPage()),
                ).then((itemAdded) {
                  if (itemAdded == true && mounted) setState(() {});
                });
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const TabBar(
                tabs: [
                  Tab(text: 'APD'),
                  Tab(text: 'Alat Panen'),
                  Tab(text: 'Umum'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari barang...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                children: [
                  _ItemList(category: 'APD', searchQuery: _searchQuery),
                  _ItemList(category: 'Alat Panen', searchQuery: _searchQuery),
                  _ItemList(category: 'Umum', searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final String category;
  final String searchQuery;
  static final InventoryRepository _repository = InventoryRepository();

  const _ItemList({required this.category, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryItem>>(
      future: _repository.getItemsByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat barang: ${snapshot.error}'));
        }

        final items = (snapshot.data ?? []).where((item) {
          final name = item.nama.toLowerCase();
          final code = item.kode.toLowerCase();

          return name.contains(searchQuery) || code.contains(searchQuery);
        }).toList();

        if (items.isEmpty) {
          return const Center(child: Text('Barang tidak ditemukan'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColor().withOpacity(.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_getIcon(), color: _getColor(), size: 28),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          item.kode,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Stok ${item.stok}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Rp ${item.hargaSatuan.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                    onSelected: (value) {},
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIcon() {
    switch (category) {
      case 'APD':
        return Icons.health_and_safety;

      case 'Alat Panen':
        return Icons.agriculture;

      default:
        return Icons.inventory_2;
    }
  }

  Color _getColor() {
    switch (category) {
      case 'APD':
        return Colors.blue;

      case 'Alat Panen':
        return Colors.green;

      default:
        return Colors.orange;
    }
  }
}
