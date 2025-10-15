// lib/features/notes/domain/models/note_topic_model.dart

class NoteTopic {
  String name;
  String icon;
  // ==> PROPERTI BARU DITAMBAHKAN <==
  int position;

  NoteTopic({
    required this.name,
    this.icon = '🗒️',
    // ==> TAMBAHKAN DI KONSTRUKTOR <==
    this.position = -1,
  });

  factory NoteTopic.fromJson(Map<String, dynamic> json) {
    return NoteTopic(
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '🗒️',
      // ==> BACA DARI JSON <==
      position: json['position'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      // ==> SIMPAN KE JSON <==
      'position': position,
    };
  }
}
