// lib/features/progress/presentation/pages/progress_page.dart

import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Progress')),
      body: const Center(
        child: Text(
          'Ini adalah halaman untuk fitur Progress.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
