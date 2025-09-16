// lib/features/content_management/domain/models/point_preset_model.dart

class PointPreset {
  final int id;
  String name;

  PointPreset({required this.id, required this.name});

  factory PointPreset.fromJson(Map<String, dynamic> json) =>
      PointPreset(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
