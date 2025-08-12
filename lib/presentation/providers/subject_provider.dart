// lib/presentation/providers/subject_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/subject_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final String topicPath;

  SubjectProvider(this.topicPath) {
    fetchSubjects();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

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
      _allSubjects = await _subjectService.getSubjects(topicPath);
      _filteredSubjects = _allSubjects;
    } catch (e) {
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

  // ==> FUNGSI BARU UNTUK MENGUBAH URUTAN <==
  Future<void> reorderSubjects(int oldIndex, int newIndex) async {
    if (_searchQuery.isNotEmpty) return; // Cegah reorder saat mencari

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final Subject item = _allSubjects.removeAt(oldIndex);
    _allSubjects.insert(newIndex, item);

    _isLoading = true;
    notifyListeners();

    try {
      await _subjectService.saveSubjectsOrder(topicPath, _allSubjects);
    } finally {
      // Muat ulang data untuk memastikan UI sinkron dengan data yang disimpan
      await fetchSubjects();
    }
  }

  Future<void> updateSubjectIcon(String subjectName, String newIcon) async {
    await _subjectService.updateSubjectIcon(topicPath, subjectName, newIcon);
    await fetchSubjects();
  }

  Future<void> addSubject(String name) async {
    await _subjectService.addSubject(topicPath, name);
    await fetchSubjects();
  }

  Future<void> renameSubject(String oldName, String newName) async {
    await _subjectService.renameSubject(topicPath, oldName, newName);
    await fetchSubjects();
  }

  Future<void> deleteSubject(String subjectName) async {
    await _subjectService.deleteSubject(topicPath, subjectName);
    await fetchSubjects();
  }
}
