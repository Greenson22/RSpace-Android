// lib/data/models/topic_model.dart
class Topic {
  String name;
  String icon;
  int position; // DITAMBAHKAN

  Topic({
    required this.name,
    required this.icon,
    required this.position,
  }); // DIUBAH

  // FUNGSI BARU untuk membuat JSON yang akan disimpan di file config
  Map<String, dynamic> toConfigJson() {
    return {'icon': icon, 'position': position};
  }
}
