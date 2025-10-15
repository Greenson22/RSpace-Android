// lib/features/settings/presentation/dialogs/theme_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../application/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
  late bool _isUnderwater;
  late Color _selectedColor;
  late double _dashboardScale;
  late double _uiScale;
  late double _dashboardComponentOpacity; // ==> STATE BARU DITAMBAHKAN
  late bool _openInAppBrowser;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    _isDark = provider.darkTheme;
    _isChristmas = provider.isChristmasTheme;
    _isUnderwater = provider.isUnderwaterTheme;
    _selectedColor = provider.primaryColor;
    _dashboardScale = provider.dashboardItemScale;
    _uiScale = provider.uiScaleFactor;
    _dashboardComponentOpacity =
        provider.dashboardComponentOpacity; // ==> INISIALISASI STATE BARU
    _openInAppBrowser = provider.openInAppBrowser;
  }

  /// Menyimpan semua perubahan tema dan menutup dialog.
  void _handleSave() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    provider.updateTheme(
      isDark: _isDark,
      isChristmas: _isChristmas,
      isUnderwater: _isUnderwater,
      color: _selectedColor,
      dashboardScale: _dashboardScale,
      uiScale: _uiScale,
      dashboardComponentOpacity:
          _dashboardComponentOpacity, // ==> KIRIM NILAI BARU
    );
    if (provider.openInAppBrowser != _openInAppBrowser) {
      provider.toggleOpenInAppBrowser();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            SwitchListTile(
              title: const Text('Tema Spesial Bawah Air'),
              secondary: const Icon(Icons.pool_outlined),
              value: _isUnderwater,
              onChanged: (value) => setState(() => _isUnderwater = value),
            ),
            SwitchListTile(
              title: const Text('Buka Link di Aplikasi'),
              subtitle: const Text(
                'Gunakan WebView internal untuk membuka file HTML.',
              ),
              secondary: const Icon(Icons.open_in_new),
              value: _openInAppBrowser,
              onChanged: (value) => setState(() => _openInAppBrowser = value),
            ),
            const Divider(),
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
                      await themeProvider.clearBackgroundImagePath();
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),

            // ==> BAGIAN BARU UNTUK TRANSPARANSI <==
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transparansi Dasbor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(_dashboardComponentOpacity * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Slider(
              value: _dashboardComponentOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label:
                  '${(_dashboardComponentOpacity * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _dashboardComponentOpacity = value;
                });
              },
            ),
            const Divider(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skala Tampilan Global',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(_uiScale * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Slider(
              value: _uiScale,
              min: 0.3,
              max: 1.5,
              divisions: 12,
              label: '${(_uiScale * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _uiScale = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ukuran Menu Dasbor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(_dashboardScale * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Slider(
              value: _dashboardScale,
              min: 0.8,
              max: 1.2,
              divisions: 4,
              label: '${(_dashboardScale * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _dashboardScale = value;
                });
              },
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Warna Primer',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
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
