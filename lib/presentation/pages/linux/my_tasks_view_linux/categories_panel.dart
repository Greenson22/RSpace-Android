// lib/presentation/pages/linux/my_tasks_view_linux/categories_panel.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/utils/scaffold_messenger_utils.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/task_category_list_tile.dart';

class CategoriesPanel extends StatefulWidget {
  final Function(TaskCategory) onCategorySelected;
  final TaskCategory? selectedCategory;

  const CategoriesPanel({
    super.key,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  State<CategoriesPanel> createState() => _CategoriesPanelState();
}

class _CategoriesPanelState extends State<CategoriesPanel> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);
    return Column(
      children: [
        _buildToolbar(context, provider),
        const Divider(height: 1),
        Expanded(child: _buildCategoryList(context, provider)),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, MyTaskProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Kategori",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              provider.isCategoryReorderEnabled ? Icons.check : Icons.sort,
            ),
            tooltip: provider.isCategoryReorderEnabled
                ? 'Selesai Mengurutkan'
                : 'Urutkan Kategori',
            onPressed: () => provider.toggleCategoryReorder(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Tambah Kategori",
            onPressed: () => _showAddCategoryDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, MyTaskProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.categories.isEmpty) {
      return Center(
        child: Text(
          provider.showHiddenCategories
              ? 'Tidak ada kategori.'
              : 'Tidak ada kategori terlihat.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ReorderableListView.builder(
      itemCount: provider.categories.length,
      buildDefaultDragHandles: provider.isCategoryReorderEnabled,
      onReorder: (oldIndex, newIndex) {
        if (provider.isCategoryReorderEnabled) {
          provider.reorderCategories(oldIndex, newIndex);
        }
      },
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return TaskCategoryListTile(
          key: ValueKey(category.name),
          category: category,
          isSelected: widget.selectedCategory?.name == category.name,
          onTap: () => widget.onCategorySelected(category),
          onRename: () =>
              _showRenameCategoryDialog(context, provider, category),
          onDelete: () =>
              _showDeleteCategoryDialog(context, provider, category),
          onIconChange: () =>
              _showIconPickerDialog(context, provider, category),
          onToggleVisibility: () =>
              _toggleVisibility(context, provider, category),
        );
      },
    );
  }

  // --- Dialog Methods ---
  void _showAddCategoryDialog(BuildContext context, MyTaskProvider provider) {
    showTopicTextInputDialog(
      context: context,
      title: 'Tambah Kategori Baru',
      label: 'Nama Kategori',
      onSave: (name) {
        provider.addCategory(name);
        showAppSnackBar(context, 'Kategori "$name" berhasil ditambahkan.');
      },
    );
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Kategori',
      label: 'Nama Baru',
      initialValue: category.name,
      onSave: (newName) {
        provider.renameCategory(category, newName);
        showAppSnackBar(context, 'Kategori diubah menjadi "$newName".');
      },
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Anda yakin ingin menghapus kategori "${category.name}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () {
              provider.deleteCategory(category);
              Navigator.pop(context);
              showAppSnackBar(
                context,
                'Kategori "${category.name}" berhasil dihapus.',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showIconPickerDialog(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    final List<String> icons = ['📝', '💼', '🏠', '🛒', '🎉', '💡', '❤️', '⭐'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Ikon Baru'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: icons.map((iconSymbol) {
            return InkWell(
              onTap: () {
                provider.updateCategoryIcon(category, iconSymbol);
                Navigator.pop(context);
                showAppSnackBar(
                  context,
                  'Ikon untuk "${category.name}" berhasil diubah.',
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(iconSymbol, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleVisibility(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    provider.toggleCategoryVisibility(category);
    final message = category.isHidden ? 'ditampilkan kembali' : 'disembunyikan';
    showAppSnackBar(context, 'Kategori "${category.name}" berhasil $message.');
  }
}
