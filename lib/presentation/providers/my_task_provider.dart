import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/my_task_model.dart';
import '../../data/services/my_task_service.dart';

class MyTaskProvider with ChangeNotifier {
  final MyTaskService _myTaskService = MyTaskService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<TaskCategory> _categories = [];
  List<TaskCategory> get categories => _categories;

  MyTaskProvider() {
    fetchTasks();
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
    final index = _categories.indexWhere((c) => c.name == category.name);
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
    _categories.removeWhere((c) => c.name == category.name);
    await _saveTasks();
  }

  // --- Task Management ---

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

  // ==> FUNGSI TOGGLE DIPERBARUI <==
  Future<void> toggleTaskChecked(
    TaskCategory category,
    MyTask task, {
    bool confirmUpdate = false, // Parameter untuk konfirmasi
  }) async {
    final categoryIndex = _categories.indexOf(category);
    if (categoryIndex != -1) {
      final taskIndex = _categories[categoryIndex].tasks.indexOf(task);
      if (taskIndex != -1) {
        final isChecking = !_categories[categoryIndex].tasks[taskIndex].checked;
        _categories[categoryIndex].tasks[taskIndex].checked = isChecking;

        // Jika dicentang (isChecking == true) dan user mengonfirmasi,
        // update tanggal dan tambah count.
        if (isChecking && confirmUpdate) {
          _categories[categoryIndex].tasks[taskIndex].date = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now());
          _categories[categoryIndex].tasks[taskIndex].count++; // Tambah count
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
}
