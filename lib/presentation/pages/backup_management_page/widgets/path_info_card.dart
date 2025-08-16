// lib/presentation/pages/backup_management_page/widgets/path_info_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../utils/backup_actions.dart';

class PathInfoCard extends StatelessWidget {
  const PathInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
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
                // ==> PERUBAHAN DI SINI <==
                final theme = Theme.of(context);
                final String displayText =
                    provider.backupPath ?? 'Folder belum ditentukan.';
                final TextStyle? textStyle = theme.textTheme.bodyMedium
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: kDebugMode && provider.backupPath != null
                          ? FontWeight.bold
                          : null,
                    );

                return Text(displayText, style: textStyle);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Ubah Folder Tujuan'),
                onPressed: () => selectBackupFolder(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
