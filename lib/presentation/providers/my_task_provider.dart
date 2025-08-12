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
}
