// lib/data/services/smart_link_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';
import '../models/link_suggestion_model.dart';
import 'path_service.dart';

class SmartLinkService {
  final PathService _pathService = PathService();

  // Cache sederhana untuk menyimpan data file PerpusKu agar tidak perlu memindai berulang kali.
  static List<Map<String, String>>? _perpuskuFileCache;

  Future<List<Map<String, String>>> _getAllPerpuskuFiles() async {
    if (_perpuskuFileCache != null) {
      return _perpuskuFileCache!;
    }

    final List<Map<String, String>> allFilesData = [];
    try {
      final perpuskuPath = await _pathService.perpuskuDataPath;
      final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
      final topicsDir = Directory(basePath);

      if (!await topicsDir.exists()) return [];

      final topicDirs = topicsDir.listSync().whereType<Directory>();

      for (final topicDir in topicDirs) {
        final subjectDirs = topicDir.listSync().whereType<Directory>();
        for (final subjectDir in subjectDirs) {
          final metadataFile = File(
            path.join(subjectDir.path, 'metadata.json'),
          );
          Map<String, String> currentTitles = {};
          if (await metadataFile.exists()) {
            final jsonString = await metadataFile.readAsString();
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final content = jsonData['content'] as List<dynamic>? ?? [];
            currentTitles = {
              for (var item in content)
                item['nama_file'] as String: item['judul'] as String,
            };
          }

          final htmlFiles = subjectDir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.html'),
          );

          for (final file in htmlFiles) {
            final fileName = path.basename(file.path);
            allFilesData.add({
              'title': currentTitles[fileName] ?? fileName,
              'fileName': fileName,
              'topic': path.basename(topicDir.path),
              'subject': path.basename(subjectDir.path),
              'relativePath': path.join(
                path.basename(topicDir.path),
                path.basename(subjectDir.path),
                fileName,
              ),
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error caching PerpusKu files: $e");
    }
    _perpuskuFileCache = allFilesData;
    return allFilesData;
  }

  Future<List<LinkSuggestion>> findSuggestions({
    required Discussion discussion,
    required String topicName,
    required String subjectName,
  }) async {
    final perpuskuFiles = await _getAllPerpuskuFiles();
    if (perpuskuFiles.isEmpty) return [];

    final List<LinkSuggestion> suggestions = [];
    final Set<String> discussionKeywords = _extractKeywords(discussion);
    final String discussionTitle = discussion.discussion.toLowerCase();

    for (final fileData in perpuskuFiles) {
      double score = 0;
      final String fileTitle = fileData['title']!.toLowerCase();

      // Skor 1: Kesamaan judul
      score += _calculateTitleSimilarity(discussionTitle, fileTitle) * 5;

      // Skor 2: Kata kunci dari poin ditemukan di judul file
      for (final keyword in discussionKeywords) {
        if (fileTitle.contains(keyword)) {
          score += 1.5;
        }
      }

      // Skor 3: Bonus jika nama topik/subjek cocok
      if (fileData['topic']!.toLowerCase() == topicName.toLowerCase()) {
        score += 2;
      }
      if (fileData['subject']!.toLowerCase() == subjectName.toLowerCase()) {
        score += 3;
      }

      // Hanya tambahkan jika skor lebih dari 0
      if (score > 0) {
        suggestions.add(
          LinkSuggestion(
            title: fileData['title']!,
            relativePath: fileData['relativePath']!,
            score: score,
          ),
        );
      }
    }

    // Urutkan saran dari skor tertinggi ke terendah
    suggestions.sort((a, b) => b.score.compareTo(a.score));

    // Ambil 5 saran teratas
    return suggestions.take(5).toList();
  }

  Set<String> _extractKeywords(Discussion discussion) {
    final keywords = <String>{};
    // Tambahkan kata-kata dari judul diskusi (lebih dari 3 huruf)
    discussion.discussion.toLowerCase().split(' ').forEach((word) {
      if (word.length > 3) keywords.add(word);
    });
    // Tambahkan kata-kata dari setiap poin
    for (final point in discussion.points) {
      point.pointText.toLowerCase().split(' ').forEach((word) {
        if (word.length > 4)
          keywords.add(word); // Ambil kata yang lebih panjang dari poin
      });
    }
    return keywords;
  }

  double _calculateTitleSimilarity(String titleA, String titleB) {
    final wordsA = titleA.split(' ').toSet();
    final wordsB = titleB.split(' ').toSet();
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return union == 0 ? 0 : intersection / union;
  }
}
