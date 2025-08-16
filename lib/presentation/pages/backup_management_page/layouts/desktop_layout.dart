// lib/presentation/pages/backup_management_page/layouts/desktop_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../widgets/backup_section.dart';
import '../widgets/path_info_card.dart';
import '../widgets/perpusku_path_card.dart';
import '../utils/backup_actions.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!provider.isSelectionMode)
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
                const PathInfoCard(),
                const SizedBox(height: 16),
                const PerpuskuPathCard(),
              ],
            ),
          ),
        if (!provider.isSelectionMode) const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              BackupSection(
                title: 'Backup RSpace',
                files: provider.rspaceBackupFiles,
                onBackup: () => backupContents(context, 'RSpace'),
                onImport: () => importContents(context, 'RSpace'),
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
              BackupSection(
                title: 'Backup PerpusKu',
                files: provider.perpuskuBackupFiles,
                onBackup: () => backupContents(context, 'PerpusKu'),
                onImport: () => importContents(context, 'PerpusKu'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
