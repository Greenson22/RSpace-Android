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
  bool _isSelectionMode = false;
  final Set<ProgressTopic> _selectedTopics = {};

  void _enterSelectionMode(ProgressTopic initialTopic) {
    setState(() {
      _isSelectionMode = true;
      _isReorderMode = false;
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

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 5;
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTransparent =
        themeProvider.backgroundImagePath != null ||
        themeProvider.isUnderwaterTheme;

    return Scaffold(
      backgroundColor: isTransparent ? Colors.transparent : null,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(context, provider, isTransparent)
          : _buildNormalAppBar(context, provider, isTransparent),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

                if (provider.topics.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Belum ada topik progress.\nTekan tombol + untuk memulai.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Render setiap section secara berurutan
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: provider.sections.map((section) {
                      // Filter topik berdasarkan section & visibility
                      final sectionTopicsRaw = provider.topics
                          .where((t) => t.section == section)
                          .toList();
                      final displayTopics =
                          (_isReorderMode || provider.showHidden)
                          ? sectionTopicsRaw
                          : sectionTopicsRaw.where((t) => !t.isHidden).toList();

                      // Sort ascending by position
                      displayTopics.sort(
                        (a, b) => a.position.compareTo(b.position),
                      );

                      return _buildSectionGrid(
                        context: context,
                        sectionName: section,
                        topics: displayTopics,
                        crossAxisCount: crossAxisCount,
                        provider: provider,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: (_isReorderMode || _isSelectionMode)
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTopicDialog(context, provider),
              child: const Icon(Icons.add),
            ),
    );
  }

  // --- Widget Builder Per Section ---
  Widget _buildSectionGrid({
    required BuildContext context,
    required String sectionName,
    required List<ProgressTopic> topics,
    required int crossAxisCount,
    required ProgressProvider provider,
  }) {
    if (topics.isEmpty && !_isReorderMode && !_isSelectionMode) {
      // Tampilkan judul section yang kosong sebagai petunjuk struktural (bisa disembunyikan jika ingin clean)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(sectionName),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Kosong',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(sectionName),
        if (topics.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Kosong',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          ReorderableGridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.1,
            ),
            itemCount: topics.length,
            dragEnabled: _isReorderMode && !_isSelectionMode,
            onReorder: (oldIndex, newIndex) {
              provider.reorderTopicsInSection(sectionName, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final topic = topics[index];
              return ProgressTopicGridTile(
                key: ValueKey(topic.topics),
                topic: topic,
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
                          child: const ProgressDetailPage(),
                        ),
                      ),
                    ).then((_) {
                      provider.fetchTopics();
                    });
                  }
                },
                onEdit: () => _showEditTopicDialog(context, topic, provider),
                onDuplicate: () {
                  provider.duplicateTopic(topic);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Topik berhasil diduplikat')),
                  );
                },
                onDelete: () =>
                    _showDeleteConfirmDialog(context, topic, provider),
                onIconChange: () =>
                    _showEditIconDialog(context, topic, provider),
                onHide: () => provider.toggleTopicVisibility(topic),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // --- AppBar Normal ---
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
          onPressed: () => provider.toggleShowHidden(),
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
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select_multiple') {
              if (provider.topics.isNotEmpty) {
                _enterSelectionMode(provider.topics.first);
              }
            } else if (value == 'manage_sections') {
              _showManageSectionsDialog(context, provider);
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
            const PopupMenuItem(
              value: 'manage_sections',
              child: ListTile(
                leading: Icon(Icons.category),
                title: Text('Kelola Kategori Bagian'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- AppBar Selection Mode ---
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
        if (_selectedTopics.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            tooltip: 'Pindahkan Bagian (Kategori)',
            onPressed: () => _handleBatchMoveSection(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Ubah Visibilitas',
            onPressed: () => _handleBatchVisibility(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Terpilih',
            onPressed: () => _handleBatchDelete(context, provider),
          ),
        ],
      ],
    );
  }

  // --- Dialogs & Handlers ---

  void _handleBatchMoveSection(
    BuildContext context,
    ProgressProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pindahkan ${_selectedTopics.length} Topik Ke...'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: provider.sections
                .map(
                  (section) => ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(section),
                    onTap: () {
                      provider.moveMultipleTopicsToSection(
                        _selectedTopics.toList(),
                        section,
                      );
                      _exitSelectionMode();
                      Navigator.pop(dialogContext);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _handleBatchVisibility(BuildContext context, ProgressProvider provider) {
    final anyVisible = _selectedTopics.any((t) => !t.isHidden);
    final actionLabel = anyVisible ? 'Sembunyikan' : 'Tampilkan';
    final makeHidden = anyVisible;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel ${_selectedTopics.length} Topik?'),
        content: const Text(
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

  void _showAddTopicDialog(BuildContext context, ProgressProvider provider) {
    final controller = TextEditingController();
    String selectedSection = provider.sections.isNotEmpty
        ? provider.sections.first
        : 'Umum';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Topik Progress Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nama Topik'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Bagian',
                  ),
                  items: provider.sections
                      .map(
                        (sec) => DropdownMenuItem(value: sec, child: Text(sec)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedSection = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    provider.addTopic(
                      controller.text,
                      section: selectedSection,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTopicDialog(
    BuildContext context,
    ProgressTopic topic,
    ProgressProvider provider,
  ) {
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

  void _showDeleteConfirmDialog(
    BuildContext context,
    ProgressTopic topic,
    ProgressProvider provider,
  ) {
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

  void _showEditIconDialog(
    BuildContext context,
    ProgressTopic topic,
    ProgressProvider provider,
  ) {
    showIconPickerDialog(
      context: context,
      name: topic.topics,
      onIconSelected: (newIcon) {
        provider.editTopicIcon(topic, newIcon);
      },
    );
  }

  // --- Manajamen Sections ---
  void _showManageSectionsDialog(
    BuildContext context,
    ProgressProvider mainProvider,
  ) {
    // Tambahkan state lokal di dalam dialog untuk mode reorder
    bool isReordering = false;

    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider<ProgressProvider>.value(
        value: mainProvider,
        child: StatefulBuilder(
          // StatefulBuilder diperlukan untuk mengupdate UI dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kelola Bagian'),
                  IconButton(
                    icon: Icon(isReordering ? Icons.check : Icons.sort),
                    onPressed: () =>
                        setDialogState(() => isReordering = !isReordering),
                    tooltip: isReordering
                        ? 'Selesai Urutkan'
                        : 'Urutkan Bagian',
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<ProgressProvider>(
                  builder: (context, prov, child) {
                    return ReorderableListView(
                      shrinkWrap: true,
                      // Reorder hanya aktif jika tombol di atas ditekan
                      buildDefaultDragHandles: isReordering,
                      onReorder: (oldIndex, newIndex) {
                        prov.reorderSections(oldIndex, newIndex);
                      },
                      children: prov.sections
                          .map(
                            (sec) => ListTile(
                              key: ValueKey(sec),
                              title: Text(sec),
                              // Saat mode reorder aktif, sembunyikan tombol edit/hapus agar tidak tertekan tidak sengaja
                              trailing: isReordering
                                  ? const Icon(Icons.drag_handle)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _showEditSectionDialog(
                                                context,
                                                prov,
                                                sec,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: prov.sections.length > 1
                                              ? () => _showDeleteSectionDialog(
                                                  context,
                                                  prov,
                                                  sec,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _showAddSectionDialog(context, mainProvider),
                  child: const Text('Tambah'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context, ProgressProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Bagian Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Bagian'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addSection(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDialog(
    BuildContext context,
    ProgressProvider provider,
    String oldName,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Bagian'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameSection(oldName, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(
    BuildContext context,
    ProgressProvider provider,
    String section,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Bagian?'),
        content: Text(
          'Anda yakin ingin menghapus bagian "$section"?\n\nTopik di dalamnya tidak akan dihapus, tetapi akan dipindahkan ke bagian pertama yang tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteSection(section);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
