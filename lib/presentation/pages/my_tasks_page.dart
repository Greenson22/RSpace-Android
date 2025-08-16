// lib/presentation/pages/my_tasks_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import 'my_tasks_page/dialogs/category_dialogs.dart';
import 'my_tasks_page/dialogs/task_dialogs.dart';
import 'my_tasks_page/widgets/category_card.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
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

  // HAPUS FUNGSI _handleKeyEvent DARI SINI

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: Consumer<MyTaskProvider>(
        builder: (context, provider, child) {
          // PINDAHKAN LOGIKA KEY HANDLER KE DALAM BUILDER INI
          void handleKeyEvent(RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              final categories = provider.categories;
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
                  } else if (event.logicalKey ==
                      LogicalKeyboardKey.arrowRight) {
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
              provider.reorderingCategoryName != null ||
              provider.isCategoryReorderEnabled;

          return RawKeyboardListener(
            focusNode: _focusNode,
            onKey: handleKeyEvent, // Gunakan handler yang baru didefinisikan
            child: Scaffold(
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
                      onPressed: () =>
                          showUncheckAllConfirmationDialog(context),
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
            ),
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
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        // PERBAIKAN: Bungkus proxy dengan provider yang benar
        return ChangeNotifierProvider.value(value: provider, child: child);
      },
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context, MyTaskProvider provider) {
    final categories = provider.categories;
    final int middle = (categories.length / 2).ceil();
    final List<TaskCategory> firstHalf = categories.sublist(0, middle);
    final List<TaskCategory> secondHalf = categories.sublist(middle);

    // PERBAIKAN: Panggil provider di luar build tree untuk mencegah error
    if (provider.isCategoryReorderEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Gunakan listen:false untuk memanggil aksi tanpa me-rebuild widget ini lagi
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
