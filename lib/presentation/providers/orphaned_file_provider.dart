// lib/presentation/providers/orphaned_file_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/orphaned_file_model.dart';
import '../../data/services/orphaned_file_service.dart';

class OrphanedFileProvider with ChangeNotifier {
  final OrphanedFileService _service = OrphanedFileService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<OrphanedFile> _orphanedFiles = [];
  List<OrphanedFile> get orphanedFiles => _orphanedFiles;

  OrphanedFileProvider() {
    fetchOrphanedFiles();
  }

  Future<void> fetchOrphanedFiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orphanedFiles = await _service.findOrphanedFiles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(OrphanedFile file) async {
    try {
      if (await file.fileObject.exists()) {
        await file.fileObject.delete();
        _orphanedFiles.remove(file); // Hapus dari daftar di UI
        notifyListeners();
      }
    } catch (e) {
      // Lemparkan error agar UI bisa menampilkannya
      throw Exception('Gagal menghapus file: $e');
    }
  }
}
