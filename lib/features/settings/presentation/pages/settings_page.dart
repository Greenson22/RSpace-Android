// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: const Center(
        child: Text(
          'Halaman Pengaturan\n(Tambahkan opsi pengaturan di sini)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
