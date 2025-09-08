// lib/presentation/pages/orphaned_files_page.dart

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/providers/orphaned_file_provider.dart';

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

// ==> UBAH MENJADI STATEFUL WIDGET <==
class _OrphanedFilesView extends StatefulWidget {
  const _OrphanedFilesView();

  @override
  State<_OrphanedFilesView> createState() => _OrphanedFilesViewState();
}

class _OrphanedFilesViewState extends State<_OrphanedFilesView> {
  // ==> TAMBAHKAN CONTROLLER UNTUK SEARCH BAR <==
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ==> TAMBAHKAN LISTENER UNTUK MENTRIGGER FUNGSI SEARCH DI PROVIDER <==
    _searchController.addListener(() {
      Provider.of<OrphanedFileProvider>(
        context,
        listen: false,
      ).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      // ==> GANTI BODY DENGAN COLUMN UNTUK MENAMBAHKAN SEARCH BAR <==
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan judul atau path...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _searchController.text.isEmpty
                              ? '🎉 Hebat! Tidak ada file HTML yatim yang ditemukan.'
                              : 'File tidak ditemukan untuk kueri "${_searchController.text}".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
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
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
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
          ),
        ],
      ),
    );
  }
}
