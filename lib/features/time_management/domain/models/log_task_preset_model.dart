// lib/data/models/log_task_preset_model.dart

class LogTaskPreset {
  int id;
  String name;

  LogTaskPreset({required this.id, required this.name});

  factory LogTaskPreset.fromJson(Map<String, dynamic> json) =>
      LogTaskPreset(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
