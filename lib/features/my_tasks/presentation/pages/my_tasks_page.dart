// lib/presentation/pages/my_tasks_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../../application/my_task_provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../dialogs/category_dialogs.dart';
import '../dialogs/task_dialogs.dart';
import '../widgets/category_card.dart';

// --- PERUBAHAN STRUKTUR UTAMA ---
/// Halaman utama yang sekarang hanya bertugas membuat dan menyediakan MyTaskProvider.
class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: const _MyTasksView(), // UI utama dipindahkan ke widget terpisah
    );
  }
}

/// Widget StatefulWidget internal untuk menangani UI dan state lokal halaman.
class _MyTasksView extends StatefulWidget {
  const _MyTasksView();

  @override
  State<_MyTasksView> createState() => _MyTasksViewState();
}
// --- AKHIR PERUBAHAN STRUKTUR ---

class _MyTasksViewState extends State<_MyTasksView> {
  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = 0;
  Timer? _focusTimer;
  bool _isKeyboardActive = false;
  final Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<MyTaskProvider>(context);

    void handleKeyEvent(RawKeyEvent event) {
      if (event is RawKeyDownEvent) {
        final categories = taskProvider.categories;
        final totalItems = categories.length;

        if (totalItems == 0) return;

        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() => _isKeyboardActive = true);
          _focusTimer?.cancel();
          _focusTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _isKeyboardActive = false);
          });

          final isTwoColumn = MediaQuery.of(context).size.width > 700.0;
          final int middle = (totalItems / 2).ceil();

          setState(() {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (isTwoColumn) {
                if (_focusedIndex < middle - 1 ||
                    (_focusedIndex >= middle &&
                        _focusedIndex < totalItems - 1)) {
                  _focusedIndex++;
                }
              } else {
                if (_focusedIndex < totalItems - 1) _focusedIndex++;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_focusedIndex > 0) _focusedIndex--;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (isTwoColumn && _focusedIndex < middle) {
                int targetIndex = _focusedIndex + middle;
                _focusedIndex = targetIndex < totalItems
                    ? targetIndex
                    : totalItems - 1;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (isTwoColumn && _focusedIndex >= middle) {
                _focusedIndex -= middle;
              }
            }
          });
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_focusedIndex < totalItems) {
            final categoryName = categories[_focusedIndex].name;
            setState(() {
              _expansionState[categoryName] =
                  !(_expansionState[categoryName] ?? false);
            });
          }
        } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
          Navigator.of(context).pop();
        }
      }
    }

    final isAnyReordering =
        taskProvider.reorderingCategoryName != null ||
        taskProvider.isCategoryReorderEnabled;
    final isChristmas = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isChristmasTheme;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: handleKeyEvent,
      child: Scaffold(
        backgroundColor: isChristmas ? Colors.transparent : null,
        appBar: AppBar(
          backgroundColor: isChristmas ? Colors.black.withOpacity(0.2) : null,
          elevation: isChristmas ? 0 : null,
          title: const Text('My Tasks'),
          actions: [
            if (taskProvider.reorderingCategoryName == null) ...[
              IconButton(
                icon: Icon(
                  taskProvider.showHiddenCategories
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                tooltip: taskProvider.showHiddenCategories
                    ? 'Sembunyikan Kategori Tersembunyi'
                    : 'Tampilkan Kategori Tersembunyi',
                onPressed: () => taskProvider.toggleShowHidden(),
              ),
              IconButton(
                icon: Icon(
                  taskProvider.isCategoryReorderEnabled
                      ? Icons.cancel
                      : Icons.sort,
                ),
                tooltip: taskProvider.isCategoryReorderEnabled
                    ? 'Selesai Mengurutkan'
                    : 'Urutkan Kategori',
                onPressed: () => taskProvider.toggleCategoryReorder(),
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
        body: _buildBody(context, taskProvider),
        floatingActionButton: isAnyReordering
            ? null
            : FloatingActionButton(
                onPressed: () => showAddCategoryDialog(context),
                child: const Icon(Icons.add),
                tooltip: 'Tambah Kategori',
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      // --- PERBAIKAN PADA PROXY DECORATOR ---
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        // Membungkus item yang di-drag dengan Material memberikan
        // dasar render yang bersih dan mencegah error.
        return Material(elevation: 4.0, child: child);
      },
      buildDefaultDragHandles: provider.isCategoryReorderEnabled,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return CategoryCard(
          key: ValueKey(category.name),
          category: category,
          isFocused: _isKeyboardActive && index == _focusedIndex,
          isExpanded: _expansionState[category.name] ?? false,
          onExpansionChanged: (isExpanded) {
            setState(() {
              _expansionState[category.name] = isExpanded;
            });
          },
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (provider.isCategoryReorderEnabled) {
          provider.reorderCategories(oldIndex, newIndex);
        }
      },
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context, MyTaskProvider provider) {
    final categories = provider.categories;
    final int middle = (categories.length / 2).ceil();
    final List<TaskCategory> firstHalf = categories.sublist(0, middle);
    final List<TaskCategory> secondHalf = categories.sublist(middle);

    if (provider.isCategoryReorderEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<MyTaskProvider>(
            context,
            listen: false,
          ).toggleCategoryReorder();
        }
      });
    }

    Widget buildColumn(List<TaskCategory> categoryList, int indexOffset) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: categoryList.length,
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final overallIndex = index + indexOffset;
          return CategoryCard(
            key: ValueKey(category.name),
            category: category,
            isFocused: _isKeyboardActive && overallIndex == _focusedIndex,
            isExpanded: _expansionState[category.name] ?? false,
            onExpansionChanged: (isExpanded) {
              setState(() {
                _expansionState[category.name] = isExpanded;
              });
            },
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: buildColumn(firstHalf, 0)),
          const SizedBox(width: 16),
          Expanded(child: buildColumn(secondHalf, middle)),
        ],
      ),
    );
  }
}
