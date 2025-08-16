// lib/presentation/pages/backup_management_page/widgets/path_info_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../utils/backup_actions.dart';

class PathInfoCard extends StatelessWidget {
  const PathInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context, listen: false);

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
              builder: (context, provider, child) => Text(
                provider.backupPath ?? 'Folder belum ditentukan.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
