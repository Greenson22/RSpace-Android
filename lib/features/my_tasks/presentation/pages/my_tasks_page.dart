// lib/features/my_tasks/presentation/pages/my_tasks_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../../application/my_task_provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../dialogs/category_dialogs.dart';
import '../dialogs/task_dialogs.dart';
import '../dialogs/task_list_dialog.dart';
import '../widgets/category_card.dart';
import '../widgets/category_grid_tile.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: const _MyTasksView(),
    );
  }
}

class _MyTasksView extends StatefulWidget {
  const _MyTasksView();

  @override
  State<_MyTasksView> createState() => _MyTasksViewState();
}

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

  void _showMoveTasksDialog(MyTaskProvider provider) async {
    final targetCategoryName = await showDialog<String>(
      context: context,
      builder: (context) {
        final sourceCategoryNames = provider.selectedTasks.keys.toSet();
        final availableCategories = provider.categories
            .where((cat) => !sourceCategoryNames.contains(cat.name))
            .toList();

        return SimpleDialog(
          title: const Text('Pindahkan ke Kategori'),
          children: availableCategories.map((category) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, category.name),
              child: Text(category.name),
            );
          }).toList(),
        );
      },
    );

    if (targetCategoryName != null) {
      await provider.moveSelectedTasks(targetCategoryName);
    }
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

          final isGridView = taskProvider.isGridView;
          final screenWidth = MediaQuery.of(context).size.width;
          final int crossAxisCount = isGridView
              ? (screenWidth > 600 ? 3 : 2)
              : (screenWidth > 700 ? 2 : 1);

          setState(() {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              int nextIndex = _focusedIndex + crossAxisCount;
              if (nextIndex < totalItems) {
                _focusedIndex = nextIndex;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              int prevIndex = _focusedIndex - crossAxisCount;
              if (prevIndex >= 0) {
                _focusedIndex = prevIndex;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if ((_focusedIndex + 1) % crossAxisCount != 0 &&
                  _focusedIndex < totalItems - 1) {
                _focusedIndex++;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (_focusedIndex % crossAxisCount != 0 && _focusedIndex > 0) {
                _focusedIndex--;
              }
            }
          });
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_focusedIndex < totalItems) {
            final category = categories[_focusedIndex];
            if (taskProvider.isGridView) {
              showTaskListDialog(context, category);
            } else {
              setState(() {
                _expansionState[category.name] =
                    !(_expansionState[category.name] ?? false);
              });
            }
          }
        }
      }
    }

    final isAnyReordering = taskProvider.isCategoryReorderEnabled;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isChristmas = themeProvider.isChristmasTheme;
    final isTransparent =
        themeProvider.backgroundImagePath != null ||
        themeProvider.isUnderwaterTheme;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: handleKeyEvent,
      child: Scaffold(
        backgroundColor: isTransparent ? Colors.transparent : null,
        appBar: taskProvider.isTaskSelectionMode
            ? _buildTaskSelectionAppBar(taskProvider)
            : _buildDefaultAppBar(taskProvider, isChristmas, isTransparent),
        body: WillPopScope(
          onWillPop: () async {
            if (taskProvider.isTaskSelectionMode) {
              taskProvider.clearTaskSelection();
              return false;
            }
            return true;
          },
          child: _buildBody(context, taskProvider),
        ),
        floatingActionButton:
            isAnyReordering || taskProvider.isTaskSelectionMode
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

  AppBar _buildTaskSelectionAppBar(MyTaskProvider provider) {
    return AppBar(
      title: Text('${provider.totalSelectedTasks} task dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearTaskSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.drive_file_move_outline),
          onPressed: () => _showMoveTasksDialog(provider),
          tooltip: 'Pindahkan Task',
        ),
      ],
    );
  }

  AppBar _buildDefaultAppBar(
    MyTaskProvider taskProvider,
    bool isChristmas,
    bool isTransparent,
  ) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isChristmas || isTransparent ? 0 : null,
      title: const Text('My Tasks'),
      actions: [
        if (!taskProvider.isCategoryReorderEnabled) ...[
          IconButton(
            icon: Icon(
              taskProvider.isGridView ? Icons.view_list : Icons.grid_view,
            ),
            tooltip: 'Ganti Tampilan',
            onPressed: () => taskProvider.toggleLayout(),
          ),
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
        ],
        IconButton(
          icon: Icon(
            taskProvider.isCategoryReorderEnabled ? Icons.cancel : Icons.sort,
          ),
          tooltip: taskProvider.isCategoryReorderEnabled
              ? 'Selesai Mengurutkan'
              : 'Urutkan Kategori',
          onPressed: () {
            if (!taskProvider.isCategoryReorderEnabled) {
              setState(() {
                _expansionState.clear();
              });
            }
            taskProvider.toggleCategoryReorder();
          },
        ),
      ],
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

    if (provider.isGridView) {
      return _buildGridViewLayout(context, provider);
    } else {
      return _buildListViewLayout(context, provider);
    }
  }

  Widget _buildListViewLayout(BuildContext context, MyTaskProvider provider) {
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

  Widget _buildGridViewLayout(BuildContext context, MyTaskProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return CategoryGridTile(
          key: ValueKey(category.name),
          category: category,
          isFocused: _isKeyboardActive && index == _focusedIndex,
          onTap: () => showTaskListDialog(context, category),
        );
      },
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    MyTaskProvider provider,
  ) {
    return ReorderableListView.builder(
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Material(elevation: 4.0, child: child),
        );
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
          isExpanded: provider.isCategoryReorderEnabled
              ? false
              : (_expansionState[category.name] ?? false),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _expansionState[category.name] = isExpanded;
            });
          },
        );
      },
      onReorder: (oldIndex, newIndex) {
        final categoryName = provider.categories[oldIndex].name;
        provider.reorderCategories(oldIndex, newIndex);
        setState(() {
          _expansionState[categoryName] = false;
        });
      },
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context, MyTaskProvider provider) {
    final categories = provider.categories;
    final int middle = (categories.length / 2).ceil();
    final List<TaskCategory> firstHalf = categories.sublist(0, middle);
    final List<TaskCategory> secondHalf = categories.sublist(middle);

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
            isExpanded: provider.isCategoryReorderEnabled
                ? false
                : (_expansionState[category.name] ?? false),
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
