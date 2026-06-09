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

  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return Colors.deepPurple;
    final List<Color> themePalettes = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade900,
      Colors.green.shade700,
      Colors.cyan.shade800,
      Colors.orange.shade800,
    ];
    final int hash = title.hashCode;
    final int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }

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
    } else {
      // Menangani logika pencarian lokal jika diperlukan
    }
  }

  @override
  Widget build(BuildContext context) {
    _provider = Provider.of<PerpuskuProvider>(context);
    final files = _searchController.text.isEmpty
        ? _provider.files
        : _provider.searchResults;
    final isLoading = _provider.isLoading;

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseAppBarIconSize = 18.0;
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;
    final Color subjectThemeColor = _getThemeColorFromTitle(
      widget.subject.name,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: subjectThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          size: scaledAppBarIconSize,
          color: Colors.white,
        ),
        title: Text(
          widget.subject.name,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16.0),
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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: subjectThemeColor.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.html,
                            color: Colors.orange,
                            size: 20,
                          ),
                          title: Text(
                            file.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subjectThemeColor,
                            ),
                          ),
                          subtitle: Text(
                            file.fileName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () async {
                            try {
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
