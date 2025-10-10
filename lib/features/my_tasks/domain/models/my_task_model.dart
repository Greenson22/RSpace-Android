// lib/features/my_tasks/domain/models/my_task_model.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class MyTask {
  final String id;
  String name;
  int count;
  String date;
  bool checked;
  int countToday;
  String lastUpdated; // Menyimpan tanggal dalam format YYYY-MM-DD
  // ==> FIELD BARU DITAMBAHKAN <==
  int targetCountToday;

  MyTask({
    String? id,
    required this.name,
    required this.count,
    required this.date,
    required this.checked,
    this.countToday = 0,
    String? lastUpdated,
    this.targetCountToday = 0, // ==> TAMBAHAN DI KONSTRUKTOR
  }) : id = id ?? const Uuid().v4(),
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
      checked: json['checked'] ?? false,
      countToday: lastUpdatedString == todayString
          ? json['countToday'] ?? 0
          : 0,
      lastUpdated: lastUpdatedString,
      // ==> MEMBACA DATA DARI JSON <==
      targetCountToday: json['targetCountToday'] as int? ?? 0,
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
      // ==> MENYIMPAN DATA KE JSON <==
      'targetCountToday': targetCountToday,
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
