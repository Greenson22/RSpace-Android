// lib/features/perpusku/domain/models/perpusku_models.dart

class PerpuskuTopic {
  final String name;
  final String path;
  final String icon;
  final int subjectCount; // ==> PROPERTI BARU DITAMBAHKAN

  PerpuskuTopic({
    required this.name,
    required this.path,
    required this.icon,
    this.subjectCount = 0, // ==> TAMBAHKAN DI KONSTRUKTOR
  });
}

class PerpuskuSubject {
  final String name;
  final String path;
  final String icon;
  final int totalQuestions; // ==> PROPERTI BARU DITAMBAHKAN

  PerpuskuSubject({
    required this.name,
    required this.path,
    required this.icon,
    this.totalQuestions = 0, // ==> TAMBAHKAN DI KONSTRUKTOR
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
