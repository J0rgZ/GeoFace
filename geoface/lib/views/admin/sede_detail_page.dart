import 'package:flutter/material.dart';

class SedeDetailPage extends StatelessWidget {
  final String sedeId;

  const SedeDetailPage({super.key, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Sede')),
      body: Center(child: Text('ID de la Sede: $sedeId')),
    );
  }
}
