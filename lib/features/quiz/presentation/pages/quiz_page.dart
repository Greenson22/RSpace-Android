// lib/features/quiz/presentation/pages/quiz_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../application/quiz_provider.dart';
import '../../domain/models/quiz_model.dart';
import '../widgets/quiz_topic_grid_tile.dart';
import 'quiz_detail_page.dart';
import '../../application/quiz_detail_provider.dart';
import 'quiz_player_page.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView();

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizProvider>(context);

    int getCrossAxisCount(double screenWidth) {
      if (screenWidth > 1200) return 5;
      if (screenWidth > 900) return 4;
      if (screenWidth > 600) return 3;
      return 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topik Kuis'),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.check : Icons.sort),
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
            tooltip: _isReorderMode ? 'Selesai Mengurutkan' : 'Urutkan Topik',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.topics.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada topik kuis.\nTekan tombol + untuk memulai.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ReorderableGridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: provider.topics.length,
                  dragEnabled: _isReorderMode,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderTopics(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final topic = provider.topics[index];
                    return QuizTopicGridTile(
                      key: ValueKey(topic.name),
                      topic: topic,
                      onPlay: () {
                        if (!_isReorderMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Mengirim seluruh objek topic ke QuizPlayerPage
                              builder: (_) => QuizPlayerPage(topic: topic),
                            ),
                          );
                        }
                      },
                      onManage: () {
                        if (!_isReorderMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => QuizDetailProvider(topic),
                                child: const QuizDetailPage(),
                              ),
                            ),
                          ).then((_) {
                            provider.fetchTopics();
                          });
                        }
                      },
                      onEdit: () => _showEditTopicDialog(context, topic),
                      onDelete: () => _showDeleteConfirmDialog(context, topic),
                      onIconChange: () => _showEditIconDialog(context, topic),
                    );
                  },
                );
              },
            ),
      floatingActionButton: _isReorderMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTopicDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddTopicDialog(BuildContext context) {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Topik Kuis Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Topik Kuis'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addTopic(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditTopicDialog(BuildContext context, QuizTopic topic) {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    final controller = TextEditingController(text: topic.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Topik Kuis'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.editTopic(topic, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, QuizTopic topic) {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus topik kuis "${topic.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteTopic(topic);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditIconDialog(BuildContext context, QuizTopic topic) {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    showIconPickerDialog(
      context: context,
      name: topic.name,
      onIconSelected: (newIcon) {
        provider.editTopicIcon(topic, newIcon);
      },
    );
  }
}
