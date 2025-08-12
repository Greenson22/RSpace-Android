import 'package:flutter/material.dart';

// Menangani konversi nama ikon string menjadi data ikon
IconData getIconData(String iconName) {
  switch (iconName) {
    case 'work':
      return Icons.work;
    case 'home':
      return Icons.home;
    case 'shopping':
      return Icons.shopping_cart;
    default:
      return Icons.task;
  }
}

class MyTask {
  String name;
  int count; // ==> Diubah dari final
  String date; // ==> Diubah dari final
  bool checked;

  MyTask({
    required this.name,
    required this.count,
    required this.date,
    required this.checked,
  });

  factory MyTask.fromJson(Map<String, dynamic> json) {
    return MyTask(
      name: json['name'] ?? 'Untitled Task',
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
      checked: json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'count': count, 'date': date, 'checked': checked};
  }
}

class TaskCategory {
  final String name;
  final String icon;
  final List<MyTask> tasks;

  TaskCategory({required this.name, required this.icon, required this.tasks});

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List;
    List<MyTask> tasks = taskList.map((i) => MyTask.fromJson(i)).toList();
    return TaskCategory(
      name: json['name'] ?? 'Uncategorized',
      icon: json['icon'] ?? 'task',
      tasks: tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }
}
