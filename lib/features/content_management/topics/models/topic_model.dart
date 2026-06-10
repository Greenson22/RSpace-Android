// lib/features/content_management/domain/models/topic_model.dart

class Topic {
  String name;
  String icon;
  int position;
  bool isHidden;
  bool isPerpuskuLinked; // ==> TAMBAHKAN PROPERTI BARU DI SINI

  Topic({
    required this.name,
    required this.icon,
    required this.position,
    this.isHidden = false,
    this.isPerpuskuLinked =
        true, // ==> TAMBAHKAN DI KONSTRUKTOR DENGAN DEFAULT TRUE
  });

  // ==> BLOK KODE SESUAI PERMINTAAN YANG SUDAH DIPERBARUI
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
      isPerpuskuLinked:
          json['isPerpuskuLinked'] as bool? ??
          true, // ==> BERI NILAI DEFAULT TRUE JIKA TIDAK ADA DI JSON
    );
  }

  // Fungsi toConfigJson tidak berubah (karena isPerpuskuLinked dicek dari fisik folder, bukan disimpan)
  Map<String, dynamic> toConfigJson() {
    return {'icon': icon, 'position': position, 'isHidden': isHidden};
  }
}
