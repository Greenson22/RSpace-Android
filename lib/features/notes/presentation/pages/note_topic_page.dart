// lib/features/notes/presentation/pages/note_topic_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/notes/application/note_topic_provider.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_list_page.dart';
import 'package:provider/provider.dart';

class NoteTopicPage extends StatelessWidget {
  const NoteTopicPage({super.key});

  void _showAddTopicDialog(BuildContext context) {
    final provider = Provider.of<NoteTopicProvider>(context, listen: false);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Topik Catatan Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Topik'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await provider.addTopic(controller.text);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTopicDialog(BuildContext context, String topicName) {
    final provider = Provider.of<NoteTopicProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Topik?'),
        content: Text(
          'Anda yakin ingin menghapus topik "$topicName" beserta semua catatannya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteTopic(topicName);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteTopicProvider(),
      child: Consumer<NoteTopicProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Topik Catatan')),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.topics.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada topik catatan. Tekan + untuk memulai.',
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.topics.length,
                    itemBuilder: (context, index) {
                      final topic = provider.topics[index];
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(topic),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteListPage(topicName: topic),
                            ),
                          );
                        },
                        onLongPress: () =>
                            _showDeleteTopicDialog(context, topic),
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddTopicDialog(context),
              child: const Icon(Icons.add),
              tooltip: 'Tambah Topik',
            ),
          );
        },
      ),
    );
  }
}
