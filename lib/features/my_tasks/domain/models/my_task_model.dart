// lib/features/my_tasks/domain/models/my_task_model.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ==> 1. Tambahkan Enum untuk Tipe Task <==
enum TaskType { simple, progress }

class MyTask {
  final String id;
  String name;
  int count; // Nilai saat ini
  String date;
  bool checked;
  int countToday;
  String lastUpdated;
  int targetCountToday;
  // ==> 2. Tambahkan Field Baru <==
  final TaskType type; // Tipe task (simple atau progress)
  int targetCount; // Target untuk 100% (hanya relevan jika type == progress)

  MyTask({
    String? id,
    required this.name,
    required this.count,
    required this.date,
    required this.checked,
    this.countToday = 0,
    String? lastUpdated,
    this.targetCountToday = 0,
    // ==> 3. Tambahkan di Konstruktor <==
    this.type = TaskType.simple, // Default ke tipe simple
    this.targetCount = 1, // Default target 1 (agar tidak error pembagian 0)
  }) : id = id ?? const Uuid().v4(),
       lastUpdated =
           lastUpdated ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ==> 4. Helper untuk menghitung persentase (CLAMP DIHAPUS) <==
  double get progressPercentage {
    if (type != TaskType.progress || targetCount <= 0) {
      return 0.0;
    }
    // Hapus .clamp(0.0, 1.0) dari sini
    return (count / targetCount);
    // Jika ingin membatasi nilai minimum 0 (tapi tidak maksimum):
    // return max(0.0, count / targetCount);
  }

  factory MyTask.fromJson(Map<String, dynamic> json) {
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastUpdatedString = json['lastUpdated'] as String? ?? todayString;

    return MyTask(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] ?? 'Untitled Task',
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
      checked: json['checked'] ?? false,
      countToday: lastUpdatedString == todayString
          ? json['countToday'] ?? 0
          : 0, // Reset countToday jika bukan hari ini
      lastUpdated: lastUpdatedString,
      targetCountToday: json['targetCountToday'] as int? ?? 0,
      // ==> 5. Baca dari JSON <==
      type: TaskType.values[json['type'] as int? ?? TaskType.simple.index],
      targetCount: json['targetCount'] as int? ?? 1, // Default 1
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'date': date,
      'checked': checked,
      'countToday': countToday,
      'lastUpdated': lastUpdated,
      'targetCountToday': targetCountToday,
      // ==> 6. Simpan ke JSON <==
      'type': type.index, // Simpan index enum
      'targetCount': targetCount,
    };
  }
}

// Class TaskCategory tidak berubah
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
