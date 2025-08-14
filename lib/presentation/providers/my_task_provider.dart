// lib/presentation/providers/my_task_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/my_task_model.dart';
import '../../data/services/my_task_service.dart';

class MyTaskProvider with ChangeNotifier {
  final MyTaskService _myTaskService = MyTaskService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isCategoryReorderEnabled = false;
  bool get isCategoryReorderEnabled => _isCategoryReorderEnabled;

  String? _reorderingCategoryName;
  String? get reorderingCategoryName => _reorderingCategoryName;

  bool _showHiddenCategories = false; // ==> DITAMBAHKAN
  bool get showHiddenCategories => _showHiddenCategories; // ==> DITAMBAHKAN

  List<TaskCategory> _allCategories = [];
  List<TaskCategory> get categories {
    if (_showHiddenCategories) {
      return _allCategories;
    }
    return _allCategories.where((c) => !c.isHidden).toList();
  }

  MyTaskProvider() {
    fetchTasks();
  }

  // ==> FUNGSI BARU <==
  void toggleShowHidden() {
    _showHiddenCategories = !_showHiddenCategories;
    notifyListeners();
  }

  void toggleCategoryReorder() {
    _isCategoryReorderEnabled = !_isCategoryReorderEnabled;
    if (_isCategoryReorderEnabled) {
      _reorderingCategoryName = null;
    }
    notifyListeners();
  }

  void enableTaskReordering(String categoryName) {
    _reorderingCategoryName = categoryName;
    if (_isCategoryReorderEnabled) {
      _isCategoryReorderEnabled = false;
    }
    notifyListeners();
  }

  void disableReordering() {
    _reorderingCategoryName = null;
    _isCategoryReorderEnabled = false;
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allCategories = await _myTaskService.loadMyTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    await _myTaskService.saveMyTasks(_allCategories);
    notifyListeners();
  }

  // --- Category Management ---
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _allCategories.removeAt(oldIndex);
    _allCategories.insert(newIndex, item);
    await _saveTasks();
  }

  Future<void> addCategory(String name, {String icon = '📝'}) async {
    final newCategory = TaskCategory(
      name: name,
      icon: icon,
      tasks: [],
      isHidden: false,
    );
    _allCategories.add(newCategory);
    await _saveTasks();
  }

  Future<void> renameCategory(TaskCategory category, String newName) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      if (_reorderingCategoryName == _allCategories[index].name) {
        _reorderingCategoryName = newName;
      }
      _allCategories[index] = TaskCategory(
        name: newName,
        icon: category.icon,
        tasks: category.tasks,
        isHidden: category.isHidden,
      );
      await _saveTasks();
    }
  }

  Future<void> deleteCategory(TaskCategory category) async {
    _allCategories.removeWhere((c) => c.name == category.name);
    await _saveTasks();
  }

  Future<void> updateCategoryIcon(TaskCategory category, String newIcon) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      _allCategories[index] = TaskCategory(
        name: category.name,
        icon: newIcon,
        tasks: category.tasks,
        isHidden: category.isHidden,
      );
      await _saveTasks();
    }
  }

  // ==> FUNGSI BARU <==
  Future<void> toggleCategoryVisibility(TaskCategory category) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      _allCategories[index] = TaskCategory(
        name: category.name,
        icon: category.icon,
        tasks: category.tasks,
        isHidden: !category.isHidden,
      );
      await _saveTasks();
    }
  }

  // --- Task Management ---
  Future<void> reorderTasks(
    TaskCategory category,
    int oldIndex,
    int newIndex,
  ) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = _allCategories[categoryIndex].tasks.removeAt(oldIndex);
      _allCategories[categoryIndex].tasks.insert(newIndex, task);
      await _saveTasks();
    }
  }

  Future<void> addTask(TaskCategory category, String taskName) async {
    final newTask = MyTask(
      name: taskName,
      count: 0,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      checked: false,
    );
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      _allCategories[categoryIndex].tasks.add(newTask);
      await _saveTasks();
    }
  }

  Future<void> renameTask(
    TaskCategory category,
    MyTask task,
    String newName,
  ) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].name = newName;
        await _saveTasks();
      }
    }
  }

  Future<void> deleteTask(TaskCategory category, MyTask task) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      _allCategories[categoryIndex].tasks.remove(task);
      await _saveTasks();
    }
  }

  Future<void> toggleTaskChecked(
    TaskCategory category,
    MyTask task, {
    bool confirmUpdate = false,
  }) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        final isChecking =
            !_allCategories[categoryIndex].tasks[taskIndex].checked;
        _allCategories[categoryIndex].tasks[taskIndex].checked = isChecking;

        if (isChecking && confirmUpdate) {
          _allCategories[categoryIndex].tasks[taskIndex].date = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now());
          _allCategories[categoryIndex].tasks[taskIndex].count++;
        }
        await _saveTasks();
      }
    }
  }

  Future<void> updateTaskDate(
    TaskCategory category,
    MyTask task,
    DateTime newDate,
  ) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].date = DateFormat(
          'yyyy-MM-dd',
        ).format(newDate);
        await _saveTasks();
      }
    }
  }

  Future<void> updateTaskCount(
    TaskCategory category,
    MyTask task,
    int newCount,
  ) async {
    final categoryIndex = _allCategories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].count = newCount;
        await _saveTasks();
      }
    }
  }

  Future<void> uncheckAllTasks() async {
    for (final category in _allCategories) {
      for (final task in category.tasks) {
        if (task.checked) {
          task.checked = false;
        }
      }
    }
    await _saveTasks();
  }
}
