import 'package:flutter/material.dart';
import '../../data/models/my_task_model.dart';
import '../../data/services/my_task_service.dart'; // DIUBAH: Menggunakan service yang baru

class MyTaskProvider with ChangeNotifier {
  final MyTaskService _myTaskService =
      MyTaskService(); // DIUBAH: Menggunakan MyTaskService

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
      // Memanggil metode dari service yang baru
      _categories = await _myTaskService.loadMyTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    // Memanggil metode dari service yang baru
    await _myTaskService.saveMyTasks(_categories);
    notifyListeners();
  }

  Future<void> addCategory(String name, {String icon = 'task'}) async {
    final newCategory = TaskCategory(name: name, icon: icon, tasks: []);
    _categories.add(newCategory);
    await _saveTasks();
  }

  Future<void> renameCategory(TaskCategory category, String newName) async {
    // Mencari index kategori berdasarkan nama unik, lebih aman
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
}
