// lib/features/perpusku/presentation/pages/perpusku_subject_page.dart
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';
import 'perpusku_file_list_page.dart';

class PerpuskuSubjectPage extends StatelessWidget {
  final PerpuskuTopic topic;
  const PerpuskuSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchSubjects(topic.path),
      child: _PerpuskuSubjectView(topic: topic),
    );
  }
}

class _PerpuskuSubjectView extends StatefulWidget {
  final PerpuskuTopic topic;
  const _PerpuskuSubjectView({required this.topic});

  @override
  State<_PerpuskuSubjectView> createState() => _PerpuskuSubjectViewState();
}

class _PerpuskuSubjectViewState extends State<_PerpuskuSubjectView> {
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.addListener(() {
      Provider.of<PerpuskuProvider>(
        context,
        listen: false,
      ).searchInTopic(widget.topic.path, _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseAppBarIconSize = 18.0;
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;
    final Color topicThemeColor = _getThemeColorFromTitle(widget.topic.name);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: topicThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          size: scaledAppBarIconSize,
          color: Colors.white,
        ),
        title: Text(
          widget.topic.name,
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
                labelText: 'Cari file di dalam topik ini...',
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
                : provider.isSearching
                ? _buildSearchResults(context, provider)
                : _buildSubjectList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(BuildContext context, PerpuskuProvider provider) {
    if (provider.subjects.isEmpty) {
      return const Center(child: Text('Tidak ada subjek di dalam topik ini.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      itemCount: provider.subjects.length,
      itemBuilder: (context, index) {
        final subject = provider.subjects[index];
        final Color mainThemeColor = _getThemeColorFromTitle(subject.name);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: mainThemeColor.withOpacity(0.35),
              width: 1.0,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerpuskuFileListPage(subject: subject),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            splashColor: mainThemeColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: mainThemeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mainThemeColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ==> TAMBAHKAN POPUP MENU BUTTON UNTUK SUBJEK DI SINI
                  Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(
                        color: mainThemeColor.withOpacity(0.7),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showRenameSubjectDialog(
                            context,
                            provider,
                            subject.name,
                          );
                        } else if (value == 'delete') {
                          _showDeleteSubjectDialog(
                            context,
                            provider,
                            subject.name,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Ubah Nama Subjek',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==> FUNGSI UTK DIALOG EDIT SUBJEK
  void _showRenameSubjectDialog(
    BuildContext context,
    PerpuskuProvider provider,
    String oldName,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Subjek'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Baru Subjek'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                try {
                  await provider.renameSubject(
                    widget.topic.name,
                    oldName,
                    controller.text,
                    widget.topic.path,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==> FUNGSI UTK DIALOG HAPUS SUBJEK
  void _showDeleteSubjectDialog(
    BuildContext context,
    PerpuskuProvider provider,
    String subjectName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Subjek'),
        content: Text(
          'Apakah Anda yakin ingin menghapus subjek "$subjectName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteSubject(subjectName, widget.topic.path);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, PerpuskuProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(child: Text('File tidak ditemukan.'));
    }
    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final file = provider.searchResults[index];
        return ListTile(
          leading: const Icon(Icons.description_outlined, size: 20),
          title: Text(
            file.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(file.path, style: const TextStyle(fontSize: 12)),
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
        );
      },
    );
  }
}
