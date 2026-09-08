import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/inventory_item.dart';
import '../inventory/inventory_repository.dart';

class StockKritisPage extends StatefulWidget {
  const StockKritisPage({super.key});

  @override
  State<StockKritisPage> createState() => _StockKritisPageState();
}

class _StockKritisPageState extends State<StockKritisPage> {
  final InventoryRepository _repository = InventoryRepository();
  late Future<List<InventoryItem>> _criticalItemsFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _criticalItemsFuture = _repository.getCriticalStockItems();
  }

  Future<void> _changePrStatus(InventoryItem item) async {
    final newStatus = !item.sudahPr;
    try {
      await _repository.updatePrStatus(itemId: item.id!, sudahPr: newStatus);
      if (!mounted) return;
      setState(_reload);
      _showMessage(
        newStatus
            ? 'Status barang diubah menjadi Sudah PR'
            : 'Status PR dibatalkan',
      );
    } catch (error) {
      if (mounted) _showMessage('Gagal mengubah status PR: $error');
    }
  }

  Future<void> _markItemAsArrived(InventoryItem item) async {
    try {
      await _repository.updateArrivalStatus(
        itemId: item.id!,
        sudahDatang: true,
      );
      if (!mounted) return;
      setState(_reload);
      _showMessage('${item.nama} ditandai sudah datang');
    } catch (error) {
      if (mounted) _showMessage('Gagal memperbarui kedatangan barang: $error');
    }
  }

  Future<void> _exportCriticalStock(List<InventoryItem> items) async {
    if (_isExporting) return;
    if (items.isEmpty) {
      _showMessage('Tidak ada stok krisis untuk diekspor');
      return;
    }

    setState(() => _isExporting = true);
    try {
      final workbook = Excel.createExcel();
      final sheet = workbook['Stok Krisis'];
      final headers = [
        'Kode',
        'Nama Barang',
        'Kategori',
        'Stok',
        'Stok Minimum',
        'Satuan',
        'Harga Satuan',
        'Nilai Stok',
        'Status PR',
      ];
      sheet.appendRow(headers.map(TextCellValue.new).toList());
      for (final item in items) {
        sheet.appendRow([
          TextCellValue(item.kode),
          TextCellValue(item.nama),
          TextCellValue(item.kategori),
          TextCellValue(item.stok.toString()),
          TextCellValue(item.stokMinimum.toString()),
          TextCellValue(item.satuan),
          TextCellValue(item.hargaSatuan.toStringAsFixed(0)),
          TextCellValue(item.nilaiStok.toStringAsFixed(0)),
          TextCellValue(item.sudahPr ? 'Sudah PR' : 'Belum PR'),
        ]);
      }

      final bytes = workbook.save();
      if (bytes == null) throw Exception('Workbook kosong');
      final fileBytes = Uint8List.fromList(bytes);
      const fileName = 'stok_krisis.xlsx';
      const mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final exportFile = XFile.fromData(
        fileBytes,
        name: fileName,
        mimeType: mimeType,
      );

      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.android) {
        await const MethodChannel('aksa_gudang/export').invokeMethod<String>(
          'saveToDownloads',
          <String, Object>{
            'fileName': fileName,
            'bytes': fileBytes,
            'mimeType': mimeType,
          },
        );
        if (mounted) _showMessage('Stok krisis tersimpan di folder Download');
      } else if (platform == TargetPlatform.iOS) {
        final directory = await getApplicationDocumentsDirectory();
        await exportFile.saveTo('${directory.path}/$fileName');
        if (mounted) _showMessage('Stok krisis berhasil diekspor');
      } else {
        const xlsxType = XTypeGroup(label: 'Excel', extensions: ['xlsx']);
        final location = await getSaveLocation(
          acceptedTypeGroups: [xlsxType],
          suggestedName: fileName,
        );
        if (location == null) {
          if (mounted) _showMessage('Export dibatalkan');
          return;
        }
        await exportFile.saveTo(location.path);
        if (mounted) _showMessage('Stok krisis berhasil diekspor');
      }
    } catch (error) {
      if (mounted) _showMessage('Export gagal: $error');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Krisis'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<InventoryItem>>(
        future: _criticalItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat stok krisis: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(items: items),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isExporting
                        ? null
                        : () => _exportCriticalStock(items),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_view),
                    label: Text(
                      _isExporting ? 'Menyiapkan Excel...' : 'Export Excel',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text('Tidak ada stok kritis saat ini'),
                    ),
                  )
                else
                  ...items.map(
                    (item) => _CriticalStockCard(
                      item: item,
                      onStatusChanged: () => _changePrStatus(item),
                      onItemArrived: () => _markItemAsArrived(item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<InventoryItem> items;

  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final sudahPr = items.where((item) => item.sudahPr).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} barang perlu perhatian',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$sudahPr sudah PR, ${items.length - sudahPr} belum PR'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriticalStockCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onStatusChanged;
  final VoidCallback onItemArrived;

  const _CriticalStockCard({
    required this.item,
    required this.onStatusChanged,
    required this.onItemArrived,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.sudahPr
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Text('${item.kode} • ${item.kategori}'),
                    ],
                  ),
                ),
                Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  item.sudahPr ? 'Sudah PR' : 'Belum PR',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('Stok\n${item.stok} ${item.satuan}')),
                Expanded(
                  child: Text('Minimum\n${item.stokMinimum} ${item.satuan}'),
                ),
                Expanded(
                  child: Text('Nilai\nRp ${item.nilaiStok.toStringAsFixed(0)}'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: item.sudahPr
                  ? OutlinedButton.icon(
                      onPressed: onStatusChanged,
                      icon: const Icon(Icons.undo),
                      label: const Text('Batalkan Status PR'),
                    )
                  : FilledButton.icon(
                      onPressed: onStatusChanged,
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Sudah PR'),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onItemArrived,
                icon: const Icon(Icons.inventory_rounded),
                label: const Text('Barang Sudah Datang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
