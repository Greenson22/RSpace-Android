// lib/features/content_management/application/subject_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_actions.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service_flutter_gemini.dart';
import '../domain/models/subject_model.dart';
import '../domain/services/subject_service.dart';
import '../domain/services/encryption_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

// ==> IMPORT TAMBAHAN UNTUK IMPORT/EXPORT
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();
  final SubjectActions _subjectActions = SubjectActions();
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final EncryptionService _encryptionService = EncryptionService();
  final PathService _pathService = PathService();
  final String topicPath;

  SubjectProvider(this.topicPath);

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

  final Set<Subject> _selectedSubjects = {};
  Set<Subject> get selectedSubjects => _selectedSubjects;
  bool get isSelectionMode => _selectedSubjects.isNotEmpty;

  // ==> FITUR IMPORT BULK SUBJECTS FROM ZIP (BARU) <==
  Future<String?> importBulkSubjectsZip() async {
    try {
      // 1. Pilih File ZIP
      final isLinux = Platform.isLinux;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: isLinux ? FileType.any : FileType.custom,
        allowedExtensions: isLinux ? null : ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return null;

      _isLoading = true;
      notifyListeners();

      final zipFile = File(result.files.single.path!);

      // Buat direktori sementara untuk ekstraksi
      final tempDir = await Directory.systemTemp.createTemp('rspace_import_');

      try {
        // 2. Ekstrak ZIP
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Ekstrak konten ke folder temp
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            final f = File(path.join(tempDir.path, filename));
            await f.parent.create(recursive: true);
            await f.writeAsBytes(data);
          } else {
            await Directory(
              path.join(tempDir.path, filename),
            ).create(recursive: true);
          }
        }

        int successCount = 0;
        final perpuskuBasePath = await _pathService.perpuskuDataPath;

        // 3. Iterasi setiap folder yang diekstrak
        // Struktur ZIP Export biasanya: RootFolder/NamaSubject/Subject.json
        final List<FileSystemEntity> entities = tempDir.listSync();

        for (var entity in entities) {
          // Kita hanya memproses Direktori (yang merepresentasikan satu Subject)
          if (entity is Directory) {
            final subjectDir = entity;
            File? jsonFile;
            Directory? perpuskuDataDir;

            // Cari file JSON dan folder PerpusKu_Data di dalam folder subject tersebut
            final subEntities = subjectDir.listSync();
            for (var sub in subEntities) {
              if (sub is File && sub.path.toLowerCase().endsWith('.json')) {
                jsonFile = sub;
              } else if (sub is Directory &&
                  path.basename(sub.path) == 'PerpusKu_Data') {
                perpuskuDataDir = sub;
              }
            }

            // Proses jika ditemukan file JSON yang valid
            if (jsonFile != null) {
              try {
                // A. Baca Metadata JSON untuk mendapatkan linkedPath
                // Kita perlu tahu path folder PerpusKu SEBELUM import, karena
                // linkedPath tidak berubah meskipun nama file subject berubah.
                final jsonString = await jsonFile.readAsString();
                final jsonData = jsonDecode(jsonString);
                final metadata = jsonData['metadata'] as Map<String, dynamic>?;
                final String? linkedPath = metadata?['linkedPath'];

                // B. Import Subject (JSON)
                // Service akan menangani duplikasi nama file
                await _subjectService.importSubject(topicPath, jsonFile);

                // C. Restore Data PerpusKu (Jika ada di ZIP dan subject memiliki link)
                if (perpuskuDataDir != null &&
                    linkedPath != null &&
                    linkedPath.isNotEmpty) {
                  final targetPath = path.join(
                    perpuskuBasePath,
                    'file_contents',
                    'topics',
                    linkedPath,
                  );
                  final targetDir = Directory(targetPath);

                  // Buat direktori tujuan jika belum ada
                  if (!await targetDir.exists()) {
                    await targetDir.create(recursive: true);
                  }

                  // Copy isi folder PerpusKu_Data ke tujuan
                  await _copyDirectory(perpuskuDataDir, targetDir);
                }

                successCount++;
              } catch (e) {
                debugPrint("Gagal mengimpor item dari ${subjectDir.path}: $e");
              }
            }
          }
        }

        await fetchSubjects();
        return "Berhasil mengimpor $successCount subject.";
      } finally {
        // Bersihkan folder temp setelah selesai
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint("Gagal membersihkan temp import: $e");
        }
      }
    } catch (e) {
      debugPrint("Error import bulk zip: $e");
      return "Terjadi kesalahan saat mengimpor: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FITUR EXPORT SINGLE SUBJECT TO ZIP
  Future<String?> exportSubjectZip(
    Subject subject,
    String zipFileName,
    bool includePerpusku,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Siapkan folder temporary
      final tempDir = await Directory.systemTemp.createTemp('rspace_export_');
      final exportFolder = Directory(path.join(tempDir.path, subject.name));
      await exportFolder.create();

      // 2. Salin file JSON Subject
      final subjectJsonPath = await _pathService.getSubjectPath(
        topicPath,
        subject.name,
      );
      final sourceJsonFile = File(subjectJsonPath);
      if (await sourceJsonFile.exists()) {
        await sourceJsonFile.copy(
          path.join(exportFolder.path, '${subject.name}.json'),
        );
      } else {
        throw Exception("File subject asli tidak ditemukan.");
      }

      // 3. Salin folder PerpusKu jika diminta dan tersedia
      if (includePerpusku &&
          subject.linkedPath != null &&
          subject.linkedPath!.isNotEmpty) {
        final perpuskuBasePath = await _pathService.perpuskuDataPath;
        final perpuskuSourcePath = path.join(
          perpuskuBasePath,
          'file_contents',
          'topics',
          subject.linkedPath,
        );

        final sourceDir = Directory(perpuskuSourcePath);
        if (await sourceDir.exists()) {
          final perpuskuDestFolder = Directory(
            path.join(exportFolder.path, 'PerpusKu_Data'),
          );
          await perpuskuDestFolder.create();
          await _copyDirectory(sourceDir, perpuskuDestFolder);
        }
      }

      // 4. Proses Zipping
      final zipPath = path.join(tempDir.path, '$zipFileName.zip');
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(exportFolder);
      encoder.close();

      final zipFile = File(zipPath);

      // 5. Output berdasarkan Platform
      String? returnMessage;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Desktop: Pilih folder penyimpanan
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih Folder Simpan Zip',
        );

        if (selectedDirectory != null) {
          final finalPath = path.join(selectedDirectory, '$zipFileName.zip');
          await zipFile.copy(finalPath);
          returnMessage = "Export berhasil disimpan di: $finalPath";
        }
      } else {
        // Mobile: Share Sheet
        await Share.shareXFiles([
          XFile(zipPath),
        ], text: 'Export Subject: ${subject.name}');
      }

      // Bersihkan temp
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint("Gagal membersihkan temp: $e");
      }

      return returnMessage;
    } catch (e) {
      debugPrint("Error export zip: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FITUR EXPORT BULK SUBJECTS TO ZIP
  Future<String?> exportBulkSubjectsZip(
    String zipFileName,
    bool includePerpusku,
  ) async {
    if (_selectedSubjects.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Siapkan folder temporary dan Root Folder Export
      final tempDir = await Directory.systemTemp.createTemp(
        'rspace_bulk_export_',
      );
      final rootExportFolder = Directory(path.join(tempDir.path, zipFileName));
      await rootExportFolder.create();

      // 2. Loop setiap subject yang dipilih
      for (var subject in _selectedSubjects) {
        // Buat folder khusus untuk subject ini: Root/NamaSubject
        final subjectFolder = Directory(
          path.join(rootExportFolder.path, subject.name),
        );
        await subjectFolder.create();

        // A. Salin file JSON Subject
        final subjectJsonPath = await _pathService.getSubjectPath(
          topicPath,
          subject.name,
        );
        final sourceJsonFile = File(subjectJsonPath);
        if (await sourceJsonFile.exists()) {
          await sourceJsonFile.copy(
            path.join(subjectFolder.path, '${subject.name}.json'),
          );
        }

        // B. Salin folder PerpusKu jika diminta dan tersedia untuk subject ini
        if (includePerpusku &&
            subject.linkedPath != null &&
            subject.linkedPath!.isNotEmpty) {
          final perpuskuBasePath = await _pathService.perpuskuDataPath;
          final perpuskuSourcePath = path.join(
            perpuskuBasePath,
            'file_contents',
            'topics',
            subject.linkedPath,
          );

          final sourceDir = Directory(perpuskuSourcePath);
          if (await sourceDir.exists()) {
            final perpuskuDestFolder = Directory(
              path.join(subjectFolder.path, 'PerpusKu_Data'),
            );
            await perpuskuDestFolder.create();
            await _copyDirectory(sourceDir, perpuskuDestFolder);
          }
        }
      }

      // 3. Proses Zipping Folder Root
      final zipPath = path.join(tempDir.path, '$zipFileName.zip');
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(rootExportFolder);
      encoder.close();

      final zipFile = File(zipPath);

      // 4. Output berdasarkan Platform
      String? returnMessage;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Desktop: Pilih folder penyimpanan
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih Folder Simpan Zip',
        );

        if (selectedDirectory != null) {
          final finalPath = path.join(selectedDirectory, '$zipFileName.zip');
          await zipFile.copy(finalPath);
          returnMessage =
              "Export $zipFileName.zip berhasil disimpan di: $finalPath";
        }
      } else {
        // Mobile: Share Sheet
        await Share.shareXFiles([
          XFile(zipPath),
        ], text: 'Export Bulk Subjects: $zipFileName');
      }

      // Bersihkan temp
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint("Gagal membersihkan temp: $e");
      }

      // Bersihkan seleksi setelah selesai
      clearSelection();

      return returnMessage;
    } catch (e) {
      debugPrint("Error export bulk zip: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk menyalin folder secara rekursif
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory(
          path.join(destination.path, path.basename(entity.path)),
        );
        await newDir.create();
        await _copyDirectory(entity, newDir);
      } else if (entity is File) {
        await entity.copy(
          path.join(destination.path, path.basename(entity.path)),
        );
      }
    }
  }

  Future<String> getRawJsonContent(Subject subject) async {
    final subjectPath = await _pathService.getSubjectPath(
      topicPath,
      subject.name,
    );
    final file = File(subjectPath);

    if (subject.isLocked) {
      return 'Konten dienkripsi. Buka kunci subjek terlebih dahulu untuk melihatnya.';
    }

    try {
      final rawContent = await file.readAsString();
      final jsonObject = jsonDecode(rawContent);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return 'Gagal memformat JSON: $e';
    }
  }

  void toggleSubjectSelection(Subject subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
  }

  void selectAllFilteredSubjects() {
    _selectedSubjects.addAll(_filteredSubjects);
    notifyListeners();
  }

  void clearSelection() {
    _selectedSubjects.clear();
    notifyListeners();
  }

  Future<void> toggleFreezeSelectedSubjects() async {
    for (final subject in _selectedSubjects) {
      await toggleSubjectFreeze(subject.name, isBulkAction: true);
    }
    clearSelection();
    await fetchSubjects();
  }

  Future<void> toggleVisibilitySelectedSubjects() async {
    for (final subject in _selectedSubjects) {
      await toggleSubjectVisibility(
        subject.name,
        !subject.isHidden,
        isBulkAction: true,
      );
    }
    clearSelection();
    await fetchSubjects();
  }

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

  Future<void> _processHtmlFiles(
    Subject subject,
    String password,
    bool encrypt,
  ) async {
    for (final discussion in subject.discussions) {
      if (discussion.filePath != null && discussion.filePath!.isNotEmpty) {
        try {
          final file = await _pathService.getHtmlFile(discussion.filePath!);
          if (encrypt) {
            await _encryptionService.encryptFile(file, password);
          } else {
            await _encryptionService.decryptFile(file, password);
          }
        } catch (e) {
          debugPrint("Gagal memproses file ${discussion.filePath}: $e");
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

    await _subjectService.saveEncryptedSubject(topicPath, subject, password);
    await _processHtmlFiles(subject, password, true);

    _unlockedSubjects.remove(subjectName);
    await fetchSubjects();
  }

  Future<void> unlockSubject(String subjectName, String password) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    final passwordHash = _encryptionService.hashPassword(password);

    if (subject.passwordHash != passwordHash) {
      throw Exception('Password salah.');
    }

    subject.discussions = await _subjectService.getDecryptedDiscussions(
      topicPath,
      subject.name,
      password,
    );

    await _processHtmlFiles(subject, password, false);

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

    await _subjectService.saveDiscussionsForSubject(
      topicPath,
      subject.name,
      subject.discussions,
    );
    await _subjectService.updateSubjectMetadata(topicPath, subject);

    await _processHtmlFiles(subject, password, false);

    _unlockedSubjects.remove(subjectName);
    await fetchSubjects();
  }

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
    bool isHidden, {
    bool isBulkAction = false,
  }) async {
    final subject = _allSubjects.firstWhere((s) => s.name == subjectName);
    subject.isHidden = isHidden;
    await _subjectService.updateSubjectMetadata(topicPath, subject);
    if (!isBulkAction) {
      await fetchSubjects();
    }
  }

  Future<void> toggleSubjectFreeze(
    String subjectName, {
    bool isBulkAction = false,
  }) async {
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
    if (!isBulkAction) {
      await fetchSubjects();
    }
  }

  void _updateDate(dynamic item, int daysToAdd) {
    if (item.date == null) return;
    try {
      final currentDate = DateTime.parse(item.date!);
      final newDate = currentDate.add(Duration(days: daysToAdd));
      item.date = DateFormat('yyyy-MM-dd').format(newDate);
    } catch (e) {
      // Abaikan
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
      // Logika penghapusan folder
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
