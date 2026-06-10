// lib/features/perpusku/presentation/pages/perpusku_topic_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/topics/providers/topic_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import 'perpusku_subject_page.dart';

class PerpuskuTopicPage extends StatelessWidget {
  const PerpuskuTopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchTopics(),
      child: const _PerpuskuTopicView(),
    );
  }
}

class _PerpuskuTopicView extends StatefulWidget {
  const _PerpuskuTopicView();

  @override
  State<_PerpuskuTopicView> createState() => _PerpuskuTopicViewState();
}

class _PerpuskuTopicViewState extends State<_PerpuskuTopicView> {
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _themePalettes = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
  ];

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
      ).search(_searchController.text);
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
    final Color defaultThemeColor = _themePalettes[0];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: defaultThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          size: scaledAppBarIconSize,
          color: Colors.white,
        ),
        title: const Text(
          'Perpusku - Topik',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.showHiddenTopics
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            iconSize: scaledAppBarIconSize,
            color: Colors.white,
            onPressed: () => provider.toggleShowHidden(),
            tooltip: provider.showHiddenTopics
                ? 'Sembunyikan Topik Tersembunyi'
                : 'Tampilkan Topik Tersembunyi',
          ),
          const SizedBox(width: 12.0),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16.0),
              decoration: InputDecoration(
                labelText: 'Cari di semua file Perpusku...',
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
                : _buildTopicList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList(BuildContext context, PerpuskuProvider provider) {
    if (provider.topics.isEmpty) {
      return Center(
        child: Text(
          provider.showHiddenTopics
              ? 'Tidak ada topik ditemukan di Perpusku.'
              : 'Tidak ada topik yang terlihat.\nCoba aktifkan "Tampilkan Topik Tersembunyi".',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      itemCount: provider.topics.length,
      itemBuilder: (context, index) {
        final topic = provider.topics[index];
        final Color mainThemeColor = _getThemeColorFromTitle(topic.name);

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
                  builder: (_) => PerpuskuSubjectPage(topic: topic),
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
                      topic.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mainThemeColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ==> TAMBAHKAN POPUP MENU BUTTON DI SINI
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
                          _showRenameTopicDialog(context, provider, topic.name);
                        } else if (value == 'delete') {
                          _showDeleteTopicDialog(context, provider, topic.name);
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
                                'Ubah Nama Topik',
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

  // ==> FUNGSI UTK DIALOG EDIT TOPIK (TANPA ICON) - TERBARU & FIX DIALOG STUCK
  void _showRenameTopicDialog(
    BuildContext context,
    PerpuskuProvider provider,
    String oldName,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Topik'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Baru Topik'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                // Tutup dialog terlebih dahulu agar UI tidak stuck
                Navigator.pop(ctx);

                try {
                  await provider.renameTopic(oldName, newName);
                  if (context.mounted) {
                    Provider.of<TopicProvider>(
                      context,
                      listen: false,
                    ).fetchTopics();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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

  // ==> FUNGSI UTK DIALOG HAPUS TOPIK - FIX DIALOG STUCK & REFRESH UTAMA
  void _showDeleteTopicDialog(
    BuildContext context,
    PerpuskuProvider provider,
    String topicName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topik'),
        content: Text(
          'Apakah Anda yakin ingin menghapus topik "$topicName" beserta seluruh isinya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // 1. Tutup dialog terlebih dahulu agar tidak stuck di layar
              Navigator.pop(ctx);

              try {
                // 2. Jalankan proses hapus data
                await provider.deleteTopic(
                  topicName,
                  deletePerpuskuFolder: true,
                );

                // 3. Picu refresh pada TopicProvider utama (RSpace)
                if (context.mounted) {
                  Provider.of<TopicProvider>(
                    context,
                    listen: false,
                  ).fetchTopics();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
