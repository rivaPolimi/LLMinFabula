import 'package:flutter/material.dart';

class RoleTutorialsScreen extends StatelessWidget {
  const RoleTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9B486),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003943),
        title: const Text('Role tutorials'),
      ),
      body: const Center(
        child: Text(
          'lista con spiegazione dei ruoli',
          style: TextStyle(color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
