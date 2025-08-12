// lib/data/services/my_task_service.dart
import 'dart:convert';
import 'dart:io';
import '../models/my_task_model.dart';
import 'path_service.dart';

class MyTaskService {
  final PathService _pathService = PathService();

  Future<List<TaskCategory>> loadMyTasks() async {
    // Menunggu hasil path dari _pathService
    final filePath = await _pathService.myTasksPath;
    final file = File(filePath);

    if (!await file.exists()) {
      // Buat file default jika tidak ditemukan
      await file.writeAsString(jsonEncode({"categories": []}));
      return [];
    }

    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final categoriesList = jsonData['categories'] as List<dynamic>;

    return categoriesList.map((item) => TaskCategory.fromJson(item)).toList();
  }

  Future<void> saveMyTasks(List<TaskCategory> categories) async {
    // Menunggu hasil path dari _pathService
    final filePath = await _pathService.myTasksPath;
    final file = File(filePath);
    final newJsonData = {
      'categories': categories.map((c) => c.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(newJsonData));
  }
}
