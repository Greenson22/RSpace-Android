import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart'; // Import SharedPreferencesService
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

  // ==> FUNGSI BARU UNTUK MENAMPILKAN DIALOG PILIHAN PENYIMPANAN <==
  Future<void> _showStorageSelectionDialog(BuildContext context) async {
    final prefsService = SharedPreferencesService();
    String currentSelection = await prefsService.loadStorageLocation();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Lokasi Penyimpanan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Internal'),
                    subtitle: const Text('Direktori privat aplikasi'),
                    value: 'internal',
                    groupValue: currentSelection,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => currentSelection = value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Eksternal'),
                    subtitle: const Text('Direktori bersama (memerlukan izin)'),
                    value: 'external',
                    groupValue: currentSelection,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => currentSelection = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aplikasi perlu dimulai ulang agar perubahan diterapkan sepenuhnya.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    await prefsService.saveStorageLocation(currentSelection);
                    Navigator.pop(context);
                    showAppSnackBar(
                      context,
                      'Lokasi disimpan. Mohon restart aplikasi.',
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
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
            // ==> ITEM BARU, HANYA MUNCUL DI ANDROID <==
            if (Platform.isAndroid)
              _buildDashboardItem(
                context,
                icon: Icons.storage_rounded,
                label: 'Penyimpanan',
                onTap: () => _showStorageSelectionDialog(context),
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
