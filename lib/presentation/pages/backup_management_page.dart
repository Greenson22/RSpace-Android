import 'dart:io'; // <-- IMPORT YANG DITAMBAHKAN
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  Future<void> _selectBackupFolder(BuildContext context) async {
    final provider = Provider.of<BackupProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Backup',
    );

    if (selectedDirectory != null) {
      await provider.setBackupPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Folder backup berhasil diubah. Restart aplikasi jika diperlukan.',
        );
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackupProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manajemen Backup')),
        body: Consumer<BackupProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildPathInfoCard(context, provider.backupPath),
                Expanded(child: _buildBackupList(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPathInfoCard(BuildContext context, String? backupPath) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folder Backup Aktif',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              backupPath ?? 'Folder belum ditentukan.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Ubah Folder'),
                onPressed: () => _selectBackupFolder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupList(BackupProvider provider) {
    if (provider.backupPath == null || provider.backupPath!.isEmpty) {
      return const Center(
        child: Text('Tentukan folder backup untuk melihat file.'),
      );
    }

    if (provider.backupFiles.isEmpty) {
      return const Center(
        child: Text('Tidak ada file backup (.zip) ditemukan di folder ini.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: provider.backupFiles.length,
      itemBuilder: (context, index) {
        final file = provider.backupFiles[index];
        // Kode ini sekarang akan berfungsi dengan benar
        final fileName = file.path.split(Platform.pathSeparator).last;
        final lastModified = file.lastModifiedSync();
        final formattedDate = DateFormat(
          'd MMMM yyyy, HH:mm',
          'id_ID',
        ).format(lastModified);

        return Card(
          child: ListTile(
            leading: const Icon(Icons.archive_outlined, size: 40),
            title: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Tanggal: $formattedDate'),
          ),
        );
      },
    );
  }
}
