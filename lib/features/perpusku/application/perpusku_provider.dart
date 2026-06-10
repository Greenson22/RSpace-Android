// lib/features/perpusku/application/perpusku_provider.dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/topics/services/topic_service.dart';
import '../domain/models/perpusku_models.dart';
import '../infrastructure/perpusku_service.dart';

class PerpuskuProvider with ChangeNotifier {
  final PerpuskuService _service = PerpuskuService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // >> STATE BARU UNTUK TOGGLE <<
  bool _showHiddenTopics = false;
  bool get showHiddenTopics => _showHiddenTopics;

  List<PerpuskuTopic> _topics = [];
  List<PerpuskuTopic> get topics => _topics;

  List<PerpuskuSubject> _subjects = [];
  List<PerpuskuSubject> get subjects => _subjects;

  List<PerpuskuFile> _files = [];
  List<PerpuskuFile> get files => _files;

  List<PerpuskuFile> _searchResults = [];
  List<PerpuskuFile> get searchResults => _searchResults;

  Future<void> fetchTopics() async {
    _setLoading(true);
    // >> KIRIM STATUS TOGGLE KE SERVICE <<
    _topics = await _service.getTopics(showHidden: _showHiddenTopics);
    _setLoading(false);
  }

  // >> METODE BARU UNTUK MENGUBAH STATE DAN MEMUAT ULANG DATA <<
  void toggleShowHidden() {
    _showHiddenTopics = !_showHiddenTopics;
    fetchTopics(); // Panggil fetchTopics untuk memuat ulang dengan filter baru
  }

  Future<void> fetchSubjects(String topicPath) async {
    _setLoading(true);
    _subjects = await _service.getSubjects(topicPath);
    _setLoading(false);
  }

  Future<void> fetchFiles(String subjectPath) async {
    _setLoading(true);
    _files = await _service.getFiles(subjectPath);
    _setLoading(false);
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    _isSearching = true;
    _setLoading(true);
    _searchResults = await _service.searchAllFiles(query);
    _setLoading(false);
  }

  Future<void> searchInTopic(String topicPath, String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    _isSearching = true;
    _setLoading(true);
    _searchResults = await _service.searchFilesInTopic(topicPath, query);
    _setLoading(false);
  }

  Future<void> renameTopic(String oldName, String newName) async {
    _setLoading(true);
    try {
      // Panggil TopicService utama Anda untuk melakukan penggantian nama folder terintegrasi
      final topicService = TopicService();
      await topicService.renameTopic(oldName, newName);
      // Refresh list setelah diubah
      await fetchTopics();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTopic(
    String topicName, {
    bool deletePerpuskuFolder = true,
  }) async {
    _setLoading(true);
    try {
      final topicService = TopicService();
      await topicService.deleteTopic(
        topicName,
        deletePerpuskuFolder: deletePerpuskuFolder,
      );
      await fetchTopics();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renameSubject(
    String topicName,
    String oldName,
    String newName,
    String topicPath,
  ) async {
    _setLoading(true);
    try {
      // 1. Definisikan path folder subjek yang lama dan yang baru
      final oldSubjectPath = path.join(topicPath, oldName);
      final newSubjectPath = path.join(topicPath, newName);

      final oldDir = Directory(oldSubjectPath);
      final newDir = Directory(newSubjectPath);

      // 2. Validasi ketersediaan folder sebelum diubah
      if (await oldDir.exists()) {
        if (await newDir.exists()) {
          throw Exception('Subjek dengan nama "$newName" sudah ada.');
        }

        // 3. Eksekusi pengubahan nama folder fisik di penyimpanan lokal
        await oldDir.rename(newDir.path);
      } else {
        throw Exception('Folder subjek lama tidak ditemukan.');
      }

      // 4. Muat ulang (refresh) data list subjek dari path topik agar UI berubah
      await fetchSubjects(topicPath);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSubject(String subjectName, String topicPath) async {
    _setLoading(true);
    try {
      // 1. Definisikan path folder subjek yang akan dihapus
      final subjectFullPath = path.join(topicPath, subjectName);
      final dir = Directory(subjectFullPath);

      // 2. Eksekusi penghapusan folder beserta seluruh isinya secara rekursif
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      // 3. Muat ulang data list subjek agar UI sinkron
      await fetchSubjects(topicPath);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renameFile({
    required String subjectPath,
    required String oldFileName,
    required String newFileName,
  }) async {
    _setLoading(true);
    try {
      final oldFilePath = path.join(subjectPath, oldFileName);
      final newFilePath = path.join(subjectPath, newFileName);

      final oldFile = File(oldFilePath);
      final newFile = File(newFilePath);

      if (await oldFile.exists()) {
        if (await newFile.exists()) {
          throw Exception('File dengan nama "$newFileName" sudah ada.');
        }
        // 1. Ganti nama berkas fisik
        await oldFile.rename(newFile.path);

        // 2. Perbarui judul di dalam metadata.json jika ada
        final metadataFile = File(path.join(subjectPath, 'metadata.json'));
        if (await metadataFile.exists()) {
          final jsonString = await metadataFile.readAsString();
          if (jsonString.isNotEmpty) {
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final content = jsonData['content'] as List<dynamic>? ?? [];

            for (var item in content) {
              if (item['nama_file'] == oldFileName) {
                item['nama_file'] = newFileName;
                // Opsional: Jika ingin judul UI ikut berubah menyamai nama file baru tanpa ekstensi
                final ext = path.extension(newFileName);
                item['judul'] = path.basenameWithoutExtension(newFileName);
                break;
              }
            }
            const encoder = JsonEncoder.withIndent('  ');
            await metadataFile.writeAsString(encoder.convert(jsonData));
          }
        }
      } else {
        throw Exception('File lama tidak ditemukan.');
      }

      // 3. Muat ulang daftar file di UI
      await fetchFiles(subjectPath);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFile({
    required String subjectPath,
    required String fileName,
  }) async {
    _setLoading(true);
    try {
      final filePath = path.join(subjectPath, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        // 1. Hapus berkas fisik
        await file.delete();

        // 2. Hapus entri dari metadata.json jika ada
        final metadataFile = File(path.join(subjectPath, 'metadata.json'));
        if (await metadataFile.exists()) {
          final jsonString = await metadataFile.readAsString();
          if (jsonString.isNotEmpty) {
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final content = jsonData['content'] as List<dynamic>? ?? [];

            content.removeWhere((item) => item['nama_file'] == fileName);

            const encoder = JsonEncoder.withIndent('  ');
            await metadataFile.writeAsString(encoder.convert(jsonData));
          }
        }
      }

      // 3. Muat ulang daftar file di UI
      await fetchFiles(subjectPath);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
