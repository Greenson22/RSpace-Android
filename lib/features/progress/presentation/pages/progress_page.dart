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
import '../../../settings/application/theme_provider.dart';

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

  // ==> State untuk Multi-select
  bool _isSelectionMode = false;
  final Set<ProgressTopic> _selectedTopics = {};

  void _enterSelectionMode(ProgressTopic initialTopic) {
    setState(() {
      _isSelectionMode = true;
      _isReorderMode = false; // Matikan reorder jika aktif
      _selectedTopics.add(initialTopic);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTopics.clear();
    });
  }

  void _toggleItemSelection(ProgressTopic topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
        if (_selectedTopics.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTransparent =
        themeProvider.backgroundImagePath != null ||
        themeProvider.isUnderwaterTheme;

    // Filter display topics
    final displayTopics =
        (_isReorderMode || provider.showHidden || _isSelectionMode)
        ? provider.topics
        : provider.topics.where((t) => !t.isHidden).toList();

    int _getCrossAxisCount(double screenWidth) {
      if (screenWidth > 1200) return 5;
      if (screenWidth > 900) return 4;
      if (screenWidth > 600) return 3;
      return 2;
    }

    return Scaffold(
      backgroundColor: isTransparent ? Colors.transparent : null,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(context, provider, isTransparent)
          : _buildNormalAppBar(context, provider, isTransparent),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayTopics.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  provider.topics.isNotEmpty
                      ? 'Semua topik disembunyikan.\nTekan ikon mata di atas untuk melihat.'
                      : 'Belum ada topik progress.\nTekan tombol + untuk memulai.',
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
                  itemCount: displayTopics.length,
                  // Drag hanya aktif jika mode reorder aktif DAN bukan mode selection
                  dragEnabled: _isReorderMode && !_isSelectionMode,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderTopics(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final topic = displayTopics[index];
                    return ProgressTopicGridTile(
                      key: ValueKey(topic.topics),
                      topic: topic,

                      // Konfigurasi Selection Mode
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedTopics.contains(topic),
                      onSelect: () => _toggleItemSelection(topic),
                      onLongPress: _isReorderMode
                          ? null
                          : () => _enterSelectionMode(topic),

                      onTap: () {
                        if (!_isReorderMode && !_isSelectionMode) {
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
                      onIconChange: () => _showEditIconDialog(context, topic),
                      onHide: () => provider.toggleTopicVisibility(topic),
                    );
                  },
                );
              },
            ),
      floatingActionButton: (_isReorderMode || _isSelectionMode)
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTopicDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  // AppBar Normal
  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    ProgressProvider provider,
    bool isTransparent,
  ) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isTransparent ? 0 : null,
      title: const Text('Progress Belajar'),
      actions: [
        IconButton(
          icon: Icon(
            provider.showHidden ? Icons.visibility : Icons.visibility_off,
          ),
          tooltip: provider.showHidden
              ? 'Sembunyikan Item Hidden'
              : 'Tampilkan Item Hidden',
          onPressed: () {
            provider.toggleShowHidden();
          },
        ),
        IconButton(
          icon: Icon(_isReorderMode ? Icons.check : Icons.sort),
          onPressed: () {
            setState(() {
              _isReorderMode = !_isReorderMode;
            });
          },
          tooltip: _isReorderMode ? 'Selesai Mengurutkan' : 'Urutkan Topik',
        ),
        // Opsi tambahan di menu titik tiga
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select_multiple') {
              if (provider.topics.isNotEmpty) {
                _enterSelectionMode(provider.topics.first);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_multiple',
              child: ListTile(
                leading: Icon(Icons.checklist),
                title: Text('Pilih Banyak'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // AppBar Selection Mode
  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    ProgressProvider provider,
    bool isTransparent,
  ) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : Colors.grey[800],
      elevation: isTransparent ? 0 : null,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedTopics.length} Dipilih'),
      actions: [
        // Tombol Sembunyikan/Tampilkan Massal
        if (_selectedTopics.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Ubah Visibilitas',
            onPressed: () => _handleBatchVisibility(context, provider),
          ),

        // Tombol Hapus Massal
        if (_selectedTopics.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Terpilih',
            onPressed: () => _handleBatchDelete(context, provider),
          ),
      ],
    );
  }

  // Logic Dialogs
  void _handleBatchVisibility(BuildContext context, ProgressProvider provider) {
    // Tentukan aksi berdasarkan item pertama yang dipilih:
    // Jika ada yang visible, kita tawarkan "Sembunyikan". Jika semua hidden, "Tampilkan".
    final anyVisible = _selectedTopics.any((t) => !t.isHidden);
    final actionLabel = anyVisible ? 'Sembunyikan' : 'Tampilkan';
    final makeHidden = anyVisible;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel ${_selectedTopics.length} Topik?'),
        content: Text(
          'Aksi ini akan mengubah status visibilitas untuk topik yang dipilih.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.toggleVisibilityMultipleTopics(
                _selectedTopics.toList(),
                makeHidden,
              );
              _exitSelectionMode();
              Navigator.pop(context);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _handleBatchDelete(BuildContext context, ProgressProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${_selectedTopics.length} Topik?'),
        content: const Text(
          'Topik yang dihapus beserta isinya tidak dapat dikembalikan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteMultipleTopics(_selectedTopics.toList());
              _exitSelectionMode();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

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
