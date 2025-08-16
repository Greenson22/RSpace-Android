// lib/presentation/pages/backup_management_page/widgets/perpusku_path_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../utils/backup_actions.dart';

class PerpuskuPathCard extends StatelessWidget {
  const PerpuskuPathCard({super.key});

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
            Consumer<BackupProvider>(
              builder: (context, provider, child) => Text(
                provider.perpuskuDataPath ?? 'Menggunakan folder default.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Ubah Folder Sumber Data'),
                onPressed: () => selectPerpuskuDataFolder(context),
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
