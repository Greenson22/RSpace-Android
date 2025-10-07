// lib/features/backup_management/presentation/widgets/backup_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/backup_management/presentation/utils/backup_actions.dart';
import 'package:provider/provider.dart';
import '../../application/backup_provider.dart';
import '../utils/backup_dialogs.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as path;

class BackupSection extends StatelessWidget {
  final String title;
  final List<File> files;
  final VoidCallback onBackup;
  final VoidCallback onImport;
  final bool isCompact;
  final bool isFocused;
  final int focusedIndex;

  const BackupSection({
    super.key,
    required this.title,
    required this.files,
    required this.onBackup,
    required this.onImport,
    this.isCompact = false,
    this.isFocused = false,
    this.focusedIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);
    final isActionInProgress =
        provider.isBackingUp || provider.isImporting || provider.isUploading;
    final theme = Theme.of(context);

    final isPerpuskuBackup = title.contains('PerpusKu');

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
                        ? _loadingIndicator()
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
                        ? _loadingIndicatorOutline(theme)
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
                final bool isCurrentlyFocused =
                    isFocused && index == focusedIndex;
                return _buildFileListItem(
                  context,
                  file,
                  provider,
                  isCurrentlyFocused,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(
    BuildContext context,
    File file,
    BackupProvider provider,
    bool isCurrentlyFocused,
  ) {
    final isSelected = provider.selectedFiles.contains(file.path);
    final theme = Theme.of(context);
    final fileName = file.path.split(Platform.pathSeparator).last;
    final lastModified = file.lastModifiedSync();
    final fileSize = file.lengthSync();
    final formattedDate = DateFormat(
      'd MMM yyyy, HH:mm',
      'id_ID',
    ).format(lastModified);
    final formattedSize = formatBytes(fileSize, 2);
    final uploadProgress = provider.getUploadProgress(path.basename(file.path));
    final isUploading = uploadProgress > 0;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.2)
            : (isCurrentlyFocused ? theme.primaryColor.withOpacity(0.1) : null),
        border: isCurrentlyFocused
            ? Border.all(color: theme.primaryColor, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        onTap: () {
          provider.toggleFileSelection(file);
        },
        onLongPress: () {
          provider.toggleFileSelection(file);
        },
        dense: true,
        leading: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : const Icon(Icons.archive_outlined),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
        contentPadding: const EdgeInsets.only(left: 8, right: 4),
        trailing: provider.isSelectionMode
            ? null
            : isUploading
            ? CircularProgressIndicator(
                value: uploadProgress > 0.01 ? uploadProgress : null,
              )
            : _buildFileActionMenu(context, file),
      ),
    );
  }

  Widget _buildFileActionMenu(BuildContext context, File file) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        final backupType = title.contains('RSpace') ? 'RSpace' : 'PerpusKu';
        if (value == 'import') {
          // ==> PERBAIKAN DI SINI: Tambahkan parameter showConfirmation <==
          importSpecificFile(context, file, backupType, showConfirmation: true);
        } else if (value == 'upload') {
          uploadBackupFile(context, file, backupType);
        } else if (value == 'share') {
          shareFile(context, file);
        } else if (value == 'delete') {
          deleteSelectedFiles(context, [file]);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'import',
          child: ListTile(leading: Icon(Icons.restore), title: Text('Import')),
        ),
        const PopupMenuItem<String>(
          value: 'upload',
          child: ListTile(
            leading: Icon(Icons.cloud_upload_outlined),
            title: Text('Unggah'),
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
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }

  Widget _loadingIndicatorOutline(ThemeData theme) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.primaryColor,
      ),
    );
  }
}
