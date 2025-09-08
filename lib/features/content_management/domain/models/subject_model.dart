// lib/data/models/subject_model.dart
class Subject {
  String name;
  String icon;
  int position;
  String? date;
  String? repetitionCode;
  bool isHidden;
  // ==> FIELD BARU DITAMBAHKAN <==
  String? linkedPath;
  // ==> FIELD BARU UNTUK STATISTIK
  int discussionCount;
  int finishedDiscussionCount;
  Map<String, int> repetitionCodeCounts;

  Subject({
    required this.name,
    required this.icon,
    required this.position,
    this.date,
    this.repetitionCode,
    this.isHidden = false,
    this.linkedPath, // ==> TAMBAHAN DI KONSTRUKTOR
    // ==> TAMBAHAN DI KONSTRUKTOR
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.repetitionCodeCounts = const {},
  });
}
