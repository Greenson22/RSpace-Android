// lib/features/perpusku/domain/models/perpusku_models.dart

class PerpuskuTopic {
  final String name;
  final String path;
  final String icon;

  PerpuskuTopic({required this.name, required this.path, required this.icon});
}

class PerpuskuSubject {
  final String name;
  final String path;
  final String icon; // ==> PROPERTI BARU DITAMBAHKAN

  PerpuskuSubject({
    required this.name,
    required this.path,
    required this.icon, // ==> TAMBAHKAN DI KONSTRUKTOR
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
