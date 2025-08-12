import 'package:flutter/material.dart';
import '../../data/services/local_file_service.dart';

class SubjectProvider with ChangeNotifier {
  final LocalFileService _fileService = LocalFileService();
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
      _allSubjects = await _fileService.getSubjects(topicPath);
      _filteredSubjects = _allSubjects;
    } catch (e) {
      // Handle error jika diperlukan
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
    await _fileService.addSubject(topicPath, name);
    await fetchSubjects(); // Muat ulang daftar setelah menambah
  }

  Future<void> renameSubject(String oldName, String newName) async {
    await _fileService.renameSubject(topicPath, oldName, newName);
    await fetchSubjects(); // Muat ulang daftar setelah mengubah
  }

  Future<void> deleteSubject(String subjectName) async {
    await _fileService.deleteSubject(topicPath, subjectName);
    await fetchSubjects(); // Muat ulang daftar setelah menghapus
  }
}
