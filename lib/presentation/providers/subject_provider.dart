import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/subject_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final String topicPath;

  SubjectProvider(this.topicPath) {
    // fetchSubjects dipanggil dari initState di halaman UI
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });

    try {
      _allSubjects = await _subjectService.getSubjects(topicPath);
      // Data sudah terurut dari service, cukup terapkan filter yang ada
      search(_searchQuery);
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      _allSubjects = [];
      _filteredSubjects = [];
    } finally {
      _isLoading = false;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filteredSubjects = _allSubjects
        .where((subject) => subject.name.toLowerCase().contains(_searchQuery))
        .toList();
    notifyListeners();
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
