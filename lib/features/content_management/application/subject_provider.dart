// lib/presentation/providers/subject_provider.dart
import 'package:flutter/material.dart';
import '../domain/models/subject_model.dart';
import '../domain/models/topic_model.dart'; // ==> IMPORT TOPIC MODEL
import '../domain/services/subject_service.dart';
import '../presentation/discussions/utils/repetition_code_utils.dart';
import '../../../core/services/storage_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
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

  // ==> STATE BARU UNTUK URUTAN TAMPILAN KODE <==
  List<String> _repetitionCodeDisplayOrder = [];
  List<String> get repetitionCodeDisplayOrder => _repetitionCodeDisplayOrder;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners(); // PERBAIKAN: Notifikasi langsung untuk menampilkan loading indicator

    try {
      // ==> MUAT URUTAN TAMPILAN DARI PENYIMPANAN <==
      _repetitionCodeDisplayOrder = await _prefsService
          .loadRepetitionCodeDisplayOrder();
      if (_repetitionCodeDisplayOrder.isEmpty) {
        _repetitionCodeDisplayOrder = List.from(kRepetitionCodes);
      }

      _allSubjects = await _subjectService.getSubjects(topicPath);
      // Data sudah terurut dari service, cukup terapkan filter yang ada
      _filterSubjects(); // DIUBAH dari search(_searchQuery)
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      _allSubjects = [];
      _filteredSubjects = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // PERBAIKAN: Notifikasi lagi untuk menampilkan data/state kosong
    }
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN URUTAN TAMPILAN <==
  Future<void> saveRepetitionCodeDisplayOrder(List<String> newOrder) async {
    _repetitionCodeDisplayOrder = newOrder;
    await _prefsService.saveRepetitionCodeDisplayOrder(newOrder);
    notifyListeners();
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
  Future<void> updateSubjectLinkedPath(
    String subjectName,
    String? newPath,
  ) async {
    await _subjectService.updateSubjectLinkedPath(
      topicPath,
      subjectName,
      newPath,
    );
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

  Future<void> deleteSubject(
    String subjectName, {
    bool deleteLinkedFolder = false,
  }) async {
    await _subjectService.deleteSubject(
      topicPath,
      subjectName,
      deleteLinkedFolder: deleteLinkedFolder,
    );
    await fetchSubjects();
  }

  // ==> FUNGSI BARU UNTUK MEMINDAHKAN SUBJECT <==
  Future<void> moveSubject(Subject subject, Topic newTopic) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _subjectService.moveSubject(subject, topicPath, newTopic);
      // Muat ulang data setelah berhasil dipindahkan
      await fetchSubjects();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FUNGSI BARU DITAMBAHKAN DI SINI <==
  Future<void> editSubjectIndexFile(Subject subject) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject ini tidak memiliki tautan ke folder PerpusKu.');
    }
    await _subjectService.openSubjectIndexFile(subject.linkedPath!);
  }
}
