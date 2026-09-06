import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Berita Acara (BA)')),
      body: const Center(
        child: Text('Gunakan filter di History untuk menyiapkan laporan BA.'),
      ),
    );
  }
}
