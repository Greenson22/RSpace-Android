// lib/features/my_tasks/domain/models/my_task_model.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class MyTask {
  final String id;
  String name;
  int count;
  String date;
  bool checked;
  // ==> PERUBAHAN DI SINI <==
  int countToday;
  String lastUpdated; // Menyimpan tanggal dalam format YYYY-MM-DD

  MyTask({
    String? id,
    required this.name,
    required this.count,
    required this.date,
    required this.checked,
    // ==> PERUBAHAN DI SINI <==
    this.countToday = 0,
    String? lastUpdated,
  }) : id = id ?? const Uuid().v4(),
       // Set lastUpdated ke hari ini jika tidak ada nilai
       lastUpdated =
           lastUpdated ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

  factory MyTask.fromJson(Map<String, dynamic> json) {
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastUpdatedString = json['lastUpdated'] as String? ?? todayString;

    return MyTask(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] ?? 'Untitled Task',
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
      checked:
          json['checked'] ?? false, // Tetap ada untuk kompatibilitas data lama
      // ==> PERUBAHAN DI SINI <==
      // Jika tanggal update terakhir bukan hari ini, reset countToday
      countToday: lastUpdatedString == todayString
          ? json['countToday'] ?? 0
          : 0,
      lastUpdated: lastUpdatedString,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'date': date,
      'checked': checked, // Tetap disimpan untuk kompatibilitas data lama
      // ==> PERUBAHAN DI SINI <==
      'countToday': countToday,
      'lastUpdated': lastUpdated,
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
