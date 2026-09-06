import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import 'inventory_repository.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final kodeController = TextEditingController();
  final namaController = TextEditingController();
  final hargaController = TextEditingController();
  final stokController = TextEditingController();
  final minimumController = TextEditingController();
  final satuanController = TextEditingController();

  final InventoryRepository _repository = InventoryRepository();

  String kategori = 'APD';

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    satuanController.text = 'PCS';
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

  Future<void> saveItem() async {
    if (kodeController.text.trim().isEmpty ||
        namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode dan Nama Barang wajib diisi')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final stok = double.tryParse(stokController.text) ?? 0;

      final hargaSatuan = double.tryParse(hargaController.text) ?? 0;

      final item = InventoryItem(
        kode: kodeController.text.trim(),
        nama: namaController.text.trim(),
        kategori: kategori,
        satuan: satuanController.text.trim(),
        stok: stok,
        hargaSatuan: hargaSatuan,
        nilaiStok: stok * hargaSatuan,
        stokMinimum: double.tryParse(minimumController.text) ?? 0,
        createdAt: DateTime.now(),
      );

      await _repository.addItem(item);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barang berhasil disimpan')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan barang: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Barang')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTextField(controller: kodeController, label: 'Kode Barang'),

          const SizedBox(height: 16),

          _buildTextField(controller: namaController, label: 'Nama Barang'),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: kategori,
            decoration: _inputDecoration('Kategori'),
            items: const [
              DropdownMenuItem(value: 'APD', child: Text('APD')),
              DropdownMenuItem(value: 'Alat Panen', child: Text('Alat Panen')),
              DropdownMenuItem(value: 'Umum', child: Text('Umum')),
            ],
            onChanged: (value) {
              setState(() {
                kategori = value!;
              });
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
            label: 'Stok Awal',
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
              onPressed: isLoading ? null : saveItem,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Barang'),
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
