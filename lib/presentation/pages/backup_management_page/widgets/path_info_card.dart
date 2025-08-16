// lib/presentation/pages/backup_management_page/widgets/path_info_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/debug_provider.dart';
import '../utils/backup_actions.dart';

class PathInfoCard extends StatelessWidget {
  const PathInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final debugProvider = Provider.of<DebugProvider>(context);
    final isChangeDisabled = kDebugMode && !debugProvider.allowPathChanges;

    return Card(
      child: Padding(
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
            Consumer<BackupProvider>(
              builder: (context, provider, child) {
                // ==> LOGIKA BARU UNTUK TAMPILAN DEBUG <==
                final String displayText;
                final TextStyle? textStyle;

                if (kDebugMode) {
                  displayText = '/home/lemon-manis-22/TESTING/testing_backup';
                  textStyle = Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.amber);
                } else {
                  displayText =
                      provider.backupPath ?? 'Folder belum ditentukan.';
                  textStyle = Theme.of(context).textTheme.bodyMedium;
                }

                return Text(displayText, style: textStyle);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Ubah Folder Tujuan'),
                onPressed: isChangeDisabled
                    ? null
                    : () => selectBackupFolder(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (isChangeDisabled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Ubah path dinonaktifkan dalam mode debug.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
