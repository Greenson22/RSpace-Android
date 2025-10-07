// lib/features/content_management/application/subject_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_actions.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import '../domain/models/subject_model.dart';
import '../domain/services/subject_service.dart';
import '../domain/services/encryption_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final SubjectActions _subjectActions = SubjectActions();
  final GeminiService _geminiService = GeminiService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final EncryptionService _encryptionService = EncryptionService();
  // ==> TAMBAHKAN PATH SERVICE <==
  final PathService _pathService = PathService();
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

  String _sortType = 'position';
  String get sortType => _sortType;
  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;
  List<String> _repetitionCodeSortOrder = [];
  List<String> get repetitionCodeSortOrder => _repetitionCodeSortOrder;

  List<String> _repetitionCodeDisplayOrder = [];
  List<String> get repetitionCodeDisplayOrder => _repetitionCodeDisplayOrder;

  final Set<String> _unlockedSubjects = {};
  bool isUnlocked(String subjectName) =>
      _unlockedSubjects.contains(subjectName);

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSortPreferences();
      _repetitionCodeSortOrder = await _prefsService.loadRepetitionCodeOrder();

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
    final sortPrefs = await _prefsService.loadSortPreferences();
    _sortType = sortPrefs['sortType'] ?? 'position';
    _sortAscending = sortPrefs['sortAscending'] ?? true;
  }

  // ==> FUNGSI HELPER BARU UNTUK MENGELOLA FILE HTML <==
  Future<void> _processHtmlFiles(
    Subject subject,
    String password,
    bool encrypt,
  ) async {
    for (final discussion in subject.discussions) {
      if (discussion.filePath != null && discussion.filePath!.isNotEmpty) {
        try {
          final file = await _pathService.getPerpuskuHtmlFile(
            discussion.filePath!,
          );
          if (encrypt) {
            await _encryptionService.encryptFile(file, password);
          } else {
            await _encryptionService.decryptFile(file, password);
          }
        } catch (e) {
          debugPrint("Gagal memproses file ${discussion.filePath}: $e");
          // Lanjutkan proses meskipun satu file gagal
        }
      }
    }
  }

  Future<void> lockSubject(String subjectName, String password) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.isLocked = true;
    subject.passwordHash = _encryptionService.hashPassword(password);
    subject.discussions = await _subjectService.getDiscussionsForSubject(
      topicPath,
      subjectName,
    );

    // Enkripsi file JSON dan semua file HTML terkait
    await _subjectService.saveEncryptedSubject(topicPath, subject, password);
    await _processHtmlFiles(subject, password, true); // true = encrypt

    _unlockedSubjects.remove(subjectName);
    await fetchSubjects();
  }

  Future<void> unlockSubject(String subjectName, String password) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    final passwordHash = _encryptionService.hashPassword(password);

    if (subject.passwordHash != passwordHash) {
      throw Exception('Password salah.');
    }

    // Dekripsi konten JSON dan muat diskusi
    subject.discussions = await _subjectService.getDecryptedDiscussions(
      topicPath,
      subject.name,
      password,
    );

    // Dekripsi juga semua file HTML terkait
    await _processHtmlFiles(subject, password, false); // false = decrypt

    _unlockedSubjects.add(subjectName);
    notifyListeners();
  }

  Future<void> removeLock(String subjectName, String password) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    final passwordHash = _encryptionService.hashPassword(password);

    if (subject.passwordHash != passwordHash) {
      throw Exception('Password salah.');
    }

    subject.isLocked = false;
    subject.passwordHash = null;
    subject.discussions = await _subjectService.getDecryptedDiscussions(
      topicPath,
      subject.name,
      password,
    );

    // Simpan kembali file JSON dalam keadaan tidak terenkripsi
    await _subjectService.saveDiscussionsForSubject(
      topicPath,
      subject.name,
      subject.discussions,
    );
    await _subjectService.updateSubjectMetadata(topicPath, subject);

    // Dekripsi semua file HTML terkait secara permanen
    await _processHtmlFiles(subject, password, false); // false = decrypt

    _unlockedSubjects.remove(subjectName);
    await fetchSubjects();
  }

  // ... Sisa kode provider (filter, sort, add, rename, dll) tidak berubah ...

  Future<void> applySort(String sortType, bool sortAscending) async {
    _sortType = sortType;
    _sortAscending = sortAscending;
    await _prefsService.saveSortPreferences(sortType, sortAscending);
    _filterAndSortSubjects();
  }

  Future<void> saveRepetitionCodeOrder(List<String> newOrder) async {
    _repetitionCodeSortOrder = newOrder;
    await _prefsService.saveRepetitionCodeOrder(newOrder);
    _filterAndSortSubjects();
  }

  Future<void> saveRepetitionCodeDisplayOrder(List<String> newOrder) async {
    _repetitionCodeDisplayOrder = newOrder;
    await _prefsService.saveRepetitionCodeDisplayOrder(newOrder);
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterAndSortSubjects();
  }

  void _filterAndSortSubjects() {
    List<Subject> tempSubjects;

    if (_showHiddenSubjects) {
      tempSubjects = _allSubjects;
    } else {
      tempSubjects = _allSubjects
          .where((subject) => !subject.isHidden)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempSubjects = tempSubjects
          .where((subject) => subject.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

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
          if (dateA == null) return 1;
          if (dateB == null) return -1;
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
        default:
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

  Future<void> toggleSubjectFreeze(String subjectName) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.isFrozen = !subject.isFrozen;

    if (subject.isFrozen) {
      subject.frozenDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    } else {
      if (subject.frozenDate != null) {
        try {
          final frozenDate = DateTime.parse(subject.frozenDate!);
          final now = DateTime.now();
          final difference = now.difference(frozenDate).inDays;

          if (difference != 0) {
            final discussions = await _subjectService.getDiscussionsForSubject(
              topicPath,
              subject.name,
            );
            for (var discussion in discussions) {
              _updateDate(discussion, difference);
              for (var point in discussion.points) {
                _updateDate(point, difference);
              }
            }
            await _subjectService.saveDiscussionsForSubject(
              topicPath,
              subject.name,
              discussions,
            );
          }
        } catch (e) {
          debugPrint("Error calculating date difference: $e");
        }
      }
      subject.frozenDate = null;
    }

    await _subjectService.updateSubjectMetadata(topicPath, subject);
    await fetchSubjects();
  }

  void _updateDate(dynamic item, int daysToAdd) {
    if (item.date == null) return;
    try {
      final currentDate = DateTime.parse(item.date!);
      final newDate = currentDate.add(Duration(days: daysToAdd));
      item.date = DateFormat('yyyy-MM-dd').format(newDate);
    } catch (e) {
      // Abaikan jika parsing tanggal gagal
    }
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

  Future<String> readIndexFileContent(Subject subject) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject tidak memiliki tautan.');
    }
    return await _subjectActions.readSubjectIndexFile(subject.linkedPath!);
  }

  Future<void> saveIndexFileContent(Subject subject, String content) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject tidak memiliki tautan.');
    }
    await _subjectActions.saveSubjectIndexFileContent(
      subject.linkedPath!,
      content,
    );
  }

  Future<void> editSubjectIndexFile(Subject subject) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject ini tidak memiliki tautan ke folder PerpusKu.');
    }
    await _subjectActions.openSubjectIndexFile(subject.linkedPath!);
  }

  Future<void> generateIndexFileWithAI(
    Subject subject,
    String themePrompt,
  ) async {
    if (subject.linkedPath == null || subject.linkedPath!.isEmpty) {
      throw Exception('Subject ini tidak memiliki tautan ke folder PerpusKu.');
    }
    final newHtmlContent = await _geminiService.generateHtmlTemplate(
      themePrompt,
    );

    await _subjectActions.generateAndSaveSubjectIndexFile(
      subject.linkedPath!,
      newHtmlContent,
    );
  }
}
