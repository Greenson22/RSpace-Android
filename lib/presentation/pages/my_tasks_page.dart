// lib/presentation/pages/my_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  // Fungsi-fungsi dialog dipindahkan ke luar build method agar lebih rapi
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

  // ... (semua fungsi dialog lainnya tetap di sini, tidak perlu diubah) ...
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

  void _showIconPickerDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
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
                _showSnackBar(
                  context,
                  'Ikon untuk "${category.name}" berhasil diubah.',
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(iconSymbol, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    provider.toggleCategoryVisibility(category);
    final message = category.isHidden ? 'ditampilkan kembali' : 'disembunyikan';
    _showSnackBar(context, 'Kategori "${category.name}" berhasil $message.');
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
                if (provider.reorderingCategoryName == null) ...[
                  IconButton(
                    icon: Icon(
                      provider.showHiddenCategories
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: provider.showHiddenCategories
                        ? 'Sembunyikan Kategori Tersembunyi'
                        : 'Tampilkan Kategori Tersembunyi',
                    onPressed: () => provider.toggleShowHidden(),
                  ),
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
                ],
                if (!isAnyReordering)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Hapus Semua Centang',
                    onPressed: () => _showUncheckAllConfirmationDialog(context),
                  ),
              ],
            ),
            body: _buildBody(context, provider), // Diubah ke method baru
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

  // --- METODE BARU UNTUK MEMBANGUN BODY SECARA RESPONSIF ---
  Widget _buildBody(BuildContext context, MyTaskProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.categories.isEmpty) {
      return Center(
        child: Text(
          provider.showHiddenCategories
              ? 'Tidak ada kategori. Tekan + untuk menambah.'
              : 'Tidak ada kategori yang terlihat.\nCoba tampilkan kategori tersembunyi.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint untuk dua kolom, bisa disesuaikan
        const double breakpoint = 700.0;
        if (constraints.maxWidth > breakpoint) {
          return _buildTwoColumnLayout(context, provider);
        } else {
          return _buildSingleColumnLayout(context, provider);
        }
      },
    );
  }

  // Widget untuk tata letak satu kolom (Mobile)
  Widget _buildSingleColumnLayout(
    BuildContext context,
    MyTaskProvider provider,
  ) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: provider.isCategoryReorderEnabled,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _buildCategoryCard(
          context,
          provider,
          category,
          ValueKey(category.name),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (provider.isCategoryReorderEnabled) {
          provider.reorderCategories(oldIndex, newIndex);
        }
      },
    );
  }

  // Widget untuk tata letak dua kolom (Desktop)
  Widget _buildTwoColumnLayout(BuildContext context, MyTaskProvider provider) {
    final categories = provider.categories;
    final int middle = (categories.length / 2).ceil();
    final List<TaskCategory> firstHalf = categories.sublist(0, middle);
    final List<TaskCategory> secondHalf = categories.sublist(middle);

    // Reordering dinonaktifkan di tampilan desktop untuk simplisitas
    if (provider.isCategoryReorderEnabled) {
      // Keluar dari mode reorder jika beralih ke desktop
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.toggleCategoryReorder(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Pertama
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: firstHalf.length,
              itemBuilder: (context, index) {
                final category = firstHalf[index];
                return _buildCategoryCard(
                  context,
                  provider,
                  category,
                  ValueKey(category.name),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Kolom Kedua
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: secondHalf.length,
              itemBuilder: (context, index) {
                final category = secondHalf[index];
                return _buildCategoryCard(
                  context,
                  provider,
                  category,
                  ValueKey(category.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // --- Akhir dari metode-metode baru ---

  Widget _buildCategoryCard(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
    Key key,
  ) {
    final theme = Theme.of(context);
    final isHidden = category.isHidden;
    final isThisCategoryReorderingTask =
        provider.reorderingCategoryName == category.name;
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;
    final isAnotherTaskReordering =
        provider.reorderingCategoryName != null &&
        !isThisCategoryReorderingTask;
    final isCardDisabled = isCategoryReorderMode || isAnotherTaskReordering;

    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : (isAnotherTaskReordering
              ? theme.disabledColor.withOpacity(0.1)
              : theme.cardColor);
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: elevation,
      color: cardColor,
      child: ExpansionTile(
        enabled: !isCategoryReorderMode,
        initiallyExpanded: isThisCategoryReorderingTask,
        leading: Text(
          category.icon,
          style: TextStyle(
            fontSize: 28,
            color: isHidden ? textColor : theme.primaryColor,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        trailing: isThisCategoryReorderingTask
            ? TextButton.icon(
                icon: const Icon(Icons.done),
                label: const Text('Selesai'),
                onPressed: () => provider.disableReordering(),
              )
            : PopupMenuButton<String>(
                enabled: !isCardDisabled,
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameCategoryDialog(context, category);
                  } else if (value == 'change_icon') {
                    _showIconPickerDialog(context, category);
                  } else if (value == 'toggle_visibility') {
                    _toggleVisibility(context, category);
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
                  const PopupMenuItem(
                    value: 'change_icon',
                    child: Text('Ubah Ikon'),
                  ),
                  PopupMenuItem(
                    value: 'toggle_visibility',
                    child: Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        children: [
          _buildTaskList(
            context,
            provider,
            category,
            isThisCategoryReorderingTask,
            isHidden,
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
    bool isParentHidden,
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
            isParentHidden,
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
                isParentHidden,
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
    bool isParentHidden,
    Key? key,
  ) {
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;
    final textColor = isParentHidden || task.checked ? Colors.grey : null;

    return ListTile(
      key: key,
      leading: isReordering
          ? Icon(Icons.drag_handle, color: textColor)
          : Checkbox(
              value: task.checked,
              onChanged: isCategoryReorderMode || isParentHidden
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
          color: textColor,
        ),
      ),
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor),
          children: [
            const TextSpan(text: 'Due: '),
            TextSpan(
              text: task.date,
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' | Count: '),
            TextSpan(
              text: task.count.toString(),
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailing: isReordering || isCategoryReorderMode || isParentHidden
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
