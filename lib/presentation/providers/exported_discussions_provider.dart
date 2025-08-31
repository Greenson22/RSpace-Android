// lib/presentation/providers/exported_discussions_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/models/discussion_model.dart';
import '../../data/models/exported_discussion_model.dart';
import '../../data/services/path_service.dart';

class ExportedDiscussionsProvider with ChangeNotifier {
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  File? _zipFile;
  File? get zipFile => _zipFile;

  DateTime? _lastModified;
  DateTime? get lastModified => _lastModified;

  List<ExportedTopic> _allExportedTopics = []; // Simpan data asli
  List<ExportedTopic> _exportedTopics = []; // Data yang akan ditampilkan
  List<ExportedTopic> get exportedTopics => _exportedTopics;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  ExportedDiscussionsProvider() {
    loadExportedData();
  }

  Future<void> loadExportedData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exportPath = await _pathService.finishedDiscussionsExportPath;
      final zipFilePath = path.join(
        exportPath,
        'Export-Finished-Discussions.zip',
      );
      _zipFile = File(zipFilePath);

      if (!await _zipFile!.exists()) {
        _allExportedTopics = [];
        _exportedTopics = [];
        _lastModified = null;
        return;
      }

      _lastModified = await _zipFile!.lastModified();

      final bytes = await _zipFile!.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final Map<String, ExportedTopic> topicsMap = {};

      for (final file in archive) {
        if (file.isFile &&
            file.name.startsWith('RSpace/') &&
            file.name.endsWith('.json')) {
          final pathParts = file.name.split('/');
          if (pathParts.length == 3) {
            final topicName = pathParts[1];
            final subjectName = path.basenameWithoutExtension(pathParts[2]);

            final content = utf8.decode(file.content as List<int>);
            final jsonData = jsonDecode(content) as Map<String, dynamic>;
            final discussions = (jsonData['content'] as List)
                .map((item) => Discussion.fromJson(item))
                .toList();

            if (!topicsMap.containsKey(topicName)) {
              topicsMap[topicName] = ExportedTopic(
                name: topicName,
                subjects: [],
              );
            }

            topicsMap[topicName]!.subjects.add(
              ExportedSubject(name: subjectName, discussions: discussions),
            );
          }
        }
      }

      for (final file in archive) {
        if (file.isFile &&
            file.name.startsWith('PerpusKu/') &&
            file.name.endsWith('.html')) {
          final pathParts = file.name.split('/');
          if (pathParts.length == 4) {
            final topicName = pathParts[1];
            final subjectName = pathParts[2];
            final fileName = pathParts[3];

            final topic = topicsMap[topicName];
            if (topic != null) {
              try {
                final subject = topic.subjects.firstWhere(
                  (s) => s.name == subjectName,
                );
                final discussion = subject.discussions.firstWhere(
                  (d) =>
                      d.filePath != null &&
                      path.basename(d.filePath!) == fileName,
                );

                discussion.archivedHtmlContent = utf8.decode(
                  file.content as List<int>,
                );
              } catch (e) {
                // Abaikan jika tidak ada subjek atau diskusi yang cocok
              }
            }
          }
        }
      }

      _allExportedTopics = topicsMap.values.toList();
      _allExportedTopics.sort((a, b) => a.name.compareTo(b.name));
      for (var topic in _allExportedTopics) {
        topic.subjects.sort((a, b) => a.name.compareTo(b.name));
      }

      _filterExportedData(); // Terapkan filter awal (tanpa query)
    } catch (e) {
      _error = "Gagal memuat atau membaca file arsip: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // >> BARU: Metode untuk melakukan pencarian
  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterExportedData();
  }

  // >> BARU: Metode untuk memfilter data
  void _filterExportedData() {
    if (_searchQuery.isEmpty) {
      _exportedTopics = List.from(_allExportedTopics);
    } else {
      final List<ExportedTopic> filteredTopics = [];
      for (final topic in _allExportedTopics) {
        final List<ExportedSubject> filteredSubjects = [];
        for (final subject in topic.subjects) {
          final List<Discussion> filteredDiscussions = subject.discussions
              .where((d) => d.discussion.toLowerCase().contains(_searchQuery))
              .toList();

          // Sertakan subjek jika nama subjek cocok ATAU ada diskusi yang cocok di dalamnya
          if (subject.name.toLowerCase().contains(_searchQuery) ||
              filteredDiscussions.isNotEmpty) {
            filteredSubjects.add(
              ExportedSubject(
                name: subject.name,
                discussions: filteredDiscussions.isNotEmpty
                    ? filteredDiscussions
                    : subject
                          .discussions, // Tampilkan semua diskusi jika nama subjek cocok
              ),
            );
          }
        }

        // Sertakan topik jika nama topik cocok ATAU ada subjek yang cocok di dalamnya
        if (topic.name.toLowerCase().contains(_searchQuery) ||
            filteredSubjects.isNotEmpty) {
          filteredTopics.add(
            ExportedTopic(
              name: topic.name,
              subjects: filteredSubjects.isNotEmpty
                  ? filteredSubjects
                  : topic
                        .subjects, // Tampilkan semua subjek jika nama topik cocok
            ),
          );
        }
      }
      _exportedTopics = filteredTopics;
    }
    notifyListeners();
  }

  Future<void> openArchivedHtml(Discussion discussion) async {
    if (discussion.archivedHtmlContent == null) {
      throw Exception(
        "Konten HTML untuk diskusi ini tidak ditemukan di dalam arsip.",
      );
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      path.join(tempDir.path, '${discussion.discussion}.html'),
    );
    await tempFile.writeAsString(discussion.archivedHtmlContent!);

    final result = await OpenFile.open(tempFile.path);
    if (result.type != ResultType.done) {
      throw Exception("Tidak dapat membuka file: ${result.message}");
    }
  }
}
