// lib/features/progress/domain/models/progress_template_model.dart

class ProgressTemplate {
  String id;
  String name;
  List<String> subMateri;

  ProgressTemplate({
    required this.id,
    required this.name,
    required this.subMateri,
  });

  factory ProgressTemplate.fromJson(Map<String, dynamic> json) {
    return ProgressTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      subMateri: List<String>.from(json['subMateri'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'subMateri': subMateri};
  }
}
