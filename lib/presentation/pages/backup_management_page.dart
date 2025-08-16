// lib/presentation/pages/backup_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import 'backup_management_page/layouts/desktop_layout.dart';
import 'backup_management_page/layouts/mobile_layout.dart';
import 'backup_management_page/utils/backup_dialogs.dart';

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackupProvider(),
      child: Consumer<BackupProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: provider.isSelectionMode
                ? _buildSelectionAppBar(context, provider)
                : AppBar(
                    title: const Text('Manajemen Backup'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.sort),
                        onPressed: () => showSortDialog(context),
                        tooltip: 'Urutkan File',
                      ),
                    ],
                  ),
            body: WillPopScope(
              onWillPop: () async {
                if (provider.isSelectionMode) {
                  provider.clearSelection();
                  return false;
                }
                return true;
              },
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const double breakpoint = 1000.0;
                      if (constraints.maxWidth > breakpoint) {
                        return const DesktopLayout();
                      } else {
                        return const MobileLayout();
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, BackupProvider provider) {
    return AppBar(
      title: Text('${provider.selectedFiles.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () {
            provider.selectAllFiles([
              ...provider.rspaceBackupFiles,
              ...provider.perpuskuBackupFiles,
            ]);
          },
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => deleteSelectedFiles(context, []),
          tooltip: 'Hapus Pilihan',
        ),
      ],
    );
  }
}
