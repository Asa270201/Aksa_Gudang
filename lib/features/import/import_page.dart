import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'excel_import_service.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final ExcelImportService _importService = ExcelImportService();

  XFile? selectedFile;

  bool isImporting = false;

  int importedCount = 0;

  String status = 'Belum ada file yang dipilih';

  Future<void> pickExcel() async {
    try {
      const excelType = XTypeGroup(
        label: 'Excel Files',
        extensions: ['xlsx', 'xls'],
      );

      final file = await openFile(acceptedTypeGroups: [excelType]);

      if (file == null) {
        return;
      }

      setState(() {
        selectedFile = file;

        status = 'File dipilih:\n${file.name}';
      });
    } catch (e) {
      setState(() {
        status = 'Gagal memilih file:\n$e';
      });
    }
  }

  Future<void> startImport() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );

      return;
    }

    try {
      setState(() {
        isImporting = true;
        status = 'Sedang membaca file Excel...';
      });

      final totalImported = await _importService.importSapFile(
        selectedFile!.path,
      );

      setState(() {
        importedCount = totalImported;

        status =
            'Import selesai.\n'
            '$totalImported barang berhasil diimpor.';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$totalImported barang berhasil diimport')),
      );
    } catch (e) {
      setState(() {
        status = 'Import gagal:\n$e';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import gagal: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Data SAP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 64),

                    const SizedBox(height: 12),

                    const Text(
                      'Import Inventory SAP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(status, textAlign: TextAlign.center),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickExcel,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Pilih File Excel'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isImporting ? null : startImport,
                        icon: isImporting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          isImporting ? 'Mengimpor...' : 'Mulai Import',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    Text('File: ${selectedFile?.name ?? "-"}'),

                    const SizedBox(height: 8),

                    Text('Total Import: $importedCount'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
