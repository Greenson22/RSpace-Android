// lib/features/backup_management/presentation/dialogs/sync_result_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/backup_management/application/sync_provider.dart';

void showSyncResultDialog(BuildContext context, SyncResult result) {
  showDialog(
    context: context,
    builder: (context) => SyncResultDialog(result: result),
  );
}

class SyncResultDialog extends StatelessWidget {
  final SyncResult result;

  const SyncResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.overallSuccess
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: result.overallSuccess ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            result.overallSuccess
                ? 'Sinkronisasi Selesai'
                : 'Terjadi Kesalahan',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikut adalah rincian dari proses Backup & Sync otomatis:',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            _buildStepTile(
              title: 'Backup Data RSpace',
              success: result.rspaceBackupSuccess,
            ),
            _buildStepTile(
              title: 'Unggah Data RSpace',
              success: result.rspaceUploadSuccess,
            ),
            const Divider(height: 24),
            // Bagian 'isPerpuskuSkipped' dihapus
            _buildStepTile(
              title: 'Backup Data PerpusKu',
              success: result.perpuskuBackupSuccess,
            ),
            _buildStepTile(
              title: 'Unggah Data PerpusKu',
              success: result.perpuskuUploadSuccess,
            ),
            if (result.errorMessage != null) ...[
              const Divider(height: 24),
              Text(
                'Pesan Error:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(result.errorMessage!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildStepTile({required String title, required bool success}) {
    return ListTile(
      leading: Icon(
        success ? Icons.check_circle : Icons.cancel,
        color: success ? Colors.green : Colors.red,
      ),
      title: Text(title),
      dense: true,
    );
  }
}
