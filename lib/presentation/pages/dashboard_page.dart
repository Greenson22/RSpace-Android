// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '1_topics_page.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'my_tasks_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBackingUp = false;
  bool _isImporting = false;
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  Future<void> _backupContents(BuildContext context) async {
    String? destinationPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Backup',
    );

    if (destinationPath == null) {
      if (mounted) showAppSnackBar(context, 'Backup dibatalkan.');
      return;
    }

    final topicProvider = Provider.of<TopicProvider>(context, listen: false);

    setState(() {
      _isBackingUp = true;
    });

    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await topicProvider.backupContents(
        destinationPath: destinationPath,
      );
      showAppSnackBar(context, message);
    } catch (e) {
      String errorMessage = 'Terjadi error saat backup: $e';
      if (e is FileSystemException) {
        errorMessage = 'Error: Gagal menulis file. Periksa izin aplikasi.';
      }
      showAppSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
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
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<bool> _showImportConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Import'),
            content: const Text(
              'PERINGATAN: Tindakan ini akan menghapus semua folder "topics" dan file "my_tasks.json" saat ini, lalu menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?',
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

  Future<void> _showStoragePathDialog(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Utama',
    );

    if (selectedDirectory != null) {
      final prefsService = SharedPreferencesService();
      await prefsService.saveCustomStoragePath(selectedDirectory);
      if (mounted) {
        showAppSnackBar(
          context,
          'Lokasi disimpan. Mohon restart aplikasi untuk menerapkan.',
        );
      }
    } else {
      if (mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () {
              themeProvider.darkTheme = !themeProvider.darkTheme;
            },
            tooltip: 'Ganti Tema',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClock(),
          Expanded(
            child: Center(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                children: <Widget>[
                  _buildDashboardItem(
                    context,
                    icon: Icons.topic_outlined,
                    label: 'Topics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopicsPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.task_alt,
                    label: 'My Tasks',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyTasksPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.backup_outlined,
                    label: 'Backup',
                    onTap: () => _backupContents(context),
                    child: _isBackingUp
                        ? const CircularProgressIndicator()
                        : null,
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.restore,
                    label: 'Import',
                    onTap: () => _importContents(context),
                    child: _isImporting
                        ? const CircularProgressIndicator()
                        : null,
                  ),
                  if (Platform.isAndroid)
                    _buildDashboardItem(
                      context,
                      icon: Icons.folder_open_rounded,
                      label: 'Penyimpanan',
                      onTap: () => _showStoragePathDialog(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return StreamBuilder<DateTime>(
      stream: _clockStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final now = snapshot.data!;
          final dateFormatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
          final timeFormatter = DateFormat('HH:mm:ss');
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Text(
                  dateFormatter.format(now),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  timeFormatter.format(now),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          );
        }
        return const SizedBox(height: 80);
      },
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child:
            child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 50, color: Theme.of(context).primaryColor),
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontSize: 18)),
              ],
            ),
      ),
    );
  }
}
