import 'package:flutter/material.dart';

class AlatPanenPage extends StatelessWidget {
  const AlatPanenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alat Panen')),
      body: const Center(child: Text('Data Alat Panen')),
    );
  }
}
