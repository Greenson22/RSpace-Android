// lib/features/notes/domain/models/note_topic_model.dart

class NoteTopic {
  String name;
  String icon;

  NoteTopic({required this.name, this.icon = '🗒️'});

  factory NoteTopic.fromJson(Map<String, dynamic> json) {
    return NoteTopic(
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '🗒️',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'icon': icon};
  }
}
