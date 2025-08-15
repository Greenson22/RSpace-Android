// lib/presentation/pages/backup_management_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../providers/backup_provider.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import '../providers/topic_provider.dart';
import 'dart:math';

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // ==> FUNGSI INI SEKARANG MENGATUR PATH BACKUP SECARA SPESIFIK <==
  Future<void> _selectBackupFolder(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Backup', // Diubah agar lebih jelas
    );

    if (selectedDirectory != null) {
      // Memanggil fungsi yang benar di provider
      await provider.setBackupPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder tujuan backup berhasil diatur.');
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
        'Folder tujuan backup belum ditentukan.', // Pesan disesuaikan
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

  Future<void> _shareFile(BuildContext context, File file) async {
    try {
      final result = await Share.shareXFiles([
        XFile(file.path),
      ], text: 'File backup dari aplikasi saya.');

      if (result.status == ShareResultStatus.unavailable) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Fitur berbagi tidak tersedia, alihkan ke mode salin file.',
          );
          await _copyBackupFile(context, file);
        }
      } else if (result.status == ShareResultStatus.success &&
          context.mounted) {
        showAppSnackBar(context, 'File berhasil dibagikan.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal memulai fitur berbagi. Beralih ke mode salin file.',
          isError: true,
        );
        await _copyBackupFile(context, file);
      }
    }
  }

  Future<void> _copyBackupFile(BuildContext context, File sourceFile) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Lokasi untuk Menyimpan Salinan',
      );

      if (selectedDirectory != null) {
        final fileName = path.basename(sourceFile.path);
        final destinationPath = path.join(selectedDirectory, fileName);

        await sourceFile.copy(destinationPath);

        if (context.mounted) {
          showAppSnackBar(context, 'File berhasil disalin ke tujuan.');
        }
      } else {
        if (context.mounted) {
          showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Gagal menyalin file: $e', isError: true);
      }
    }
  }

  Future<void> _deleteSelectedFiles(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    final count = provider.selectedFiles.length;
    final confirmed = await _showDeleteConfirmationDialog(
      context,
      'Anda yakin ingin menghapus $count file yang dipilih?',
    );

    if (confirmed) {
      try {
        await provider.deleteSelectedFiles();
        if (context.mounted) {
          showAppSnackBar(context, '$count file backup berhasil dihapus.');
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Gagal menghapus file: $e', isError: true);
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(message),
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
      child: Consumer<BackupProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: provider.isSelectionMode
                ? _buildSelectionAppBar(context, provider)
                : AppBar(title: const Text('Manajemen Backup')),
            body: WillPopScope(
              onWillPop: () async {
                if (provider.isSelectionMode) {
                  provider.clearSelection();
                  return false;
                }
                return true;
              },
              child: Builder(
                builder: (context) {
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
        },
      ),
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, BackupProvider provider) {
    return AppBar(
      title: Text('${provider.selectedFiles.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () {
            provider.selectAllFiles([
              ...provider.rspaceBackupFiles,
              ...provider.perpuskuBackupFiles,
            ]);
          },
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteSelectedFiles(context),
          tooltip: 'Hapus Pilihan',
        ),
      ],
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

    final isPerpuskuBackup = title.contains('PerpusKu');
    final isPerpuskuPathSet =
        provider.perpuskuDataPath != null &&
        provider.perpuskuDataPath!.isNotEmpty;
    final isPerpuskuBackupDisabled = isPerpuskuBackup && !isPerpuskuPathSet;

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
            if (!provider.isSelectionMode)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: provider.isBackingUp && !isPerpuskuBackup
                        ? const SizedBox.shrink()
                        : const Icon(Icons.backup_outlined),
                    label: provider.isBackingUp && !isPerpuskuBackup
                        ? loadingIndicator()
                        : const Text('Backup'),
                    onPressed: isActionInProgress || isPerpuskuBackupDisabled
                        ? null
                        : onBackup,
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
            if (isPerpuskuBackupDisabled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tentukan folder sumber data PerpusKu untuk mengaktifkan backup.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
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
                final isSelected = provider.selectedFiles.contains(file.path);

                final fileName = file.path.split(Platform.pathSeparator).last;
                final lastModified = file.lastModifiedSync();
                final fileSize = file.lengthSync();
                final formattedDate = DateFormat(
                  'd MMM yyyy, HH:mm',
                  'id_ID',
                ).format(lastModified);
                final formattedSize = _formatBytes(fileSize, 2);

                return ListTile(
                  tileColor: isSelected
                      ? theme.primaryColor.withOpacity(0.2)
                      : null,
                  onTap: () {
                    if (provider.isSelectionMode) {
                      provider.toggleFileSelection(file);
                    }
                  },
                  onLongPress: () {
                    if (!provider.isSelectionMode) {
                      provider.toggleFileSelection(file);
                    }
                  },
                  dense: true,
                  leading: isSelected
                      ? Icon(Icons.check_circle, color: theme.primaryColor)
                      : const Icon(Icons.archive_outlined),
                  title: Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      children: [
                        TextSpan(
                          text: formattedDate,
                          style: TextStyle(color: Colors.blueGrey.shade700),
                        ),
                        const TextSpan(text: ' - '),
                        TextSpan(
                          text: formattedSize,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(left: 4),
                  trailing: provider.isSelectionMode
                      ? null
                      : PopupMenuButton<String>(
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
                              _deleteSelectedFiles(context);
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
