import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // --- Dialog untuk Kategori ---
  void _showAddCategoryDialog(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Tambah Kategori Baru',
      label: 'Nama Kategori',
      onSave: (name) {
        provider.addCategory(name);
        _showSnackBar(context, 'Kategori "$name" berhasil ditambahkan.');
      },
    );
  }

  void _showRenameCategoryDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Kategori',
      label: 'Nama Baru',
      initialValue: category.name,
      onSave: (newName) {
        provider.renameCategory(category, newName);
        _showSnackBar(context, 'Kategori diubah menjadi "$newName".');
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
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
              _showSnackBar(
                context,
                'Kategori "${category.name}" berhasil dihapus.',
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Dialog untuk Task ---
  void _showAddTaskDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Tambah Task Baru',
      label: 'Nama Task',
      onSave: (name) {
        provider.addTask(category, name);
        _showSnackBar(context, 'Task "$name" berhasil ditambahkan.');
      },
    );
  }

  void _showRenameTaskDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Task',
      label: 'Nama Baru',
      initialValue: task.name,
      onSave: (newName) {
        provider.renameTask(category, task, newName);
        _showSnackBar(context, 'Task diubah menjadi "$newName".');
      },
    );
  }

  void _showDeleteTaskDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Task'),
        content: Text('Anda yakin ingin menghapus task "${task.name}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () {
              provider.deleteTask(category, task);
              Navigator.pop(context);
              _showSnackBar(context, 'Task "${task.name}" berhasil dihapus.');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateDateDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) async {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final initialDate = DateTime.tryParse(task.date) ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (newDate != null) {
      provider.updateTaskDate(category, task, newDate);
      _showSnackBar(context, 'Tanggal task berhasil diubah.');
    }
  }

  void _showUpdateCountDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Jumlah (Count)',
      label: 'Jumlah Baru',
      initialValue: task.count.toString(),
      keyboardType: TextInputType.number,
      onSave: (newValue) {
        final newCount = int.tryParse(newValue);
        if (newCount != null) {
          provider.updateTaskCount(category, task, newCount);
          _showSnackBar(context, 'Jumlah task berhasil diubah.');
        } else {
          _showSnackBar(
            context,
            'Input tidak valid. Harap masukkan angka.',
            isError: true,
          );
        }
      },
    );
  }

  Future<bool?> _showToggleConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
          'Update tanggal ke hari ini dan tambah jumlah (count) sebanyak 1?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Ya, Update'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  void _showUncheckAllConfirmationDialog(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Anda yakin ingin menghapus semua centang dari task?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('Ya, Hapus'),
            onPressed: () {
              provider.uncheckAllTasks();
              Navigator.of(dialogContext).pop();
              _showSnackBar(context, 'Semua centang telah dihapus.');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: Consumer<MyTaskProvider>(
        builder: (context, provider, child) {
          final isAnyReordering =
              provider.reorderingCategoryName != null ||
              provider.isCategoryReorderEnabled;

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tasks'),
              actions: [
                // Tombol "Urutkan Kategori" hanya muncul jika tidak ada mode urut lain yang aktif
                if (provider.reorderingCategoryName == null)
                  IconButton(
                    icon: Icon(
                      provider.isCategoryReorderEnabled
                          ? Icons.cancel
                          : Icons.sort,
                    ),
                    tooltip: provider.isCategoryReorderEnabled
                        ? 'Selesai Mengurutkan'
                        : 'Urutkan Kategori',
                    onPressed: () => provider.toggleCategoryReorder(),
                  ),
                // Tombol "Hapus Centang" hanya muncul jika tidak ada mode urut yang aktif
                if (!isAnyReordering)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Hapus Semua Centang',
                    onPressed: () => _showUncheckAllConfirmationDialog(context),
                  ),
              ],
            ),
            body: _buildBody(context, provider),
            floatingActionButton: isAnyReordering
                ? null
                : FloatingActionButton(
                    onPressed: () => _showAddCategoryDialog(context),
                    child: const Icon(Icons.add),
                    tooltip: 'Tambah Kategori',
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyTaskProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.categories.isEmpty) {
      return const Center(
        child: Text('Tidak ada kategori. Tekan + untuk menambah.'),
      );
    }

    return ReorderableListView.builder(
      // Aktifkan drag handle hanya jika mode urutkan kategori aktif
      buildDefaultDragHandles: provider.isCategoryReorderEnabled,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _buildCategoryCard(
          context,
          provider,
          category,
          ValueKey(category),
        );
      },
      onReorder: (oldIndex, newIndex) {
        // Hanya izinkan reorder jika mode urutkan kategori aktif
        if (provider.isCategoryReorderEnabled) {
          provider.reorderCategories(oldIndex, newIndex);
        }
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
    Key key,
  ) {
    final isThisCategoryReorderingTask =
        provider.reorderingCategoryName == category.name;
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;
    final isAnotherTaskReordering =
        provider.reorderingCategoryName != null &&
        !isThisCategoryReorderingTask;

    // Kategori menjadi non-interaktif jika sedang mengurutkan kategori lain (mode global)
    // atau jika sedang mengurutkan task di kategori lain.
    final isCardDisabled = isCategoryReorderMode || isAnotherTaskReordering;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      color: isAnotherTaskReordering
          ? Theme.of(context).disabledColor.withOpacity(0.1)
          : null,
      child: ExpansionTile(
        // Tile bisa dibuka tutup jika tidak ada mode reorder global
        // atau jika mode reorder task aktif untuk tile ini
        enabled: !isCategoryReorderMode,
        initiallyExpanded: isThisCategoryReorderingTask,
        leading: Icon(
          getIconData(category.icon),
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: isThisCategoryReorderingTask
            ? TextButton.icon(
                icon: const Icon(Icons.done),
                label: const Text('Selesai'),
                onPressed: () => provider.disableReordering(),
              )
            : PopupMenuButton<String>(
                // Menu nonaktif jika ada mode reorder global atau reorder task di kategori lain
                enabled: !isCardDisabled,
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameCategoryDialog(context, category);
                  } else if (value == 'delete') {
                    _showDeleteCategoryDialog(context, category);
                  } else if (value == 'add_task') {
                    _showAddTaskDialog(context, category);
                  } else if (value == 'reorder_tasks') {
                    provider.enableTaskReordering(category.name);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_task',
                    child: Text('Tambah Task'),
                  ),
                  const PopupMenuItem(
                    value: 'reorder_tasks',
                    child: Text('Urutkan Task'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Ubah Nama'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
        children: [
          _buildTaskList(
            context,
            provider,
            category,
            isThisCategoryReorderingTask,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
    bool isReordering,
  ) {
    if (isReordering) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: category.tasks.length,
        buildDefaultDragHandles: true,
        itemBuilder: (context, index) {
          final task = category.tasks[index];
          return _buildTaskTile(
            context,
            provider,
            category,
            task,
            isReordering,
            ValueKey(task),
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderTasks(category, oldIndex, newIndex);
        },
      );
    } else {
      return Column(
        children: category.tasks
            .map(
              (task) => _buildTaskTile(
                context,
                provider,
                category,
                task,
                isReordering,
                null,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildTaskTile(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
    MyTask task,
    bool isReordering,
    Key? key,
  ) {
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;

    return ListTile(
      key: key,
      leading: isReordering
          ? const Icon(Icons.drag_handle)
          : Checkbox(
              value: task.checked,
              // Checkbox nonaktif jika ada mode reorder APAPUN yang aktif
              onChanged: isCategoryReorderMode
                  ? null
                  : (bool? value) async {
                      if (value == true) {
                        final shouldUpdate =
                            await _showToggleConfirmationDialog(context);
                        if (shouldUpdate == true) {
                          provider.toggleTaskChecked(
                            category,
                            task,
                            confirmUpdate: true,
                          );
                        }
                      } else {
                        provider.toggleTaskChecked(
                          category,
                          task,
                          confirmUpdate: false,
                        );
                      }
                    },
            ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.checked ? TextDecoration.lineThrough : null,
          color: task.checked ? Colors.grey : null,
        ),
      ),
      subtitle: Text('Due: ${task.date} | Count: ${task.count}'),
      trailing: isReordering || isCategoryReorderMode
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameTaskDialog(context, category, task);
                } else if (value == 'edit_date') {
                  _showUpdateDateDialog(context, category, task);
                } else if (value == 'edit_count') {
                  _showUpdateCountDialog(context, category, task);
                } else if (value == 'delete') {
                  _showDeleteTaskDialog(context, category, task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
                const PopupMenuItem(
                  value: 'edit_date',
                  child: Text('Ubah Tanggal'),
                ),
                const PopupMenuItem(
                  value: 'edit_count',
                  child: Text('Ubah Jumlah'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
    );
  }
}
