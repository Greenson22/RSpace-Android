// lib/presentation/pages/dashboard_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/topic_provider.dart';
import '1_topics_page.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'my_tasks_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBackingUp = false;

  Future<void> _backupContents(BuildContext context) async {
    final String? destinationPath = await showBackupPathDialog(context);

    if (destinationPath == null || destinationPath.isEmpty) {
      if (mounted) showAppSnackBar(context, 'Backup dibatalkan.');
      return;
    }

    final topicProvider = TopicProvider();

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

  // ==> DIALOG PEMILIHAN LOKASI PENYIMPANAN DIUBAH TOTAL <==
  Future<void> _showStoragePathDialog(BuildContext context) async {
    final prefsService = SharedPreferencesService();
    final currentPath = await prefsService.loadCustomStoragePath() ?? '';

    await showPathInputDialog(
      context: context,
      title: 'Pilih Folder Penyimpanan Utama',
      label: 'Path Folder',
      initialValue: currentPath,
      hint: 'Contoh: /storage/emulated/0/MyAppData',
      onSave: (newPath) async {
        await prefsService.saveCustomStoragePath(newPath);
        showAppSnackBar(
          context,
          'Lokasi disimpan. Mohon restart aplikasi untuk menerapkan.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
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
                  MaterialPageRoute(builder: (context) => const TopicsPage()),
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
                  MaterialPageRoute(builder: (context) => const MyTasksPage()),
                );
              },
            ),
            _buildDashboardItem(
              context,
              icon: Icons.backup_outlined,
              label: 'Backup',
              onTap: () => _backupContents(context),
              child: _isBackingUp ? const CircularProgressIndicator() : null,
            ),
            // ==> ITEM INI SEKARANG MEMANGGIL DIALOG BARU <==
            if (Platform.isAndroid)
              _buildDashboardItem(
                context,
                icon: Icons.folder_open_rounded, // Ikon diubah
                label: 'Penyimpanan',
                onTap: () => _showStoragePathDialog(context),
              ),
          ],
        ),
      ),
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
