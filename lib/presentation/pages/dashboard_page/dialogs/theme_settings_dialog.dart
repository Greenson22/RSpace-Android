// lib/presentation/pages/dashboard_page/dialogs/theme_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_theme.dart';

/// Menampilkan dialog pengaturan tema yang terpusat.
void showThemeSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ThemeSettingsDialog(),
  );
}

class ThemeSettingsDialog extends StatefulWidget {
  const ThemeSettingsDialog({super.key});

  @override
  State<ThemeSettingsDialog> createState() => _ThemeSettingsDialogState();
}

class _ThemeSettingsDialogState extends State<ThemeSettingsDialog> {
  late bool _isDark;
  late bool _isChristmas;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _isDark = provider.darkTheme;
    _isChristmas = provider.isChristmasTheme;
    _selectedColor = provider.primaryColor;
  }

  /// Menyimpan semua perubahan tema dan menutup dialog.
  void _handleSave() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    provider.updateTheme(
      isDark: _isDark,
      isChristmas: _isChristmas,
      color: _selectedColor,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // ==> DAPATKAN PROVIDER TEMA DI SINI <==
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Pengaturan Tema'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Mode Gelap'),
              secondary: const Icon(Icons.nightlight_round),
              value: _isDark,
              onChanged: (value) => setState(() => _isDark = value),
            ),
            SwitchListTile(
              title: const Text('Tema Spesial Natal'),
              secondary: const Icon(Icons.celebration_outlined),
              value: _isChristmas,
              onChanged: (value) => setState(() => _isChristmas = value),
            ),
            const Divider(),
            // ==> BAGIAN BARU UNTUK LATAR BELAKANG <==
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Latar Dasbor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Pilih Gambar'),
                      onPressed: () async {
                        await themeProvider.setBackgroundImage();
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Hapus Gambar Latar',
                    onPressed: () async {
                      await themeProvider.clearBackgroundImage();
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            // --- AKHIR BAGIAN BARU ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Warna Primer',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // Color picker yang interaktif
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) => setState(() => _selectedColor = color),
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hueWheel,
            ),
            const SizedBox(height: 16),
            // Palet warna yang telah ditentukan
            BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              availableColors: AppTheme.selectableColors,
              layoutBuilder: (context, colors, child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => child(color)).toList(),
                );
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
          onPressed: _handleSave,
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}
