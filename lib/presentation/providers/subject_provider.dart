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

  bool _showHiddenSubjects = false; // ==> DITAMBAHKAN
  bool get showHiddenSubjects => _showHiddenSubjects; // ==> DITAMBAHKAN

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
      _filterSubjects(); // DIUBAH dari search(_searchQuery)
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
    _filterSubjects();
  }

  // ==> FUNGSI BARU UNTUK MENGGABUNGKAN SEMUA LOGIKA FILTER <==
  void _filterSubjects() {
    List<Subject> tempSubjects;

    // 1. Filter berdasarkan visibilitas
    if (_showHiddenSubjects) {
      tempSubjects = _allSubjects;
    } else {
      tempSubjects = _allSubjects
          .where((subject) => !subject.isHidden)
          .toList();
    }

    // 2. Filter berdasarkan query pencarian
    if (_searchQuery.isNotEmpty) {
      _filteredSubjects = tempSubjects
          .where((subject) => subject.name.toLowerCase().contains(_searchQuery))
          .toList();
    } else {
      _filteredSubjects = tempSubjects;
    }

    notifyListeners();
  }

  // ==> FUNGSI BARU <==
  void toggleShowHidden() {
    _showHiddenSubjects = !_showHiddenSubjects;
    _filterSubjects();
  }

  Future<void> updateSubjectIcon(String subjectName, String newIcon) async {
    await _subjectService.updateSubjectIcon(topicPath, subjectName, newIcon);
    await fetchSubjects();
  }

  // ==> FUNGSI BARU <==
  Future<void> toggleSubjectVisibility(
    String subjectName,
    bool isHidden,
  ) async {
    await _subjectService.updateSubjectVisibility(
      topicPath,
      subjectName,
      isHidden,
    );
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
