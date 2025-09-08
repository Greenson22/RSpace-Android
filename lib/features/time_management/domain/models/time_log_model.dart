// lib/data/models/time_log_model.dart

import 'package:intl/intl.dart';

class LoggedTask {
  int id;
  String name;
  int durationMinutes;
  String? category;
  // ==> FIELD BARU DITAMBAHKAN UNTUK MENYIMPAN KONEKSI <==
  List<String> linkedTaskIds;

  LoggedTask({
    required this.id,
    required this.name,
    this.durationMinutes = 0,
    this.category,
    this.linkedTaskIds = const [], // ==> TAMBAHAN DI KONSTRUKTOR
  });

  factory LoggedTask.fromJson(Map<String, dynamic> json) => LoggedTask(
    id: json['id'] as int,
    name: json['nama'] as String,
    durationMinutes: json['durasi_menit'] as int,
    category: json['kategori'] as String?,
    // ==> MEMBACA DATA DARI JSON, DENGAN PENANGANAN NULL <==
    linkedTaskIds: json['linkedTaskIds'] != null
        ? List<String>.from(json['linkedTaskIds'])
        : [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': name,
    'durasi_menit': durationMinutes,
    'kategori': category,
    // ==> MENYIMPAN DATA KE JSON <==
    'linkedTaskIds': linkedTaskIds,
  };
}

class TimeLogEntry {
  DateTime date;
  List<LoggedTask> tasks;

  TimeLogEntry({required this.date, required this.tasks});

  factory TimeLogEntry.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List;
    List<LoggedTask> tasks = taskList
        .map((i) => LoggedTask.fromJson(i))
        .toList();
    return TimeLogEntry(
      date: DateTime.parse(json['tanggal'] as String),
      tasks: tasks,
    );
  }

  Map<String, dynamic> toJson() => {
    'tanggal': DateFormat('yyyy-MM-dd').format(date),
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };
}
