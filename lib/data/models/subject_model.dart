// lib/data/models/subject_model.dart
class Subject {
  String name;
  String icon;
  int position;
  String? date; // DITAMBAHKAN
  String? repetitionCode; // DITAMBAHKAN

  Subject({
    required this.name,
    required this.icon,
    required this.position,
    this.date, // DIUBAH
    this.repetitionCode, // DIUBAH
  });
}
