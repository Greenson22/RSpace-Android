// lib/features/perpusku/presentation/pages/perpusku_file_list_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import 'package:my_aplication/features/webview_page/presentation/pages/webview_page.dart';
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
  List<PerpuskuFile> _filteredFiles = [];
  // ==> TAMBAHKAN VARIABEL UNTUK MENYIMPAN INSTANCE PROVIDER
  late PerpuskuProvider _provider;

  @override
  void initState() {
    super.initState();
    // ==> INISIALISASI PROVIDER DI SINI
    _provider = Provider.of<PerpuskuProvider>(context, listen: false);
    _provider.addListener(_filterList);
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _provider.files;
      } else {
        _filteredFiles = _provider.files
            .where(
              (f) =>
                  f.title.toLowerCase().contains(query) ||
                  f.fileName.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterList);
    _searchController.dispose();
    // ==> GUNAKAN INSTANCE PROVIDER YANG SUDAH DISIMPAN
    _provider.removeListener(_filterList);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchController.text.isEmpty) {
        setState(() {
          _filteredFiles = provider.files;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari file di dalam subjek ini...',
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
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                ? const Center(child: Text('Tidak ada file ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = _filteredFiles[index];
                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(file.title),
                        subtitle: Text(file.fileName),
                        onTap: () async {
                          try {
                            if (Platform.isAndroid &&
                                themeProvider.openInAppBrowser) {
                              final fileContent = await File(
                                file.path,
                              ).readAsString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WebViewPage(
                                    title: file.title,
                                    htmlContent: fileContent,
                                  ),
                                ),
                              );
                            } else {
                              final result = await OpenFile.open(file.path);
                              if (result.type != ResultType.done) {
                                throw Exception(result.message);
                              }
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
