// lib/features/notes/presentation/pages/note_topic_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/topics/dialogs/topic_dialogs.dart';
import 'package:my_aplication/features/notes/application/note_topic_provider.dart';
import 'package:my_aplication/features/notes/domain/models/note_topic_model.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_list_page.dart';
import 'package:my_aplication/features/notes/presentation/widgets/note_topic_grid_tile.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
// Import ThemeProvider
import 'package:my_aplication/features/settings/application/theme_provider.dart';

class NoteTopicPage extends StatelessWidget {
  const NoteTopicPage({super.key});

  void _showAddTopicDialog(BuildContext context) {
    final provider = Provider.of<NoteTopicProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Buat Topik Catatan Baru',
      label: 'Nama Topik',
      onSave: (name) async {
        try {
          await provider.addTopic(name);
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
    );
  }

  void _showEditTopicDialog(BuildContext context, NoteTopic topic) {
    final provider = Provider.of<NoteTopicProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: topic.name,
      onSave: (newName) async {
        try {
          await provider.renameTopic(topic.name, newName);
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
    );
  }

  void _showEditIconDialog(BuildContext context, NoteTopic topic) {
    final provider = Provider.of<NoteTopicProvider>(context, listen: false);
    showIconPickerDialog(
      context: context,
      name: topic.name,
      onIconSelected: (newIcon) {
        provider.updateTopicIcon(topic, newIcon);
      },
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
          // Akses ThemeProvider
          final themeProvider = Provider.of<ThemeProvider>(context);
          final isTransparent =
              themeProvider.backgroundImagePath != null ||
              themeProvider.isUnderwaterTheme;

          int getCrossAxisCount(double screenWidth) {
            if (screenWidth > 1200) return 5;
            if (screenWidth > 900) return 4;
            if (screenWidth > 600) return 3;
            return 2;
          }

          return Scaffold(
            // Terapkan transparansi Scaffold
            backgroundColor: isTransparent ? Colors.transparent : null,
            appBar: AppBar(
              // Terapkan transparansi AppBar
              backgroundColor: isTransparent ? Colors.transparent : null,
              elevation: isTransparent ? 0 : null,
              title: const Text('Topik Catatan'),
              actions: [
                IconButton(
                  icon: Icon(
                    provider.isReorderModeEnabled ? Icons.check : Icons.sort,
                  ),
                  onPressed: () => provider.toggleReorderMode(),
                  tooltip: provider.isReorderModeEnabled
                      ? 'Selesai Mengurutkan'
                      : 'Urutkan Topik',
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.topics.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada topik catatan. Tekan + untuk memulai.',
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return ReorderableGridView.builder(
                        dragEnabled: provider.isReorderModeEnabled,
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getCrossAxisCount(
                            constraints.maxWidth,
                          ),
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: provider.topics.length,
                        itemBuilder: (context, index) {
                          final topic = provider.topics[index];
                          return NoteTopicGridTile(
                            key: ValueKey(topic.name),
                            topic: topic,
                            onTap: () {
                              if (!provider.isReorderModeEnabled) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoteListPage(topicName: topic.name),
                                  ),
                                );
                              }
                            },
                            onRename: () =>
                                _showEditTopicDialog(context, topic),
                            onIconChange: () =>
                                _showEditIconDialog(context, topic),
                            onDelete: () =>
                                _showDeleteTopicDialog(context, topic.name),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderTopics(oldIndex, newIndex);
                        },
                      );
                    },
                  ),
            floatingActionButton: provider.isReorderModeEnabled
                ? null
                : FloatingActionButton(
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
