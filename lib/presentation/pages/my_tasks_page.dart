// lib/presentation/pages/my_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import 'my_tasks_page/dialogs/category_dialogs.dart';
import 'my_tasks_page/dialogs/task_dialogs.dart';
import 'my_tasks_page/widgets/category_card.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

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
                    onPressed: () => showUncheckAllConfirmationDialog(context),
                  ),
              ],
            ),
            body: _buildBody(context, provider),
            floatingActionButton: isAnyReordering
                ? null
                : FloatingActionButton(
                    onPressed: () => showAddCategoryDialog(context),
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
        const double breakpoint = 700.0;
        if (constraints.maxWidth > breakpoint) {
          return _buildTwoColumnLayout(context, provider);
        } else {
          return _buildSingleColumnLayout(context, provider);
        }
      },
    );
  }

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
        return CategoryCard(key: ValueKey(category.name), category: category);
      },
      onReorder: (oldIndex, newIndex) {
        if (provider.isCategoryReorderEnabled) {
          provider.reorderCategories(oldIndex, newIndex);
        }
      },
      // ==> TAMBAHKAN KODE INI <==
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        // Bungkus kembali widget yang diseret dengan provider yang sama
        return ChangeNotifierProvider.value(value: provider, child: child);
      },
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context, MyTaskProvider provider) {
    final categories = provider.categories;
    final int middle = (categories.length / 2).ceil();
    final List<TaskCategory> firstHalf = categories.sublist(0, middle);
    final List<TaskCategory> secondHalf = categories.sublist(middle);

    if (provider.isCategoryReorderEnabled) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.toggleCategoryReorder(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: firstHalf.length,
              itemBuilder: (context, index) {
                final category = firstHalf[index];
                return CategoryCard(
                  key: ValueKey(category.name),
                  category: category,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: secondHalf.length,
              itemBuilder: (context, index) {
                final category = secondHalf[index];
                return CategoryCard(
                  key: ValueKey(category.name),
                  category: category,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
