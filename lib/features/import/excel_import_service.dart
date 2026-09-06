// lib/features/import/excel_import_service.dart

import 'dart:io';

import 'package:excel/excel.dart';

import '../../models/inventory_item.dart';
import '../inventory/inventory_repository.dart';
import 'sap_category_mapper.dart';

class ExcelImportService {
  final InventoryRepository _repository = InventoryRepository();

  Future<int> importSapFile(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();

    final excel = Excel.decodeBytes(bytes);

    int importedCount = 0;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];

      if (sheet == null) continue;

      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];

        try {
          if (row.length < 9) continue;

          final material = row[0]?.value?.toString().trim() ?? '';

          final materialDescription = row[2]?.value?.toString().trim() ?? '';

          final satuan = row[5]?.value?.toString().trim() ?? 'PCS';

          final stokString =
              row[6]?.value?.toString().replaceAll(',', '').trim() ?? '0';

          final nilaiString =
              row[8]?.value?.toString().replaceAll(',', '').trim() ?? '0';

          if (material.isEmpty) continue;

          if (materialDescription.isEmpty) {
            continue;
          }

          final stok = double.tryParse(stokString) ?? 0;

          final nilaiStok = double.tryParse(nilaiString) ?? 0;

          final double hargaSatuan;

          if (stok <= 0) {
            hargaSatuan = 0.0;
          } else {
            hargaSatuan = (nilaiStok / stok).toDouble();
          }

          final kategori = SapCategoryMapper.getCategory(materialDescription);

          final item = InventoryItem(
            kode: material,
            nama: materialDescription,
            kategori: kategori,
            satuan: satuan,
            stok: stok,
            hargaSatuan: hargaSatuan,
            nilaiStok: nilaiStok,
            stokMinimum: 0,
            createdAt: DateTime.now(),
          );

          try {
            await _repository.addItem(item);

            importedCount++;
          } catch (_) {
            // Skip duplicate kode material
          }
        } catch (_) {
          continue;
        }
      }
    }

    return importedCount;
  }
}
