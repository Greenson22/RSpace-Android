// lib/features/perpusku/domain/models/perpusku_models.dart

class PerpuskuTopic {
  final String name;
  final String path;
  final String icon; // ==> PROPERTI BARU DITAMBAHKAN

  PerpuskuTopic({
    required this.name,
    required this.path,
    required this.icon, // ==> TAMBAHKAN DI KONSTRUKTOR
  });
}

class PerpuskuSubject {
  final String name;
  final String path;

  PerpuskuSubject({required this.name, required this.path});
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
