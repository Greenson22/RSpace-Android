// lib/features/file_management/presentation/layouts/mobile_layout.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/backup_management/presentation/utils/backup_actions.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../application/file_provider.dart';
import '../../domain/models/file_model.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../backup_management/presentation/utils/file_utils.dart';
import '../pages/file_list_page.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FileProvider>(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ApiConfigCard(),
        const SizedBox(height: 16),
        _buildFileSection(
          context,
          provider: provider,
          title: 'File Online RSpace',
          files: provider.rspaceFiles,
          isRspaceFile: true,
        ),
        const SizedBox(height: 24),
        _buildFileSection(
          context,
          provider: provider,
          title: 'File Online Perpusku',
          files: provider.perpuskuFiles,
          isRspaceFile: false,
        ),
        const SizedBox(height: 24),
        _buildDownloadedFileSection(
          context,
          provider: provider,
          title: 'Unduhan RSpace',
          files: provider.downloadedRspaceFiles,
          isRspaceFile: true,
        ),
        const SizedBox(height: 24),
        _buildDownloadedFileSection(
          context,
          provider: provider,
          title: 'Unduhan Perpusku',
          files: provider.downloadedPerpuskuFiles,
          isRspaceFile: false,
        ),
      ],
    );
  }

  Future<void> _uploadFile(BuildContext context, bool isRspaceFile) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final file = result.files.first;
        if (context.mounted) {
          showAppSnackBar(context, 'Mengunggah ${file.name}...');
        }
        final message = await provider.uploadFile(file, isRspaceFile);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal mengunggah: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteFile(
    BuildContext context,
    FileItem file,
    bool isRspaceFile,
  ) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      final confirmed = await _showConfirmationDialog(
        context,
        'Konfirmasi Hapus',
        'Anda yakin ingin menghapus file "${file.originalName}" dari server?',
      );
      if (confirmed) {
        final message = await provider.deleteFile(file, isRspaceFile);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal menghapus: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteDownloadedFile(BuildContext context, File file) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      final confirmed = await _showConfirmationDialog(
        context,
        'Konfirmasi Hapus Lokal',
        'Anda yakin ingin menghapus file "${path.basename(file.path)}" dari perangkat Anda?',
      );
      if (confirmed) {
        final message = await provider.deleteDownloadedFile(file);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal menghapus file lokal: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<FileItem> files,
    required bool isRspaceFile,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Unggah'),
              onPressed: provider.isUploading
                  ? null
                  : () => _uploadFile(context, isRspaceFile),
            ),
          ],
        ),
        const Divider(thickness: 2),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('Tidak ada file online ditemukan.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildFileListItem(context, file, isRspaceFile);
            },
          ),
      ],
    );
  }

  Widget _buildDownloadedFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<File> files,
    required bool isRspaceFile,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(thickness: 2),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('Tidak ada file yang telah diunduh.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildDownloadedFileListItem(context, file, isRspaceFile);
            },
          ),
      ],
    );
  }

  Widget _buildFileListItem(
    BuildContext context,
    FileItem file,
    bool isRspaceFile,
  ) {
    final provider = Provider.of<FileProvider>(context);
    final progress = provider.getDownloadProgress(file.uniqueName);
    final isDownloading = progress > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.cloud_queue_rounded),
        title: Text(file.originalName),
        subtitle: Text('Diunggah: ${file.uploadedAt}'),
        trailing: isDownloading
            ? CircularProgressIndicator(
                value: progress > 0.01 ? progress : null,
              )
            : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'download') {
                    try {
                      await provider.downloadFile(file, isRspaceFile);
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          'Mengunduh ${file.originalName}...',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          'Gagal mengunduh: $e',
                          isError: true,
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    _deleteFile(context, file, isRspaceFile);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Download'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDownloadedFileListItem(
    BuildContext context,
    File file,
    bool isRspaceFile,
  ) {
    final provider = Provider.of<FileProvider>(context);
    final isSelected = provider.selectedDownloadedFiles.contains(file.path);
    final theme = Theme.of(context);
    final fileName = path.basename(file.path);
    final fileSize = file.lengthSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isSelected ? theme.primaryColor.withOpacity(0.2) : null,
      child: ListTile(
        onTap: () {
          if (provider.isSelectionMode) {
            provider.toggleDownloadedFileSelection(file);
          } else {
            OpenFile.open(file.path);
          }
        },
        onLongPress: () {
          provider.toggleDownloadedFileSelection(file);
        },
        leading: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : const Icon(Icons.drafts_rounded),
        title: Text(fileName),
        subtitle: Text('Ukuran: ${formatBytes(fileSize, 2)}'),
        trailing: provider.isSelectionMode
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'open') {
                    await OpenFile.open(file.path);
                  } else if (value == 'import') {
                    final backupType = isRspaceFile ? 'RSpace' : 'PerpusKu';
                    // ==> PERBAIKAN DI SINI: Tambahkan parameter showConfirmation <==
                    importSpecificFile(
                      context,
                      file,
                      backupType,
                      showConfirmation: true,
                    );
                  } else if (value == 'delete') {
                    _deleteDownloadedFile(context, file);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'open', child: Text('Buka File')),
                  const PopupMenuItem(value: 'import', child: Text('Import')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }
}
