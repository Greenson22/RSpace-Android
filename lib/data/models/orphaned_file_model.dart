// lib/data/models/orphaned_file_model.dart

import 'dart:io';

class OrphanedFile {
  final String title;
  final String relativePath;
  final File fileObject; // Objek file untuk tindakan seperti penghapusan

  OrphanedFile({
    required this.title,
    required this.relativePath,
    required this.fileObject,
  });
}
