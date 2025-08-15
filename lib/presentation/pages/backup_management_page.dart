import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import '../providers/topic_provider.dart'; // Import untuk refresh data

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  Future<void> _selectBackupFolder(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Backup',
    );

    if (selectedDirectory != null) {
      await provider.setBackupPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder backup berhasil diubah.');
      }
    } else {
      if (context.mounted)
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
    }
  }

  // --- FUNGSI BARU UNTUK PROSES BACKUP & IMPORT ---
  Future<void> _backupContents(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    if (provider.backupPath == null) {
      showAppSnackBar(
        context,
        'Folder backup belum ditentukan.',
        isError: true,
      );
      return;
    }

    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await provider.backupContents(
        destinationPath: provider.backupPath!,
      );
      if (context.mounted) showAppSnackBar(context, message);
    } catch (e) {
      String errorMessage = 'Terjadi error saat backup: $e';
      if (e is FileSystemException) {
        errorMessage = 'Error: Gagal menulis file. Periksa izin aplikasi.';
      }
      if (context.mounted)
        showAppSnackBar(context, errorMessage, isError: true);
    }
  }

  Future<void> _importContents(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) {
      if (context.mounted) showAppSnackBar(context, 'Import dibatalkan.');
      return;
    }

    final confirmed = await _showImportConfirmationDialog(context);
    if (!confirmed) {
      if (context.mounted)
        showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
      return;
    }

    showAppSnackBar(context, 'Memulai proses import...');
    final provider = Provider.of<BackupProvider>(context, listen: false);
    try {
      final zipFile = File(result.files.single.path!);
      await provider.importContents(zipFile);
      if (context.mounted) {
        // Refresh data di TopicProvider setelah import
        await Provider.of<TopicProvider>(context, listen: false).fetchTopics();
        showAppSnackBar(
          context,
          'Import berhasil. Aplikasi akan terasa segar!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Terjadi error saat import: $e',
          isError: true,
        );
      }
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
  // --- Akhir dari fungsi baru ---

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackupProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manajemen Backup')),
        body: Consumer<BackupProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildPathInfoCard(context, provider),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Daftar File Backup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(child: _buildBackupList(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPathInfoCard(BuildContext context, BackupProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Folder Backup Aktif',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            provider.backupPath ?? 'Folder belum ditentukan.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Ubah Folder'),
                  onPressed: () => _selectBackupFolder(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: provider.isBackingUp
                      ? const SizedBox.shrink()
                      : const Icon(Icons.backup_outlined),
                  label: provider.isBackingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Backup'),
                  onPressed: provider.isBackingUp
                      ? null
                      : () => _backupContents(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: provider.isImporting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.restore),
                  label: provider.isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Import'),
                  onPressed: provider.isImporting
                      ? null
                      : () => _importContents(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList(BackupProvider provider) {
    if (provider.backupPath == null || provider.backupPath!.isEmpty) {
      return const Center(
        child: Text('Tentukan folder backup untuk melihat file.'),
      );
    }

    if (provider.backupFiles.isEmpty) {
      return const Center(
        child: Text('Tidak ada file backup (.zip) ditemukan di folder ini.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: provider.backupFiles.length,
      itemBuilder: (context, index) {
        final file = provider.backupFiles[index];
        final fileName = file.path.split(Platform.pathSeparator).last;
        final lastModified = file.lastModifiedSync();
        final formattedDate = DateFormat(
          'd MMMM yyyy, HH:mm',
          'id_ID',
        ).format(lastModified);

        return Card(
          child: ListTile(
            leading: const Icon(Icons.archive_outlined, size: 40),
            title: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Tanggal: $formattedDate'),
          ),
        );
      },
    );
  }
}
