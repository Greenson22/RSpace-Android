// lib/presentation/pages/linux/dashboard_page_linux.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
// DIUBAH: Import MainViewLinux yang baru
import 'main_view_linux.dart';
import '../1_topics_page/utils/scaffold_messenger_utils.dart';
import '../my_tasks_page.dart';
import '../statistics_page.dart';
import '../about_page.dart';

/// Halaman dashboard yang dioptimalkan untuk tampilan Desktop (Linux).
/// Menggunakan NavigationRail untuk sidebar navigasi.
class DashboardPageLinux extends StatefulWidget {
  const DashboardPageLinux({super.key});

  @override
  State<DashboardPageLinux> createState() => _DashboardPageLinuxState();
}

class _DashboardPageLinuxState extends State<DashboardPageLinux> {
  int _selectedIndex = 0;
  bool _isBackingUp = false;
  bool _isImporting = false;

  // DIUBAH: Ganti TopicsPage dengan MainViewLinux
  final List<Widget> _pages = [
    const MainViewLinux(),
    const MyTasksPage(),
    const StatisticsPage(),
  ];

  // ... (sisa fungsi _backupContents, _importContents, _showImportConfirmationDialog tidak berubah) ...
  Future<void> _backupContents(BuildContext context) async {
    String? destinationPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Backup',
    );

    if (destinationPath == null) {
      if (mounted) showAppSnackBar(context, 'Backup dibatalkan.');
      return;
    }

    final topicProvider = Provider.of<TopicProvider>(context, listen: false);

    setState(() => _isBackingUp = true);
    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await topicProvider.backupContents(
        destinationPath: destinationPath,
      );
      if (mounted) showAppSnackBar(context, message);
    } catch (e) {
      String errorMessage = 'Terjadi error saat backup: $e';
      if (e is FileSystemException) {
        errorMessage = 'Error: Gagal menulis file. Periksa izin aplikasi.';
      }
      if (mounted) showAppSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _importContents(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      if (mounted) showAppSnackBar(context, 'Import dibatalkan.');
      return;
    }

    final confirmed = await _showImportConfirmationDialog(context);
    if (!confirmed) {
      if (mounted) showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
      return;
    }

    setState(() => _isImporting = true);
    showAppSnackBar(context, 'Memulai proses import...');

    try {
      final zipFile = File(result.files.single.path!);
      final topicProvider = Provider.of<TopicProvider>(context, listen: false);
      await topicProvider.importContents(zipFile);
      if (mounted) {
        showAppSnackBar(
          context,
          'Import berhasil. Mohon restart aplikasi untuk menerapkan perubahan.',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Terjadi error saat import: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<bool> _showImportConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Import'),
            content: const Text(
              'PERINGATAN: Tindakan ini akan menghapus semua data saat ini dan menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?',
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Lanjutkan'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ==> FUNGSI BARU UNTUK MENAMPILKAN DIALOG PEMILIH WARNA <==
  void _showColorPickerDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    Color pickerColor = themeProvider.primaryColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Warna Primer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) => pickerColor = color,
                  labelTypes: const [ColorLabelType.hex],
                  pickerAreaHeightPercent: 0.8,
                  enableAlpha: false,
                ),
                const Divider(),
                Text(
                  'Pilihan Warna',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                BlockPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) {
                    pickerColor = color;
                    themeProvider.setPrimaryColor(pickerColor);
                    Navigator.of(context).pop();
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
                const Divider(),
                Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    if (provider.recentColors.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Warna Terakhir Digunakan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        BlockPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (color) {
                            pickerColor = color;
                            themeProvider.setPrimaryColor(pickerColor);
                            Navigator.of(context).pop();
                          },
                          availableColors: provider.recentColors,
                          layoutBuilder: (context, colors, child) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: colors
                                  .map((color) => child(color))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Pilih'),
              onPressed: () {
                themeProvider.setPrimaryColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Icon(
                Icons.space_dashboard_rounded,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.topic_outlined),
                selectedIcon: Icon(Icons.topic),
                label: Text('Content'), // Label diubah agar lebih umum
              ),
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('My Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text('Statistik'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildTrailingMenu(context),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  // ... (sisa dari _buildTrailingMenu tidak berubah) ...
  Widget _buildTrailingMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ==> TOMBOL-TOMBOL BARU DITAMBAHKAN DI SINI <==
        IconButton(
          icon: const Icon(Icons.color_lens_outlined),
          tooltip: 'Ganti Warna Primer',
          onPressed: () => _showColorPickerDialog(context),
        ),
        const SizedBox(height: 16),
        IconButton(
          icon: Icon(
            themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
          ),
          tooltip: 'Ganti Tema',
          onPressed: () => themeProvider.darkTheme = !themeProvider.darkTheme,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        IconButton(
          icon: _isBackingUp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.backup_outlined),
          tooltip: 'Backup Data',
          onPressed: _isBackingUp ? null : () => _backupContents(context),
        ),
        const SizedBox(height: 16),
        IconButton(
          icon: _isImporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.restore_outlined),
          tooltip: 'Import Data',
          onPressed: _isImporting ? null : () => _importContents(context),
        ),
        const SizedBox(height: 16),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Tentang Aplikasi',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const Dialog(
                child: SizedBox(
                  width: 500, // Atur lebar dialog
                  height: 600, // Atur tinggi dialog
                  child: AboutPage(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
