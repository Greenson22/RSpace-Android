// lib/features/file_management/presentation/dialogs/download_import_progress_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/file_provider.dart';

// Fungsi untuk menampilkan dialog
void showDownloadImportProgressDialog(BuildContext context) {
  final provider = Provider.of<FileProvider>(context, listen: false);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ChangeNotifierProvider.value(
        value: provider,
        child: const DownloadImportProgressDialog(),
      );
    },
  );
}

// Widget utama dialog
class DownloadImportProgressDialog extends StatelessWidget {
  const DownloadImportProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        final progress = provider.syncProgress;
        final bool isFinished = progress.isFinished;

        return AlertDialog(
          title: Text(isFinished ? 'Proses Selesai' : 'Download & Import...'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFinished)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Harap jangan tutup aplikasi hingga proses selesai.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                _buildStepTile(
                  'Mengunduh data RSpace',
                  progress.rspaceDownloadStatus,
                ),
                _buildStepTile(
                  'Mengimpor data RSpace',
                  progress.rspaceImportStatus,
                ),
                const Divider(height: 24),
                _buildStepTile(
                  'Mengunduh data PerpusKu',
                  progress.perpuskuDownloadStatus,
                ),
                _buildStepTile(
                  'Mengimpor data PerpusKu',
                  progress.perpuskuImportStatus,
                ),
                if (progress.errorMessage != null) ...[
                  const Divider(height: 24),
                  Text(
                    'Pesan Error:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isFinished ? () => Navigator.of(context).pop() : null,
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Widget helper untuk menampilkan setiap langkah
  Widget _buildStepTile(String title, SyncStepStatus status) {
    // ==> PERBAIKAN DI SINI: Tipe data diubah dari 'Icon' menjadi 'Widget' <==
    Widget icon;
    switch (status) {
      case SyncStepStatus.waiting:
        icon = const Icon(Icons.hourglass_empty, color: Colors.grey);
        break;
      case SyncStepStatus.inProgress:
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        break;
      case SyncStepStatus.success:
        icon = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case SyncStepStatus.failed:
        icon = const Icon(Icons.cancel, color: Colors.red);
        break;
    }
    return ListTile(leading: icon, title: Text(title), dense: true);
  }
}
