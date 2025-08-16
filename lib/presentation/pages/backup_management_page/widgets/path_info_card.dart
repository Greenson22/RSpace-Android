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
                // DIUBAH: Hapus logika if (kDebugMode) yang menyebabkan path tidak update.
                // Sekarang selalu ambil path dari provider.
                final String displayText =
                    provider.backupPath ?? 'Folder belum ditentukan.';

                // Gaya teks amber tetap dipertahankan untuk mode debug agar mudah dikenali.
                final TextStyle? textStyle =
                    kDebugMode && provider.backupPath != null
                    ? Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.amber)
                    : Theme.of(context).textTheme.bodyMedium;

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
