// lib/presentation/pages/backup_management_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart'; // Placeholder untuk fungsionalitas share
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

  Future<void> _selectPerpuskuDataFolder(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Sumber Data PerpusKu',
    );

    if (selectedDirectory != null) {
      await provider.setPerpuskuDataPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Folder sumber data PerpusKu berhasil diatur.',
        );
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

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

    final zipFile = File(result.files.single.path!);
    await _importSpecificFile(context, zipFile, type);
  }

  Future<void> _importSpecificFile(
    BuildContext context,
    File zipFile,
    String type,
  ) async {
    final confirmed = await _showImportConfirmationDialog(context, type);
    if (!confirmed) {
      if (context.mounted) {
        showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
      }
      return;
    }

    showAppSnackBar(context, 'Memulai proses import...');
    final provider = Provider.of<BackupProvider>(context, listen: false);
    try {
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

  // ==> FUNGSI BARU UNTUK BERBAGI FILE <==
  Future<void> _shareFile(BuildContext context, File file) async {
    try {
      // Untuk fungsionalitas ini, Anda perlu menambahkan package seperti 'share_plus'
      // await Share.shareXFiles([XFile(file.path)], text: 'Ini adalah backup data saya.');
      // Placeholder karena tidak bisa menambah package:
      showAppSnackBar(context, 'Fungsi berbagi belum diimplementasikan.');
    } catch (e) {
      showAppSnackBar(context, 'Gagal membagikan file: $e', isError: true);
    }
  }

  // ==> FUNGSI BARU UNTUK MENGHAPUS FILE <==
  Future<void> _deleteFile(BuildContext context, File file) async {
    final confirmed = await _showDeleteConfirmationDialog(context, file);
    if (confirmed) {
      try {
        await file.delete();
        // Refresh daftar file setelah menghapus
        await Provider.of<BackupProvider>(
          context,
          listen: false,
        ).listBackupFiles();
        if (context.mounted) {
          showAppSnackBar(context, 'File backup berhasil dihapus.');
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Gagal menghapus file: $e', isError: true);
        }
      }
    }
  }

  // ==> DIALOG BARU UNTUK KONFIRMASI HAPUS <==
  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    File file,
  ) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Anda yakin ingin menghapus file "$fileName"?'),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

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

            return LayoutBuilder(
              builder: (context, constraints) {
                const double breakpoint = 1000.0;
                if (constraints.maxWidth > breakpoint) {
                  return _buildDesktopLayout(context, provider);
                } else {
                  return _buildMobileLayout(context, provider);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, BackupProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildPathInfoCard(context, provider, isCard: true),
        const SizedBox(height: 8),
        _buildPerpuskuPathCard(context, provider, isCard: true),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBackupSection(
                context: context,
                title: 'RSpace',
                files: provider.rspaceBackupFiles,
                onBackup: () => _backupContents(context, 'RSpace'),
                onImport: () => _importContents(context, 'RSpace'),
                provider: provider,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBackupSection(
                context: context,
                title: 'PerpusKu',
                files: provider.perpuskuBackupFiles,
                onBackup: () => _backupContents(context, 'PerpusKu'),
                onImport: () => _importContents(context, 'PerpusKu'),
                provider: provider,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BackupProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                "Pengaturan Folder",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildPathInfoCard(context, provider, isCard: true),
              const SizedBox(height: 16),
              _buildPerpuskuPathCard(context, provider, isCard: true),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBackupSection(
                context: context,
                title: 'Backup RSpace',
                files: provider.rspaceBackupFiles,
                onBackup: () => _backupContents(context, 'RSpace'),
                onImport: () => _importContents(context, 'RSpace'),
                provider: provider,
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildBackupSection(
                context: context,
                title: 'Backup PerpusKu',
                files: provider.perpuskuBackupFiles,
                onBackup: () => _backupContents(context, 'PerpusKu'),
                onImport: () => _importContents(context, 'PerpusKu'),
                provider: provider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPathInfoCard(
    BuildContext context,
    BackupProvider provider, {
    bool isCard = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Folder Tujuan Backup',
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
              label: const Text('Ubah Folder Tujuan'),
              onPressed: () => _selectBackupFolder(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
    return isCard ? Card(child: content) : content;
  }

  Widget _buildPerpuskuPathCard(
    BuildContext context,
    BackupProvider provider, {
    bool isCard = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Folder Sumber Data PerpusKu',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih folder yang berisi data PerpusKu yang ingin Anda backup. Jika tidak diisi, akan digunakan folder default aplikasi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.perpuskuDataPath ?? 'Menggunakan folder default.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Ubah Folder Sumber Data'),
              onPressed: () => _selectPerpuskuDataFolder(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
    return isCard ? Card(child: content) : content;
  }

  Widget _buildBackupSection({
    required BuildContext context,
    required String title,
    required List<File> files,
    required VoidCallback onBackup,
    required VoidCallback onImport,
    required BackupProvider provider,
    bool isCompact = false,
  }) {
    final bool isActionInProgress =
        provider.isBackingUp || provider.isImporting;
    final theme = Theme.of(context);

    Widget loadingIndicator() {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    Widget loadingIndicatorOutline() {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.primaryColor,
        ),
      );
    }

    final buttonPadding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  (isCompact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: provider.isBackingUp
                      ? const SizedBox.shrink()
                      : const Icon(Icons.backup_outlined),
                  label: provider.isBackingUp
                      ? loadingIndicator()
                      : const Text('Backup'),
                  onPressed: isActionInProgress ? null : onBackup,
                  style: ElevatedButton.styleFrom(
                    padding: buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: provider.isImporting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.restore),
                  label: provider.isImporting
                      ? loadingIndicatorOutline()
                      : const Text('Import'),
                  onPressed: isActionInProgress ? null : onImport,
                  style: OutlinedButton.styleFrom(
                    padding: buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'File Tersimpan',
              style: isCompact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleMedium,
            ),
            const Divider(),
            if (files.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Tidak ada file .zip ditemukan.',
                    textAlign: TextAlign.center,
                  ),
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
                  'd MMM yyyy, HH:mm',
                  'id_ID',
                ).format(lastModified);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 10),
                  ),
                  contentPadding: const EdgeInsets.only(left: 4),
                  // ==> PERUBAHAN UTAMA DI SINI <==
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      final backupType = title.contains('RSpace')
                          ? 'RSpace'
                          : 'PerpusKu';
                      if (value == 'import') {
                        _importSpecificFile(context, file, backupType);
                      } else if (value == 'share') {
                        _shareFile(context, file);
                      } else if (value == 'delete') {
                        _deleteFile(context, file);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'import',
                            child: ListTile(
                              leading: Icon(Icons.restore),
                              title: Text('Import'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share_outlined),
                              title: Text('Bagikan'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
