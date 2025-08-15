// lib/presentation/pages/backup_management_page.dart
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
      dialogTitle: 'Pilih Folder Backup Utama',
    );

    if (selectedDirectory != null) {
      await provider.setBackupPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder backup utama berhasil diatur.');
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  // ==> FUNGSI BARU UNTUK MEMILIH FOLDER PERPUSKU <==
  Future<void> _selectPerpuskuBackupFolder(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Backup PerpusKu',
    );

    if (selectedDirectory != null) {
      await provider.setPerpuskuBackupPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder backup PerpusKu berhasil diatur.');
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  // ... (kode _backupContents, _importContents, dan _showImportConfirmationDialog tetap sama) ...
  Future<void> _backupContents(BuildContext context, String type) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    if (provider.backupPath == null || provider.backupPath!.isEmpty) {
      showAppSnackBar(
        context,
        'Folder backup utama belum ditentukan.',
        isError: true,
      );
      return;
    }

    showAppSnackBar(context, 'Memulai proses backup $type...');
    try {
      String message;
      if (type == 'RSpace') {
        message = await provider.backupRspaceContents();
      } else {
        message = await provider.backupPerpuskuContents();
      }
      if (context.mounted) showAppSnackBar(context, message);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Terjadi error saat backup: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _importContents(BuildContext context, String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) {
      if (context.mounted) showAppSnackBar(context, 'Import dibatalkan.');
      return;
    }

    final confirmed = await _showImportConfirmationDialog(context, type);
    if (!confirmed) {
      if (context.mounted)
        showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
      return;
    }

    showAppSnackBar(context, 'Memulai proses import...');
    final provider = Provider.of<BackupProvider>(context, listen: false);
    try {
      final zipFile = File(result.files.single.path!);
      await provider.importContents(zipFile, type);
      if (context.mounted) {
        if (type == 'RSpace') {
          await Provider.of<TopicProvider>(
            context,
            listen: false,
          ).fetchTopics();
        }
        showAppSnackBar(context, 'Import $type berhasil!');
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

  Future<bool> _showImportConfirmationDialog(
    BuildContext context,
    String type,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Konfirmasi Import $type'),
            content: Text(
              'PERINGATAN: Tindakan ini akan menghapus semua data $type saat ini dan menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?',
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

  // ==> FUNGSI build DIPERBARUI <==
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

            return ListView(
              // Diubah dari Column ke ListView
              children: [
                _buildPathInfoCard(context, provider),
                const Divider(height: 1),
                // ==> BAGIAN BARU UNTUK FOLDER PERPUSKU <==
                _buildPerpuskuPathCard(context, provider),
                const Divider(height: 1),
                _buildBackupSection(
                  context: context,
                  title: 'Backup RSpace',
                  files: provider.rspaceBackupFiles,
                  onBackup: () => _backupContents(context, 'RSpace'),
                  onImport: () => _importContents(context, 'RSpace'),
                  provider: provider,
                ),
                const Divider(),
                _buildBackupSection(
                  context: context,
                  title: 'Backup PerpusKu',
                  files: provider.perpuskuBackupFiles,
                  onBackup: () => _backupContents(context, 'PerpusKu'),
                  onImport: () => _importContents(context, 'PerpusKu'),
                  provider: provider,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ... (kode _buildPathInfoCard dan _buildBackupSection tetap sama) ...
  Widget _buildPathInfoCard(BuildContext context, BackupProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Folder Backup Utama (RSpace)',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.backupPath ?? 'Folder belum ditentukan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Ubah Folder Utama'),
              onPressed: () => _selectBackupFolder(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==> WIDGET BARU UNTUK INFO PATH PERPUSKU <==
  Widget _buildPerpuskuPathCard(BuildContext context, BackupProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Folder Backup PerpusKu (Opsional)',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Jika tidak diisi, akan mengikuti Folder Backup Utama.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.perpuskuBackupPath ?? 'Folder belum ditentukan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Ubah Folder PerpusKu'),
              onPressed: () => _selectPerpuskuBackupFolder(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection({
    required BuildContext context,
    required String title,
    required List<File> files,
    required VoidCallback onBackup,
    required VoidCallback onImport,
    required BackupProvider provider,
  }) {
    final bool isActionInProgress =
        provider.isBackingUp || provider.isImporting;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
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
                  onPressed: isActionInProgress ? null : onBackup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
                  onPressed: isActionInProgress ? null : onImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'File Tersimpan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('Tidak ada file backup (.zip) ditemukan.'),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file.path.split(Platform.pathSeparator).last;
              final lastModified = file.lastModifiedSync();
              final formattedDate = DateFormat(
                'd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(lastModified);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined, size: 32),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Tanggal: $formattedDate'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
