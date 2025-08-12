import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '2_subjects_page.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';
import '1_topics_page/widgets/topic_list_tile.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftarkan TopicProvider di sini
    return ChangeNotifierProvider(
      create: (_) => TopicProvider(),
      child: const _TopicsPageContent(),
    );
  }
}

class _TopicsPageContent extends StatefulWidget {
  const _TopicsPageContent();

  @override
  State<_TopicsPageContent> createState() => _TopicsPageContentState();
}

class _TopicsPageContentState extends State<_TopicsPageContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<TopicProvider>(
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

  // Aksi-aksi sekarang memanggil provider
  Future<void> _addTopic(BuildContext context) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showTopicTextInputDialog(
      context: context,
      title: 'Tambah Topik Baru',
      label: 'Nama Topik',
      onSave: (name) async {
        try {
          await provider.addTopic(name);
          showAppSnackBar(context, 'Topik "$name" berhasil ditambahkan.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _renameTopic(BuildContext context, String oldName) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: oldName,
      onSave: (newName) async {
        try {
          await provider.renameTopic(oldName, newName);
          showAppSnackBar(context, 'Topik berhasil diubah menjadi "$newName".');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteTopic(BuildContext context, String topicName) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showDeleteTopicConfirmationDialog(
      context: context,
      topicName: topicName,
      onDelete: () async {
        try {
          await provider.deleteTopic(topicName);
          showAppSnackBar(context, 'Topik "$topicName" berhasil dihapus.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _backupContents(BuildContext context) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await provider.backupContents();
      showAppSnackBar(context, message);
    } catch (e) {
      showAppSnackBar(context, 'Terjadi error saat backup: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan instance dari provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari topik...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Topics'),
        actions: [
          // Gunakan Consumer untuk bagian yang perlu update spesifik
          Consumer<TopicProvider>(
            builder: (context, provider, child) {
              return provider.isBackingUp
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.backup),
                      onPressed: () => _backupContents(context),
                      tooltip: 'Backup Seluruh Konten',
                    );
            },
          ),
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () => themeProvider.darkTheme = !themeProvider.darkTheme,
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTopic(context),
        tooltip: 'Tambah Topik',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    return Consumer<TopicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.allTopics.isEmpty) {
          return const Center(
            child: Text('Tidak ada topik. Tekan + untuk menambah.'),
          );
        }

        final topicsToShow = provider.filteredTopics;
        if (topicsToShow.isEmpty && provider.searchQuery.isNotEmpty) {
          return const Center(child: Text('Topik tidak ditemukan.'));
        }

        return ListView.builder(
          itemCount: topicsToShow.length,
          itemBuilder: (context, index) {
            final folderName = topicsToShow[index];
            return TopicListTile(
              topicName: folderName,
              onTap: () {
                final folderPath = path.join(
                  provider.getTopicsPath(),
                  folderName,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => SubjectProvider(folderPath),
                      child: SubjectsPage(topicName: folderName),
                    ),
                  ),
                );
              },
              onRename: () => _renameTopic(context, folderName),
              onDelete: () => _deleteTopic(context, folderName),
            );
          },
        );
      },
    );
  }
}
