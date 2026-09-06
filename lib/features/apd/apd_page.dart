import 'package:flutter/material.dart';

class ApdPage extends StatelessWidget {
  const ApdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('APD')),
      body: const Center(child: Text('Data APD')),
    );
  }
}
