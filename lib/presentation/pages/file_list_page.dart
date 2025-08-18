// lib/presentation/pages/file_list_page.dart

import 'package:flutter/foundation.dart'; // ==> IMPORT DITAMBAHKAN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // ==> IMPORT DITAMBAHKAN
import '../providers/file_provider.dart';
import '../../data/models/file_model.dart';
import '../pages/1_topics_page/utils/scaffold_messenger_utils.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  // ==> FUNGSI BARU UNTUK MEMILIH FOLDER <==
  Future<void> _selectDownloadFolder(BuildContext context) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Download',
    );

    if (selectedDirectory != null) {
      await provider.setDownloadPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder tujuan download berhasil diatur.');
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar File Online')),
      body: ChangeNotifierProvider(
        create: (_) => FileProvider(),
        child: Consumer<FileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        onPressed: () => provider.fetchFiles(),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchFiles(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ==> WIDGET BARU DITAMBAHKAN DI SINI <==
                  _buildPathInfoCard(context),
                  const SizedBox(height: 24),
                  _buildFileSection(
                    context,
                    provider: provider,
                    title: 'File RSpace',
                    files: provider.rspaceFiles,
                    isRspaceFile: true,
                  ),
                  const SizedBox(height: 24),
                  _buildFileSection(
                    context,
                    provider: provider,
                    title: 'File Perpusku',
                    files: provider.perpuskuFiles,
                    isRspaceFile: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==> WIDGET BARU UNTUK MENAMPILKAN INFO PATH <==
  Widget _buildPathInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folder Tujuan Download',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<FileProvider>(
              builder: (context, provider, child) {
                final theme = Theme.of(context);
                final String displayText =
                    provider.downloadPath ?? 'Folder belum ditentukan.';
                final TextStyle? textStyle = theme.textTheme.bodyMedium
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: kDebugMode && provider.downloadPath != null
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
                onPressed: () => _selectDownloadFolder(context),
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

  Widget _buildFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<FileItem> files,
    required bool isRspaceFile, // ==> PARAMETER BARU
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(thickness: 2),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('Tidak ada file ditemukan.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final progress = provider.getDownloadProgress(file.uniqueName);
              final isDownloading = progress > 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(file.originalName),
                  subtitle: Text('Diunggah: ${file.uploadedAt}'),
                  trailing: isDownloading
                      ? CircularProgressIndicator(
                          value: progress > 0.01 ? progress : null,
                        )
                      : IconButton(
                          icon: const Icon(Icons.download_outlined),
                          tooltip: 'Download File',
                          onPressed: () async {
                            try {
                              // ==> PANGGIL FUNGSI DENGAN PARAMETER BARU <==
                              final message = await provider.downloadFile(
                                file,
                                isRspaceFile,
                              );
                              if (context.mounted) {
                                showAppSnackBar(context, message);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showAppSnackBar(
                                  context,
                                  'Gagal mengunduh: ${e.toString()}',
                                  isError: true,
                                );
                              }
                            }
                          },
                        ),
                ),
              );
            },
          ),
      ],
    );
  }
}
