import 'package:flutter/material.dart';
import '../../data/models/my_task_model.dart';
import '../../data/services/local_file_service.dart';

class MyTaskProvider with ChangeNotifier {
  final LocalFileService _fileService = LocalFileService();

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
      _categories = await _fileService.loadMyTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    await _fileService.saveMyTasks(_categories);
    notifyListeners();
  }

  Future<void> addCategory(String name, {String icon = 'task'}) async {
    final newCategory = TaskCategory(name: name, icon: icon, tasks: []);
    _categories.add(newCategory);
    await _saveTasks();
  }

  Future<void> renameCategory(TaskCategory category, String newName) async {
    final index = _categories.indexOf(category);
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
}
