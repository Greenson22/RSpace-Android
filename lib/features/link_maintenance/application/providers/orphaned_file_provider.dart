// lib/presentation/providers/orphaned_file_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/orphaned_file_model.dart';
import '../services/orphaned_file_service.dart';

class OrphanedFileProvider with ChangeNotifier {
  final OrphanedFileService _service = OrphanedFileService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<OrphanedFile> _allOrphanedFiles = [];
  // ==> TAMBAHKAN LIST BARU UNTUK HASIL FILTER <==
  List<OrphanedFile> _filteredOrphanedFiles = [];
  List<OrphanedFile> get orphanedFiles => _filteredOrphanedFiles;

  // ==> TAMBAHKAN STATE UNTUK QUERY PENCARIAN <==
  String _searchQuery = '';

  OrphanedFileProvider() {
    fetchOrphanedFiles();
  }

  Future<void> fetchOrphanedFiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allOrphanedFiles = await _service.findOrphanedFiles();
      // ==> PANGGIL FUNGSI FILTER SETELAH MENDAPATKAN DATA <==
      _filterFiles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FUNGSI BARU UNTUK MELAKUKAN PENCARIAN <==
  void search(String query) {
    _searchQuery = query;
    _filterFiles();
  }

  // ==> FUNGSI BARU UNTUK MENERAPKAN FILTER <==
  void _filterFiles() {
    if (_searchQuery.isEmpty) {
      _filteredOrphanedFiles = _allOrphanedFiles;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredOrphanedFiles = _allOrphanedFiles.where((file) {
        final title = file.title.toLowerCase();
        final path = file.relativePath.toLowerCase();
        return title.contains(query) || path.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteFile(OrphanedFile file) async {
    try {
      if (await file.fileObject.exists()) {
        await file.fileObject.delete();
        // Hapus dari kedua list
        _allOrphanedFiles.remove(file);
        _filteredOrphanedFiles.remove(file);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Gagal menghapus file: $e');
    }
  }
}
