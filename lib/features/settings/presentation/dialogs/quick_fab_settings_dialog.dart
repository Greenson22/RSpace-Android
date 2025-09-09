// lib/features/settings/presentation/dialogs/quick_fab_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/theme_provider.dart';

/// Menampilkan dialog untuk pengaturan Floating Action Button (FAB) cepat.
void showQuickFabSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const QuickFabSettingsDialog(),
  );
}

class QuickFabSettingsDialog extends StatefulWidget {
  const QuickFabSettingsDialog({super.key});

  @override
  State<QuickFabSettingsDialog> createState() => _QuickFabSettingsDialogState();
}

class _QuickFabSettingsDialogState extends State<QuickFabSettingsDialog> {
  late bool _showQuickFab;

  @override
  void initState() {
    super.initState();
    // Ambil state awal dari ThemeProvider
    _showQuickFab = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).showQuickFab;
  }

  void _handleSaveChanges() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    // Panggil metode untuk menyimpan perubahan
    provider.toggleQuickFab(_showQuickFab);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Tombol Cepat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Tampilkan Tombol Cepat'),
            subtitle: const Text(
              'Menampilkan tombol mengambang di semua halaman.',
            ),
            value: _showQuickFab,
            onChanged: (value) {
              setState(() {
                _showQuickFab = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSaveChanges,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
