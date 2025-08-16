// lib/presentation/pages/backup_management_page/layouts/mobile_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../widgets/backup_section.dart';
import '../widgets/path_info_card.dart';
import '../widgets/perpusku_path_card.dart';
import '../utils/backup_actions.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (!provider.isSelectionMode) ...[
          const PathInfoCard(),
          const SizedBox(height: 8),
          const PerpuskuPathCard(),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BackupSection(
                title: 'RSpace',
                files: provider.rspaceBackupFiles,
                onBackup: () => backupContents(context, 'RSpace'),
                onImport: () => importContents(context, 'RSpace'),
                isCompact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BackupSection(
                title: 'PerpusKu',
                files: provider.perpuskuBackupFiles,
                onBackup: () => backupContents(context, 'PerpusKu'),
                onImport: () => importContents(context, 'PerpusKu'),
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
