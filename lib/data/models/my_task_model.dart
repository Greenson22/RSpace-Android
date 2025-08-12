import 'package:flutter/material.dart';

class MyTask {
  String name;
  int count;
  String date;
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
  final String icon; // Akan berisi simbol seperti '📝', '💼', dll.
  final List<MyTask> tasks;

  TaskCategory({required this.name, required this.icon, required this.tasks});

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List;
    List<MyTask> tasks = taskList.map((i) => MyTask.fromJson(i)).toList();
    return TaskCategory(
      name: json['name'] ?? 'Uncategorized',
      icon: json['icon'] ?? '📝', // Default icon adalah simbol pensil
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
