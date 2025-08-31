// lib/presentation/providers/exported_discussions_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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

  List<ExportedTopic> _exportedTopics = [];
  List<ExportedTopic> get exportedTopics => _exportedTopics;

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
        _exportedTopics = [];
        _lastModified = null;
        return;
      }

      _lastModified = await _zipFile!.lastModified();

      final bytes = await _zipFile!.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final Map<String, ExportedTopic> topicsMap = {};

      for (final file in archive) {
        // Proses hanya file JSON dari direktori RSpace
        if (file.isFile &&
            file.name.startsWith('RSpace/') &&
            file.name.endsWith('.json')) {
          final pathParts = file.name.split('/');
          if (pathParts.length == 3) {
            // RSpace/TopicName/SubjectName.json
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

      _exportedTopics = topicsMap.values.toList();
      // Urutkan topik dan subjek berdasarkan abjad
      _exportedTopics.sort((a, b) => a.name.compareTo(b.name));
      for (var topic in _exportedTopics) {
        topic.subjects.sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e) {
      _error = "Gagal memuat atau membaca file arsip: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
