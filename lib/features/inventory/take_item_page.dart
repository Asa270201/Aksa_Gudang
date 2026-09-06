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
  final foremanController = TextEditingController();
  final assistantController = TextEditingController();
  final noteController = TextEditingController();
  final quantityController = TextEditingController(text: '1');

  List<InventoryItem> items = [];
  List<String> divisions = [];
  InventoryItem? selectedItem;
  String? selectedDivision;
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
    if (quantity > item.stok) {
      _showMessage('Jumlah melebihi stok tersedia (${item.stok})');
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
      await _transactionRepository.issueItem(
        item: item,
        quantity: quantity,
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
                DropdownButtonFormField<InventoryItem>(
                  initialValue: selectedItem,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Barang',
                    border: OutlineInputBorder(),
                  ),
                  items: filteredItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.nama} (${item.kode}) - Stok ${item.stok}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (item) => setState(() => selectedItem = item),
                ),
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
