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
  late String _quickFabIcon;
  late TextEditingController _iconController;
  // ==> 1. TAMBAHKAN STATE LOKAL UNTUK SLIDER
  late double _bgOpacity;
  late double _overallOpacity;

  final List<String> _iconSuggestions = ['➕', '📝', '⚡', '💡', '💬', '⭐'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _showQuickFab = provider.showQuickFab;
    _quickFabIcon = provider.quickFabIcon;
    _iconController = TextEditingController(text: _quickFabIcon);
    // ==> 2. INISIALISASI STATE SLIDER
    _bgOpacity = provider.quickFabBgOpacity;
    _overallOpacity = provider.quickFabOverallOpacity;
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _handleSaveChanges() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    // ==> 3. KIRIM SEMUA NILAI BARU KE PROVIDER
    provider.updateQuickFabSettings(
      show: _showQuickFab,
      icon: _iconController.text.trim().isNotEmpty
          ? _iconController.text.trim()
          : '➕',
      bgOpacity: _bgOpacity,
      overallOpacity: _overallOpacity,
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
            const Divider(height: 24),
            // ==> 4. TAMBAHKAN UI SLIDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transparansi Latar (${(_bgOpacity * 100).toInt()}%)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Slider(
              value: _bgOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() => _bgOpacity = value);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transparansi Keseluruhan (${(_overallOpacity * 100).toInt()}%)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Slider(
              value: _overallOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() => _overallOpacity = value);
              },
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
