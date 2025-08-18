// lib/presentation/pages/file_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/file_provider.dart';
import '../../data/models/file_model.dart';
import '../pages/1_topics_page/utils/scaffold_messenger_utils.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

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
                  _buildFileSection(
                    context,
                    title: 'File RSpace',
                    files: provider.rspaceFiles,
                  ),
                  const SizedBox(height: 24),
                  _buildFileSection(
                    context,
                    title: 'File Perpusku',
                    files: provider.perpuskuFiles,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileSection(
    BuildContext context, {
    required String title,
    required List<FileItem> files,
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
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(file.originalName),
                  subtitle: Text('Diunggah: ${file.uploadedAt}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Download File',
                    onPressed: () async {
                      try {
                        final uri = Uri.parse(file.url);
                        if (await canLaunchUrl(uri)) {
                          // Membuka URL di browser eksternal untuk download
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              'Tidak dapat membuka URL: ${file.url}',
                              isError: true,
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            'Error: ${e.toString()}',
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
