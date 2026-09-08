import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import 'inventory_repository.dart';

class EditItemPage extends StatefulWidget {
  final InventoryItem item;

  const EditItemPage({super.key, required this.item});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final kodeController = TextEditingController();
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final stokController = TextEditingController();
  final minimumController = TextEditingController();
  final satuanController = TextEditingController();

  final InventoryRepository _repository = InventoryRepository();

  late String kategori;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    kodeController.text = item.kode;
    namaController.text = item.nama;
    kategori = item.kategori;
    satuanController.text = item.satuan;
    hargaController.text = item.hargaSatuan.toString();
    stokController.text = item.stok.toString();
    minimumController.text = item.stokMinimum.toString();
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    hargaController.dispose();
    stokController.dispose();
    minimumController.dispose();
    satuanController.dispose();
    super.dispose();
  }

  Future<void> updateItem() async {
    if (kodeController.text.trim().isEmpty ||
        namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode dan Nama Barang wajib diisi')),
      );
      return;
    }

    final stok = double.tryParse(stokController.text);
    final hargaSatuan = double.tryParse(hargaController.text);
    final stokMinimum = double.tryParse(minimumController.text);

    if (stok == null ||
        hargaSatuan == null ||
        stokMinimum == null ||
        stok < 0 ||
        hargaSatuan < 0 ||
        stokMinimum < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok, harga, dan batas minimum harus valid'),
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final updatedItem = InventoryItem(
        id: widget.item.id,
        kode: kodeController.text.trim(),
        nama: namaController.text.trim(),
        kategori: kategori,
        satuan: satuanController.text.trim(),
        stok: stok,
        hargaSatuan: hargaSatuan,
        nilaiStok: stok * hargaSatuan,
        stokMinimum: stokMinimum,
        sudahPr: widget.item.sudahPr,
        sudahDatang: widget.item.sudahDatang,
        createdAt: widget.item.createdAt,
      );

      final affectedRows = await _repository.updateItem(updatedItem);
      if (affectedRows == 0) {
        throw Exception('Data barang tidak ditemukan');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui barang: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Barang')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTextField(controller: kodeController, label: 'Kode Barang'),
          const SizedBox(height: 16),
          _buildTextField(controller: namaController, label: 'Nama Barang'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: kategori,
            decoration: _inputDecoration('Kategori'),
            items: const [
              DropdownMenuItem(value: 'APD', child: Text('APD')),
              DropdownMenuItem(value: 'Alat Panen', child: Text('Alat Panen')),
              DropdownMenuItem(value: 'Umum', child: Text('Umum')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => kategori = value);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: satuanController, label: 'Satuan'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: hargaController,
            label: 'Harga Satuan',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: stokController,
            label: 'Stok',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: minimumController,
            label: 'Stok Minimum',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : updateItem,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
