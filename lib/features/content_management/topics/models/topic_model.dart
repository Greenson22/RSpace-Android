// lib/features/content_management/domain/models/topic_model.dart

class Topic {
  String name;
  String icon;
  int position;
  bool isHidden;

  Topic({
    required this.name,
    required this.icon,
    required this.position,
    this.isHidden = false,
  });

  // ==> TAMBAHKAN BLOK KODE DI BAWAH INI <==
  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      name: json['name'] as String,
      icon:
          json['icon'] as String? ?? '📁', // Beri nilai default jika icon null
      position:
          json['position'] as int? ??
          -1, // Beri nilai default jika position null
      isHidden:
          json['isHidden'] as bool? ??
          false, // Beri nilai default jika isHidden null
    );
  }

  // Fungsi toConfigJson tidak berubah
  Map<String, dynamic> toConfigJson() {
    return {'icon': icon, 'position': position, 'isHidden': isHidden};
  }
}
