// lib/features/perpusku/domain/models/perpusku_models.dart

class PerpuskuTopic {
  final String name;
  final String path;
  final String icon;
  final int subjectCount;

  PerpuskuTopic({
    required this.name,
    required this.path,
    required this.icon,
    this.subjectCount = 0,
  });
}

class PerpuskuSubject {
  final String name;
  final String path;
  final String icon;
  // ==> NAMA PROPERTI DIPERBARUI
  final int quizCount;

  PerpuskuSubject({
    required this.name,
    required this.path,
    required this.icon,
    // ==> DIPERBARUI DI KONSTRUKTOR
    this.quizCount = 0,
  });
}

class PerpuskuFile {
  final String title;
  final String fileName;
  final String path;

  PerpuskuFile({
    required this.title,
    required this.fileName,
    required this.path,
  });
}
