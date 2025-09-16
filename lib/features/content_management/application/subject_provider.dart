// lib/features/content_management/application/subject_provider.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_actions.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import '../domain/models/subject_model.dart';
import '../domain/services/subject_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final SubjectActions _subjectActions = SubjectActions();
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

  bool _showHiddenSubjects = false;
  bool get showHiddenSubjects => _showHiddenSubjects;

  // ==> STATE BARU UNTUK SORTING <==
  String _sortType = 'position'; // Default urutan manual
  String get sortType => _sortType;
  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;
  List<String> _repetitionCodeSortOrder = [];
  List<String> get repetitionCodeSortOrder => _repetitionCodeSortOrder;

  // State untuk urutan tampilan kode
  List<String> _repetitionCodeDisplayOrder = [];
  List<String> get repetitionCodeDisplayOrder => _repetitionCodeDisplayOrder;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Muat preferensi sorting subject
      await _loadSortPreferences();
      // Muat urutan bobot custom untuk sorting kode
      _repetitionCodeSortOrder = await _prefsService.loadRepetitionCodeOrder();

      // Muat urutan tampilan kustom dari penyimpanan
      _repetitionCodeDisplayOrder = await _prefsService
          .loadRepetitionCodeDisplayOrder();
      if (_repetitionCodeDisplayOrder.isEmpty) {
        _repetitionCodeDisplayOrder = List.from(kRepetitionCodes);
      }

      _allSubjects = await _subjectService.getSubjects(topicPath);
      _filterAndSortSubjects();
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      _allSubjects = [];
      _filteredSubjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSortPreferences() async {
    // Gunakan key yang berbeda untuk preferensi sort subject
    // (Untuk saat ini, kita bisa gunakan key yang sama jika ingin sinkron,
    // atau buat key baru di UserDataService jika ingin terpisah)
    final sortPrefs = await _prefsService.loadSortPreferences();
    _sortType = sortPrefs['sortType'] ?? 'position';
    _sortAscending = sortPrefs['sortAscending'] ?? true;
  }

  // ==> FUNGSI BARU UNTUK MENERAPKAN SORTING <==
  Future<void> applySort(String sortType, bool sortAscending) async {
    _sortType = sortType;
    _sortAscending = sortAscending;
    // Simpan preferensi agar diingat
    await _prefsService.saveSortPreferences(sortType, sortAscending);
    _filterAndSortSubjects();
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN URUTAN BOBOT KODE <==
  Future<void> saveRepetitionCodeOrder(List<String> newOrder) async {
    _repetitionCodeSortOrder = newOrder;
    await _prefsService.saveRepetitionCodeOrder(newOrder);
    _filterAndSortSubjects(); // Terapkan urutan baru secara langsung
  }

  // Fungsi untuk menyimpan urutan tampilan kustom
  Future<void> saveRepetitionCodeDisplayOrder(List<String> newOrder) async {
    _repetitionCodeDisplayOrder = newOrder;
    await _prefsService.saveRepetitionCodeDisplayOrder(newOrder);
    notifyListeners(); // Beri tahu UI untuk render ulang dengan urutan baru
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterAndSortSubjects();
  }

  // ==> NAMA FUNGSI DIPERBARUI DAN LOGIKA SORTING DITAMBAHKAN <==
  void _filterAndSortSubjects() {
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
      tempSubjects = tempSubjects
          .where((subject) => subject.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // 3. Terapkan Sorting
    tempSubjects.sort((a, b) {
      int result;
      switch (_sortType) {
        case 'name':
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'date':
          final dateA = a.date != null ? DateTime.tryParse(a.date!) : null;
          final dateB = b.date != null ? DateTime.tryParse(b.date!) : null;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1; // nulls last
          if (dateB == null) return -1; // nulls last
          result = dateA.compareTo(dateB);
          break;
        case 'code':
          result =
              getRepetitionCodeIndex(
                a.repetitionCode ?? '',
                customOrder: _repetitionCodeSortOrder,
              ).compareTo(
                getRepetitionCodeIndex(
                  b.repetitionCode ?? '',
                  customOrder: _repetitionCodeSortOrder,
                ),
              );
          break;
        default: // 'position'
          result = a.position.compareTo(b.position);
          break;
      }
      return result;
    });

    if (!_sortAscending) {
      _filteredSubjects = tempSubjects.reversed.toList();
    } else {
      _filteredSubjects = tempSubjects;
    }

    notifyListeners();
  }

  void toggleShowHidden() {
    _showHiddenSubjects = !_showHiddenSubjects;
    _filterAndSortSubjects();
  }

  Future<void> updateSubjectIcon(String subjectName, String newIcon) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.icon = newIcon;
    await _subjectService.updateSubjectMetadata(topicPath, subject);
    await fetchSubjects();
  }

  Future<void> updateSubjectLinkedPath(
    String subjectName,
    String? newPath,
  ) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.linkedPath = newPath;
    await _subjectService.updateSubjectMetadata(topicPath, subject);
    await fetchSubjects();
  }

  Future<void> toggleSubjectVisibility(
    String subjectName,
    bool isHidden,
  ) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.isHidden = isHidden;
    await _subjectService.updateSubjectMetadata(topicPath, subject);
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
    if (deleteLinkedFolder) {
      final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
      if (subject.linkedPath != null) {
        // Logika penghapusan folder bisa ditambahkan di SubjectActions jika diperlukan
      }
    }
    await _subjectService.deleteSubject(topicPath, subjectName);
    await fetchSubjects();
  }

  Future<void> moveSubject(Subject subject, Topic newTopic) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _subjectActions.moveSubject(subject, topicPath, newTopic);
      await fetchSubjects();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editSubjectIndexFile(Subject subject) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject ini tidak memiliki tautan ke folder PerpusKu.');
    }
    await _subjectActions.openSubjectIndexFile(subject.linkedPath!);
  }
}
