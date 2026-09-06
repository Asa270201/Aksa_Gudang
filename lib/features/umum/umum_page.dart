import 'package:flutter/material.dart';

class UmumPage extends StatelessWidget {
  const UmumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Umum')),
      body: const Center(child: Text('Data Barang Umum')),
    );
  }
}
