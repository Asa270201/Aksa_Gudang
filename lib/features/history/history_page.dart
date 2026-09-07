import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'transaction_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TransactionRepository _repository = TransactionRepository();
  late Future<List<TransactionHistory>> _historyFuture;
  bool isExporting = false;
  DateTime? startDate;
  DateTime? endDate;
  String selectedDivision = 'Semua Divisi';
  String selectedItem = 'Semua Barang';

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.getHistory();
    startDate = null;
    endDate = null;
    selectedDivision = 'Semua Divisi';
    selectedItem = 'Semua Barang';
  }

  void _reload() {
    setState(() => _historyFuture = _repository.getHistory());
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: start
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  List<TransactionHistory> _filterHistory(List<TransactionHistory> history) {
    return history.where((item) {
      final date = item.date.toLocal();
      final dateOnly = DateTime(date.year, date.month, date.day);
      final matchesStart = startDate == null || !dateOnly.isBefore(startDate!);
      final matchesEnd = endDate == null || !dateOnly.isAfter(endDate!);
      final matchesDivision =
          selectedDivision == 'Semua Divisi' ||
          item.division == selectedDivision;
      final matchesItem =
          selectedItem == 'Semua Barang' || item.itemName == selectedItem;
      return matchesStart && matchesEnd && matchesDivision && matchesItem;
    }).toList();
  }

  Future<void> _exportHistory(List<TransactionHistory> history) async {
    if (isExporting) return;
    if (history.isEmpty) {
      _showMessage('Tidak ada data sesuai filter untuk diekspor');
      return;
    }

    setState(() => isExporting = true);
    try {
      final rows = <List<String>>[
        [
          'Tanggal',
          'Barang',
          'Kode',
          'Kategori',
          'Jumlah',
          'Satuan',
          'Divisi',
          'Penerima',
          'Mandor',
          'Asisten Divisi',
          'Keterangan',
          'Foto Dokumentasi',
          'Nilai',
        ],
        ...history.map(
          (item) => [
            item.date.toLocal().toIso8601String(),
            item.itemName,
            item.itemCode,
            item.category,
            item.quantity.toString(),
            item.unit,
            item.division,
            item.recipient,
            item.foreman,
            item.assistant,
            item.note,
            item.documentationPhotoPath ?? '',
            item.subtotal.toStringAsFixed(0),
          ],
        ),
      ];
      final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      final exportFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(csv)),
        name: 'laporan_pengambilan.csv',
        mimeType: 'text/csv',
      );

      final isMobile =
          Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS;
      if (Theme.of(context).platform == TargetPlatform.android) {
        await const MethodChannel(
          'aksa_gudang/export',
        ).invokeMethod<String>('saveToDownloads', <String, Object>{
          'fileName': 'laporan_pengambilan.csv',
          'bytes': Uint8List.fromList(utf8.encode(csv)),
        });
        if (mounted) {
          _showMessage('Laporan tersimpan di folder Download');
        }
      } else if (isMobile) {
        final directory = await getApplicationDocumentsDirectory();
        await exportFile.saveTo('${directory.path}/laporan_pengambilan.csv');
        if (mounted) _showMessage('Laporan berhasil diekspor');
      } else {
        const csvType = XTypeGroup(label: 'CSV', extensions: ['csv']);
        final location = await getSaveLocation(
          acceptedTypeGroups: [csvType],
          suggestedName: 'laporan_pengambilan.csv',
        );
        if (location == null) {
          if (mounted) _showMessage('Export dibatalkan');
          return;
        }
        await exportFile.saveTo(location.path);
        if (mounted) _showMessage('Laporan berhasil diekspor');
      }
    } catch (error) {
      if (mounted) _showMessage('Export gagal: $error');
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
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
        title: const Text('History Pengambilan'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<TransactionHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat history: ${snapshot.error}'),
            );
          }

          final history = snapshot.data ?? [];
          final divisions = <String>{
            'Semua Divisi',
            ...history.map((item) => item.division),
          }.toList();
          final items = <String>{
            'Semua Barang',
            ...history.map((item) => item.itemName),
          }.toList();
          final filteredHistory = _filterHistory(history);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FilterPanel(
                  startDate: startDate,
                  endDate: endDate,
                  divisions: divisions,
                  items: items,
                  selectedDivision: selectedDivision,
                  selectedItem: selectedItem,
                  onStartDate: () => _pickDate(start: true),
                  onEndDate: () => _pickDate(start: false),
                  onDivisionChanged: (value) =>
                      setState(() => selectedDivision = value),
                  onItemChanged: (value) =>
                      setState(() => selectedItem = value),
                  onClear: () => setState(() {
                    startDate = null;
                    endDate = null;
                    selectedDivision = 'Semua Divisi';
                    selectedItem = 'Semua Barang';
                  }),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isExporting
                      ? null
                      : () => _exportHistory(filteredHistory),
                  icon: isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download),
                  label: Text(
                    isExporting
                        ? 'Mengekspor...'
                        : 'Export ${filteredHistory.length} transaksi',
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredHistory.isEmpty)
                  const Center(child: Text('Belum ada transaksi sesuai filter'))
                else
                  ...filteredHistory.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryCard(
                        item: item,
                        onCancel: () => _cancelTransaction(item),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancelTransaction(TransactionHistory item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan transaksi?'),
        content: Text(
          'Stok dari transaksi ${item.bonNumber == null ? '' : 'bon ${item.bonNumber} '}akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.cancelTransaction(item.id);
      if (mounted) {
        _showMessage('Transaksi berhasil dibatalkan dan stok dikembalikan');
        _reload();
      }
    } catch (error) {
      if (mounted) _showMessage('Gagal membatalkan transaksi: $error');
    }
  }
}

class _FilterPanel extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> divisions;
  final List<String> items;
  final String selectedDivision;
  final String selectedItem;
  final VoidCallback onStartDate;
  final VoidCallback onEndDate;
  final ValueChanged<String> onDivisionChanged;
  final ValueChanged<String> onItemChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.startDate,
    required this.endDate,
    required this.divisions,
    required this.items,
    required this.selectedDivision,
    required this.selectedItem,
    required this.onStartDate,
    required this.onEndDate,
    required this.onDivisionChanged,
    required this.onItemChanged,
    required this.onClear,
  });

  String _dateText(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Dari: ${_dateText(startDate)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEndDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Sampai: ${_dateText(endDate)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedDivision,
          decoration: const InputDecoration(
            labelText: 'Divisi',
            border: OutlineInputBorder(),
          ),
          items: divisions
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onDivisionChanged(value);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedItem,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Barang',
            border: OutlineInputBorder(),
          ),
          items: items
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onItemChanged(value);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Bersihkan filter'),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TransactionHistory item;
  final VoidCallback onCancel;

  const _HistoryCard({required this.item, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final date = item.date.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          Icons.output,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        title: Text(
          item.itemName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item.bonNumber == null ? 'Tanpa nomor bon' : 'Bon ${item.bonNumber}'}\n'
          '${item.quantity} ${item.unit} - ${item.division}\n$dateText',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.itemCode} - ${item.category}'),
                const SizedBox(height: 6),
                Text('Penerima: ${item.recipient}'),
                Text('Mandor: ${item.foreman}'),
                Text('Asisten Divisi: ${item.assistant}'),
                Text('Keterangan: ${item.note}'),
                if (item.documentationPhotoPath != null)
                  Text('Foto Dokumentasi: ${item.documentationPhotoPath}'),
                Text('Nilai: Rp ${item.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.undo),
                    label: const Text('Batalkan transaksi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
