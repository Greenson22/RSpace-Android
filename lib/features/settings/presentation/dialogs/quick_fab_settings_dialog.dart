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

// Ubah menjadi StatelessWidget karena state akan dikelola oleh provider secara real-time.
class QuickFabSettingsDialog extends StatelessWidget {
  const QuickFabSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar UI di dalam dialog bisa ikut diperbarui.
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        final iconController = TextEditingController(
          text: provider.quickFabIcon,
        );
        // Pindahkan kursor ke akhir teks saat controller dibuat.
        iconController.selection = TextSelection.fromPosition(
          TextPosition(offset: iconController.text.length),
        );

        final List<String> iconSuggestions = ['➕', '📝', '⚡', '💡', '💬', '⭐'];

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
                  value: provider.showQuickFab,
                  onChanged: (value) {
                    // Langsung panggil provider, tanpa setState
                    provider.updateQuickFabSettings(show: value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Tampilkan Teks di Menu'),
                  subtitle: const Text(
                    'Jika nonaktif, menu hanya akan menampilkan ikon.',
                  ),
                  value: provider.fabMenuShowText,
                  onChanged: (value) {
                    provider.updateQuickFabSettings(showMenuText: value);
                  },
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: iconController,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'Simbol Ikon',
                      helperText: 'Gunakan emoji atau 1-2 karakter.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Terapkan secara real-time saat pengguna mengetik
                      provider.updateQuickFabSettings(icon: value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: iconSuggestions.map((icon) {
                      return ActionChip(
                        label: Text(icon),
                        onPressed: () {
                          iconController.text = icon;
                          // Langsung panggil provider saat chip dipilih
                          provider.updateQuickFabSettings(icon: icon);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Ukuran Tombol (${provider.quickFabSize.toInt()} px)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Slider(
                  value: provider.quickFabSize,
                  min: 40.0,
                  max: 80.0,
                  divisions: 4,
                  label: '${provider.quickFabSize.toInt()}',
                  onChanged: (value) {
                    // Langsung panggil provider saat slider digeser
                    provider.updateQuickFabSettings(size: value);
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Transparansi Latar (${(provider.quickFabBgOpacity * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Slider(
                  value: provider.quickFabBgOpacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    // Langsung panggil provider saat slider digeser
                    provider.updateQuickFabSettings(bgOpacity: value);
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Transparansi Keseluruhan (${(provider.quickFabOverallOpacity * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Slider(
                  value: provider.quickFabOverallOpacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    // Langsung panggil provider saat slider digeser
                    provider.updateQuickFabSettings(overallOpacity: value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Tombol Simpan tidak lagi diperlukan, diganti dengan Tutup
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
