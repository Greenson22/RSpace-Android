// lib/features/perpusku/presentation/pages/perpusku_file_list_page.dart

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';

class PerpuskuFileListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const PerpuskuFileListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchFiles(subject.path),
      child: _PerpuskuFileListView(subject: subject),
    );
  }
}

class _PerpuskuFileListView extends StatefulWidget {
  final PerpuskuSubject subject;
  const _PerpuskuFileListView({required this.subject});

  @override
  State<_PerpuskuFileListView> createState() => __PerpuskuFileListViewState();
}

class __PerpuskuFileListViewState extends State<_PerpuskuFileListView> {
  final TextEditingController _searchController = TextEditingController();
  late PerpuskuProvider _provider;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {});
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<PerpuskuProvider>(context);
    final files = _searchController.text.isEmpty
        ? _provider.files
        : _provider.searchResults;
    final isLoading = _provider.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari file...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : files.isEmpty
                ? const Center(child: Text('Tidak ada file ditemukan'))
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return ListTile(
                        leading: const Icon(Icons.html, color: Colors.orange),
                        title: Text(file.title),
                        subtitle: Text(file.fileName),
                        onTap: () async {
                          try {
                            // Karena themeProvider dihapus, langsung gunakan open_file sebagai default eksternal.
                            // Jika Anda ingin selalu membuka di dalam aplikasi, silakan ganti ke blok WebViewPage.
                            final result = await OpenFile.open(file.path);
                            if (result.type != ResultType.done) {
                              throw Exception(result.message);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal membuka file: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
