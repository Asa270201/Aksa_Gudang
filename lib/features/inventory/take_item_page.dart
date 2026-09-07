import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../history/transaction_repository.dart';
import 'inventory_repository.dart';

class TakeItemPage extends StatefulWidget {
  const TakeItemPage({super.key});

  @override
  State<TakeItemPage> createState() => _TakeItemPageState();
}

class _TakeItemPageState extends State<TakeItemPage> {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final recipientController = TextEditingController();
  final bonNumberController = TextEditingController();
  final foremanController = TextEditingController();
  final assistantController = TextEditingController();
  final noteController = TextEditingController();
  final quantityController = TextEditingController(text: '1');

  List<InventoryItem> items = [];
  List<String> divisions = [];
  InventoryItem? selectedItem;
  final List<TransactionLine> transactionLines = [];
  String? selectedDivision;
  DateTime selectedDate = DateTime.now();
  String selectedCategory = 'Semua Kategori';
  bool isLoading = true;
  bool isSaving = false;
  XFile? documentationPhoto;

  List<InventoryItem> get filteredItems {
    if (selectedCategory == 'Semua Kategori') {
      return items;
    }

    return items.where((item) => item.kategori == selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    recipientController.dispose();
    bonNumberController.dispose();
    foremanController.dispose();
    assistantController.dispose();
    noteController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final loadedItems = await _inventoryRepository.getAllItems();
      final loadedDivisions = await _transactionRepository.getDivisions();
      if (!mounted) return;
      setState(() {
        items = loadedItems.where((item) => item.stok > 0).toList();
        selectedItem = items.isEmpty ? null : items.first;
        divisions = loadedDivisions;
        selectedDivision = divisions.isEmpty ? null : divisions.first;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showMessage('Gagal memuat barang: $error');
    }
  }

  Future<void> _saveTransaction() async {
    if (transactionLines.isEmpty) {
      _showMessage('Tambahkan minimal satu barang ke bon');
      return;
    }
    if (noteController.text.trim().isEmpty) {
      _showMessage('Keterangan wajib diisi');
      return;
    }
    if (recipientController.text.trim().isEmpty) {
      _showMessage('Nama penerima wajib diisi');
      return;
    }
    if (foremanController.text.trim().isEmpty) {
      _showMessage('Nama mandor wajib diisi');
      return;
    }
    if (assistantController.text.trim().isEmpty) {
      _showMessage('Nama asisten divisi wajib diisi');
      return;
    }
    if (selectedDivision == null) {
      _showMessage('Pilih divisi terlebih dahulu');
      return;
    }

    final divisionId = await _transactionRepository.getDivisionId(
      selectedDivision!,
    );
    if (divisionId == null) {
      _showMessage('Divisi tidak ditemukan');
      return;
    }

    setState(() => isSaving = true);
    try {
      await _transactionRepository.issueBon(
        bonNumber: bonNumberController.text,
        date: selectedDate,
        items: transactionLines,
        recipient: recipientController.text,
        foreman: foremanController.text,
        assistant: assistantController.text,
        note: noteController.text,
        divisionId: divisionId,
        documentationPhotoPath: documentationPhoto?.path,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _addLine() {
    final item = selectedItem;
    final quantity = int.tryParse(quantityController.text.trim());
    if (item == null) {
      _showMessage('Pilih barang terlebih dahulu');
      return;
    }
    if (quantity == null || quantity <= 0) {
      _showMessage('Jumlah harus berupa angka lebih dari 0');
      return;
    }
    final existing = transactionLines.indexWhere(
      (line) => line.item.id == item.id,
    );
    final currentQuantity = existing == -1
        ? 0
        : transactionLines[existing].quantity;
    if (currentQuantity + quantity > item.stok) {
      _showMessage('Jumlah melebihi stok tersedia (${item.stok})');
      return;
    }
    setState(() {
      if (existing == -1) {
        transactionLines.add(TransactionLine(item: item, quantity: quantity));
      } else {
        transactionLines[existing] = TransactionLine(
          item: item,
          quantity: currentQuantity + quantity,
        );
      }
      quantityController.text = '1';
    });
  }

  Future<void> _pickTransactionDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: selectedDate,
    );
    if (date != null && mounted) setState(() => selectedDate = date);
  }

  Future<void> _pickDocumentationPhoto() async {
    const imageType = XTypeGroup(
      label: 'Foto Dokumentasi',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageType]);
    if (file == null || !mounted) return;
    setState(() => documentationPhoto = file);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Barang')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('Tidak ada barang dengan stok tersedia'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: bonNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Bon (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickTransactionDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Tanggal Pengambilan: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Barang',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Semua Kategori',
                      child: Text('Semua Kategori'),
                    ),
                    DropdownMenuItem(value: 'APD', child: Text('APD')),
                    DropdownMenuItem(
                      value: 'Alat Panen',
                      child: Text('Alat Panen'),
                    ),
                    DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                  ],
                  onChanged: (category) {
                    if (category == null) return;
                    setState(() {
                      selectedCategory = category;
                      selectedItem = filteredItems.isEmpty
                          ? null
                          : filteredItems.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<InventoryItem>(
                  displayStringForOption: (item) =>
                      '${item.nama} (${item.kode})',

                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return filteredItems;
                    }

                    return filteredItems.where((item) {
                      final query = textEditingValue.text.toLowerCase();

                      return item.nama.toLowerCase().contains(query) ||
                          item.kode.toLowerCase().contains(query);
                    });
                  },

                  onSelected: (item) {
                    setState(() {
                      selectedItem = item;
                    });
                  },

                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Cari Barang',
                            hintText: 'Ketik nama atau kode barang',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },

                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: 500,
                          height: 250,
                          child: ListView.builder(
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final item = options.elementAt(index);

                              return ListTile(
                                title: Text(item.nama),
                                subtitle: Text(
                                  '${item.kode} • Stok ${item.stok}',
                                ),
                                onTap: () {
                                  onSelected(item);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedItem != null) ...[
                  const SizedBox(height: 12),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(selectedItem!.nama),
                      subtitle: Text(
                        'Kode: ${selectedItem!.kode}\n'
                        'Stok: ${selectedItem!.stok} ${selectedItem!.satuan}',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedDivision,
                  decoration: const InputDecoration(
                    labelText: 'Divisi Pengambil',
                    border: OutlineInputBorder(),
                  ),
                  items: divisions
                      .map(
                        (division) => DropdownMenuItem(
                          value: division,
                          child: Text(division),
                        ),
                      )
                      .toList(),
                  onChanged: (division) {
                    setState(() => selectedDivision = division);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Diambil',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _addLine,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Tambah ke Bon'),
                ),
                if (transactionLines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Isi Bon',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...transactionLines.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.item.nama),
                      subtitle: Text(
                        '${entry.value.item.kode} - ${entry.value.quantity} ${entry.value.item.satuan}',
                      ),
                      trailing: IconButton(
                        onPressed: isSaving
                            ? null
                            : () => setState(
                                () => transactionLines.removeAt(entry.key),
                              ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima',
                    hintText: 'Contoh: Budi Santoso',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: foremanController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Mandor',
                    hintText: 'Contoh: Pak Joko',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: assistantController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Asisten Divisi',
                    hintText: 'Contoh: Siti Aminah',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
                    hintText: 'Contoh: APD untuk Divisi Panen A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickDocumentationPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    documentationPhoto == null
                        ? 'Upload Foto Dokumentasi (Opsional)'
                        : 'Ganti Foto Dokumentasi',
                  ),
                ),
                if (documentationPhoto != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    documentationPhoto!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isSaving ? null : _saveTransaction,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.output),
                  label: const Text('Simpan Pengambilan'),
                ),
              ],
            ),
    );
  }
}
