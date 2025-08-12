// lib/presentation/providers/subject_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart'; // ==> DITAMBAHKAN
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

  // ==> TIPE LIST DIUBAH <==
  List<Subject> _allSubjects = [];
  List<Subject> get allSubjects => _allSubjects;

  List<Subject> _filteredSubjects = [];
  List<Subject> get filteredSubjects => _filteredSubjects;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Memanggil metode dari SubjectService yang mengembalikan List<Subject>
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
        .where((subject) => subject.name.toLowerCase().contains(_searchQuery))
        .toList();
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK UPDATE IKON <==
  Future<void> updateSubjectIcon(String subjectName, String newIcon) async {
    await _subjectService.updateSubjectIcon(topicPath, subjectName, newIcon);
    await fetchSubjects();
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
