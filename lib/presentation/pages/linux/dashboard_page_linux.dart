// lib/presentation/pages/dashboard_page_linux.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/topic_provider.dart';
import '../1_topics_page.dart';
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

  // Daftar halaman yang akan ditampilkan di area konten
  final List<Widget> _pages = [
    const TopicsPage(),
    const MyTasksPage(),
    const StatisticsPage(),
  ];

  // Fungsi untuk backup (sama seperti sebelumnya)
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

  // Fungsi untuk import (sama seperti sebelumnya)
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
            // Daftar menu utama di sidebar
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.topic_outlined),
                selectedIcon: Icon(Icons.topic),
                label: Text('Topics'),
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
            // Menu tambahan di bagian bawah sidebar
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
          // Area konten utama yang akan berubah sesuai pilihan di sidebar
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  // Widget untuk menu tambahan (Backup, Import, About)
  Widget _buildTrailingMenu(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
