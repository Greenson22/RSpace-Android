// lib/data/models/my_task_model.dart
// 1. IMPORT UUID UNTUK MEMBUAT ID UNIK
import 'package:uuid/uuid.dart';

class MyTask {
  // 2. TAMBAHKAN PROPERTI ID
  final String id;
  String name;
  int count;
  String date;
  bool checked;

  MyTask({
    String? id, // 3. BUAT ID JADI OPSIONAL DI KONSTRUKTOR
    required this.name,
    required this.count,
    required this.date,
    required this.checked,
    // 4. GENERATE ID JIKA KOSONG (ID BARU AKAN DIBUAT SAAT TUGAS BARU DIBUAT)
  }) : id = id ?? const Uuid().v4();

  factory MyTask.fromJson(Map<String, dynamic> json) {
    return MyTask(
      // 5. BACA ID DARI JSON, ATAU BUAT YANG BARU JIKA TIDAK ADA (UNTUK KOMPATIBILITAS DATA LAMA)
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] ?? 'Untitled Task',
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
      checked: json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 6. SIMPAN ID KE JSON
      'id': id,
      'name': name,
      'count': count,
      'date': date,
      'checked': checked,
    };
  }
}

class TaskCategory {
  final String name;
  final String icon;
  final List<MyTask> tasks;
  final bool isHidden;

  TaskCategory({
    required this.name,
    required this.icon,
    required this.tasks,
    this.isHidden = false,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List;
    List<MyTask> tasks = taskList.map((i) => MyTask.fromJson(i)).toList();
    return TaskCategory(
      name: json['name'] ?? 'Uncategorized',
      icon: json['icon'] ?? '📝',
      tasks: tasks,
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'isHidden': isHidden,
    };
  }
}
