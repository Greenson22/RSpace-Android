// lib/presentation/providers/subject_provider.dart

import 'package:flutter/material.dart';
// Diubah dari local_file_service.dart ke subject_service.dart
import '../../data/services/subject_service.dart';

class SubjectProvider with ChangeNotifier {
  // Menggunakan SubjectService yang baru
  final SubjectService _subjectService = SubjectService();
  final String topicPath;

  SubjectProvider(this.topicPath) {
    fetchSubjects();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> _allSubjects = [];
  List<String> get allSubjects => _allSubjects;

  List<String> _filteredSubjects = [];
  List<String> get filteredSubjects => _filteredSubjects;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Memanggil metode dari SubjectService
      _allSubjects = await _subjectService.getSubjects(topicPath);
      _filteredSubjects = _allSubjects;
    } catch (e) {
      // Handle error jika diperlukan
      // Anda mungkin ingin menampilkan pesan error ke pengguna di sini
      debugPrint("Error fetching subjects: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filteredSubjects = _allSubjects
        .where((subject) => subject.toLowerCase().contains(_searchQuery))
        .toList();
    notifyListeners();
  }

  Future<void> addSubject(String name) async {
    await _subjectService.addSubject(topicPath, name);
    await fetchSubjects(); // Muat ulang daftar setelah menambah
  }

  Future<void> renameSubject(String oldName, String newName) async {
    await _subjectService.renameSubject(topicPath, oldName, newName);
    await fetchSubjects(); // Muat ulang daftar setelah mengubah
  }

  Future<void> deleteSubject(String subjectName) async {
    await _subjectService.deleteSubject(topicPath, subjectName);
    await fetchSubjects(); // Muat ulang daftar setelah menghapus
  }
}
