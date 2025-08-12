import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/my_task_model.dart';
import '../../data/services/my_task_service.dart';

class MyTaskProvider with ChangeNotifier {
  final MyTaskService _myTaskService = MyTaskService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ==> STATE BARU UNTUK MODE PINDAH <==
  bool _isReorderEnabled = false;
  bool get isReorderEnabled => _isReorderEnabled;

  List<TaskCategory> _categories = [];
  List<TaskCategory> get categories => _categories;

  MyTaskProvider() {
    fetchTasks();
  }

  // ==> FUNGSI UNTUK TOGGLE MODE PINDAH <==
  void toggleReorder() {
    _isReorderEnabled = !_isReorderEnabled;
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _myTaskService.loadMyTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    await _myTaskService.saveMyTasks(_categories);
    notifyListeners();
  }

  // --- Category Management ---
  Future<void> addCategory(String name, {String icon = 'task'}) async {
    final newCategory = TaskCategory(name: name, icon: icon, tasks: []);
    _categories.add(newCategory);
    await _saveTasks();
  }

  Future<void> renameCategory(TaskCategory category, String newName) async {
    final index = _categories.indexWhere((c) => c == category);
    if (index != -1) {
      _categories[index] = TaskCategory(
        name: newName,
        icon: category.icon,
        tasks: category.tasks,
      );
      await _saveTasks();
    }
  }

  Future<void> deleteCategory(TaskCategory category) async {
    _categories.remove(category);
    await _saveTasks();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    await _saveTasks();
  }

  // --- Task Management ---

  // ==> FUNGSI BARU UNTUK MENGURUTKAN TASK <==
  Future<void> reorderTasks(
    TaskCategory category,
    int oldIndex,
    int newIndex,
  ) async {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = _categories[categoryIndex].tasks.removeAt(oldIndex);
      _categories[categoryIndex].tasks.insert(newIndex, task);
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
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      _categories[categoryIndex].tasks.add(newTask);
      await _saveTasks();
    }
  }

  Future<void> renameTask(
    TaskCategory category,
    MyTask task,
    String newName,
  ) async {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _categories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _categories[categoryIndex].tasks[taskIndex].name = newName;
        await _saveTasks();
      }
    }
  }

  Future<void> deleteTask(TaskCategory category, MyTask task) async {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      _categories[categoryIndex].tasks.remove(task);
      await _saveTasks();
    }
  }

  Future<void> toggleTaskChecked(
    TaskCategory category,
    MyTask task, {
    bool confirmUpdate = false,
  }) async {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _categories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        final isChecking = !_categories[categoryIndex].tasks[taskIndex].checked;
        _categories[categoryIndex].tasks[taskIndex].checked = isChecking;

        if (isChecking && confirmUpdate) {
          _categories[categoryIndex].tasks[taskIndex].date = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now());
          _categories[categoryIndex].tasks[taskIndex].count++;
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
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _categories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _categories[categoryIndex].tasks[taskIndex].date = DateFormat(
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
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _categories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        _categories[categoryIndex].tasks[taskIndex].count = newCount;
        await _saveTasks();
      }
    }
  }

  Future<void> uncheckAllTasks() async {
    for (final category in _categories) {
      for (final task in category.tasks) {
        if (task.checked) {
          task.checked = false;
        }
      }
    }
    await _saveTasks();
  }
}
