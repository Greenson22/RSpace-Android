// lib/presentation/pages/file_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../../data/models/file_model.dart';

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
                  child: Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
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
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file.name),
                  subtitle: Text(
                    'Ukuran: ${file.size} bytes - Tanggal: ${file.date}',
                  ),
                  onTap: () {
                    // Aksi saat item di-tap, misalnya membuka URL
                    // import 'package:url_launcher/url_launcher.dart';
                    // launchUrl(Uri.parse(file.url));
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
