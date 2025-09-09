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
  // ==> 1. TAMBAHKAN STATE & CONTROLLER UNTUK IKON
  late String _quickFabIcon;
  late TextEditingController _iconController;

  final List<String> _iconSuggestions = ['➕', '📝', '⚡', '💡', '💬', '⭐'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _showQuickFab = provider.showQuickFab;
    // ==> 2. INISIALISASI STATE & CONTROLLER
    _quickFabIcon = provider.quickFabIcon;
    _iconController = TextEditingController(text: _quickFabIcon);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _handleSaveChanges() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    // ==> 3. PANGGIL METODE BARU UNTUK MENYIMPAN SEMUA PENGATURAN
    provider.updateQuickFabSettings(
      show: _showQuickFab,
      icon: _iconController.text.trim().isNotEmpty
          ? _iconController.text.trim()
          : '➕',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Tombol Cepat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Divider(height: 24),
            // ==> 4. TAMBAHKAN UI UNTUK MENGGANTI IKON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _iconController,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Simbol Ikon',
                  helperText: 'Gunakan emoji atau 1-2 karakter.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                children: _iconSuggestions.map((icon) {
                  return ActionChip(
                    label: Text(icon),
                    onPressed: () {
                      _iconController.text = icon;
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
