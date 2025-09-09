// lib/features/progress/presentation/pages/progress_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../application/progress_provider.dart';
import '../../domain/models/progress_topic_model.dart';
import 'progress_detail_page.dart';
import '../../application/progress_detail_provider.dart';
import '../widgets/progress_topic_grid_tile.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProgressProvider(),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatefulWidget {
  const _ProgressView();

  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressProvider>(context);

    int _getCrossAxisCount(double screenWidth) {
      if (screenWidth > 1200) return 5;
      if (screenWidth > 900) return 4;
      if (screenWidth > 600) return 3;
      return 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Belajar'),
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
                  'Belum ada topik progress.\nTekan tombol + untuk memulai.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ReorderableGridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
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
                    return ProgressTopicGridTile(
                      key: ValueKey(topic.topics),
                      topic: topic,
                      onTap: () {
                        if (!_isReorderMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => ProgressDetailProvider(topic),
                                child: ProgressDetailPage(),
                              ),
                            ),
                          ).then((_) {
                            provider.fetchTopics();
                          });
                        }
                      },
                      onEdit: () => _showEditTopicDialog(context, topic),
                      onDelete: () => _showDeleteConfirmDialog(context, topic),
                      // Hubungkan callback baru
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

  // ... (Fungsi _showAddTopicDialog, _showEditTopicDialog, _showDeleteConfirmDialog tidak berubah) ...
  void _showAddTopicDialog(BuildContext context) {
    final provider = Provider.of<ProgressProvider>(context, listen: false);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Topik Progress Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Topik'),
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

  void _showEditTopicDialog(BuildContext context, ProgressTopic topic) {
    final provider = Provider.of<ProgressProvider>(context, listen: false);
    final controller = TextEditingController(text: topic.topics);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Topik'),
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

  void _showDeleteConfirmDialog(BuildContext context, ProgressTopic topic) {
    final provider = Provider.of<ProgressProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus topik "${topic.topics}" beserta semua isinya?',
        ),
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

  // Fungsi baru untuk memanggil dialog ikon
  void _showEditIconDialog(BuildContext context, ProgressTopic topic) {
    final provider = Provider.of<ProgressProvider>(context, listen: false);
    showIconPickerDialog(
      context: context,
      name: topic.topics,
      onIconSelected: (newIcon) {
        provider.editTopicIcon(topic, newIcon);
      },
    );
  }
}
