// lib/presentation/pages/orphaned_files_page.dart

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../providers/orphaned_file_provider.dart';
import '../../data/models/orphaned_file_model.dart'; // Import OrphanedFile

class OrphanedFilesPage extends StatelessWidget {
  const OrphanedFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrphanedFileProvider(),
      child: const _OrphanedFilesView(),
    );
  }
}

class _OrphanedFilesView extends StatelessWidget {
  const _OrphanedFilesView();

  Future<void> _confirmAndDelete(
    BuildContext context,
    OrphanedFileProvider provider,
    int index,
  ) async {
    final file = provider.orphanedFiles[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus file "${file.title}" secara permanen? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteFile(file);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${file.title}" berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrphanedFileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Yatim PerpusKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchOrphanedFiles(),
            tooltip: 'Pindai Ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchOrphanedFiles(),
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (provider.orphanedFiles.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🎉 Hebat! Tidak ada file HTML yatim yang ditemukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: provider.orphanedFiles.length,
              itemBuilder: (context, index) {
                final item = provider.orphanedFiles[index];
                return ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: Colors.grey,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.relativePath),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _confirmAndDelete(context, provider, index),
                    tooltip: 'Hapus File',
                  ),
                  onTap: () {
                    OpenFile.open(item.fileObject.path);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
