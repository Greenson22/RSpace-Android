// lib/presentation/providers/mixins/discussion_actions_mixin.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/discussion_model.dart';
import '../../domain/services/discussion_service.dart';
import '../../../../data/services/path_service.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';

mixin DiscussionActionsMixin on ChangeNotifier {
  // DEPENDENCIES
  DiscussionService get discussionService;
  PathService get pathService;
  String? get sourceSubjectLinkedPath;
  List<Discussion> get allDiscussions;
  set allDiscussions(List<Discussion> value);
  List<Discussion> get filteredDiscussions;
  Set<Discussion> get selectedDiscussions;

  // ABSTRACT METHODS TO BE IMPLEMENTED BY THE MAIN PROVIDER
  void filterAndSortDiscussions();
  Future<void> saveDiscussions();
  void internalNotifyListeners(); // Helper to call notifyListeners()

  // PROPERTIES
  List<String> get repetitionCodes => kRepetitionCodes;

  // SELECTION ACTIONS
  void toggleSelection(Discussion discussion) {
    if (selectedDiscussions.contains(discussion)) {
      selectedDiscussions.remove(discussion);
    } else {
      selectedDiscussions.add(discussion);
    }
    internalNotifyListeners();
  }

  void selectAllFiltered() {
    selectedDiscussions.addAll(filteredDiscussions);
    internalNotifyListeners();
  }

  void clearSelection() {
    selectedDiscussions.clear();
    internalNotifyListeners();
  }

  // LIFECYCLE & METADATA ACTIONS
  void renameDiscussion(Discussion discussion, String newName) {
    discussion.discussion = newName;
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void updateDiscussionDate(Discussion discussion, DateTime newDate) {
    discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
    if (discussion.finished) {
      discussion.finished = false;
      discussion.finish_date = null;
      if (discussion.repetitionCode == 'Finish') {
        discussion.repetitionCode = 'R0D';
      }
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void updateDiscussionCode(Discussion discussion, String newCode) {
    discussion.repetitionCode = newCode;
    if (newCode != 'Finish') {
      discussion.date = getNewDateForRepetitionCode(newCode);
      if (discussion.finished) {
        discussion.finished = false;
        discussion.finish_date = null;
      }
    } else {
      markAsFinished(discussion);
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void markAsFinished(Discussion discussion) {
    discussion.finished = true;
    discussion.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void reactivateDiscussion(Discussion discussion) {
    discussion.finished = false;
    discussion.finish_date = null;
    discussion.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    discussion.repetitionCode = 'R0D';
    filterAndSortDiscussions();
    saveDiscussions();
  }

  // POINT ACTIONS
  void renamePoint(Point point, String newName) {
    point.pointText = newName;
    internalNotifyListeners();
    saveDiscussions();
  }

  void updatePointDate(Point point, DateTime newDate) {
    point.date = DateFormat('yyyy-MM-dd').format(newDate);
    if (point.finished) {
      point.finished = false;
      point.finish_date = null;
      if (point.repetitionCode == 'Finish') point.repetitionCode = 'R0D';
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void updatePointCode(Point point, String newCode) {
    point.repetitionCode = newCode;
    if (newCode != 'Finish') {
      point.date = getNewDateForRepetitionCode(newCode);
      if (point.finished) {
        point.finished = false;
        point.finish_date = null;
      }
    } else {
      markPointAsFinished(point);
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  void markPointAsFinished(Point point) {
    point.finished = true;
    point.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if parent discussion should be marked as finished
    final parent = allDiscussions.firstWhere((d) => d.points.contains(point));
    if (parent.points.every((p) => p.finished)) {
      markAsFinished(parent);
    } else {
      filterAndSortDiscussions();
      saveDiscussions();
    }
  }

  void reactivatePoint(Point point) {
    point.finished = false;
    point.finish_date = null;
    point.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    point.repetitionCode = 'R0D';

    // Check if parent discussion should be reactivated
    final parent = allDiscussions.firstWhere((d) => d.points.contains(point));
    if (parent.finished) {
      reactivateDiscussion(parent);
    } else {
      filterAndSortDiscussions();
      saveDiscussions();
    }
  }

  void incrementRepetitionCode(dynamic item) {
    String currentCode = item is Discussion
        ? item.repetitionCode
        : (item as Point).repetitionCode;
    final currentIndex = getRepetitionCodeIndex(currentCode);
    if (currentIndex < repetitionCodes.length - 1) {
      final newCode = repetitionCodes[currentIndex + 1];
      if (item is Discussion) updateDiscussionCode(item, newCode);
      if (item is Point) updatePointCode(item, newCode);
    }
  }

  // FILE & MOVE ACTIONS
  Future<String> getPerpuskuHtmlBasePath() async {
    final perpuskuPath = await pathService.perpuskuDataPath;
    return path.join(perpuskuPath, 'file_contents', 'topics');
  }

  Future<void> updateDiscussionFilePath(
    Discussion discussion,
    String filePath,
  ) async {
    discussion.filePath = filePath;
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  Future<void> removeDiscussionFilePath(Discussion discussion) async {
    discussion.filePath = null;
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  Future<String> moveSelectedDiscussions(
    String targetSubjectJsonPath,
    String? targetSubjectLinkedPath,
  ) async {
    final log = StringBuffer();
    final toMove = selectedDiscussions.toList();
    final perpuskuBasePath = await getPerpuskuHtmlBasePath();

    log.writeln('${toMove.length} item akan dipindahkan:');
    log.writeln('--------------------');

    for (final discussion in toMove) {
      log.writeln('Memindahkan: "${discussion.discussion}"');
      if (discussion.filePath != null && discussion.filePath!.isNotEmpty) {
        if (sourceSubjectLinkedPath != null &&
            targetSubjectLinkedPath != null) {
          try {
            final newPath = await discussionService.moveDiscussionFile(
              perpuskuBasePath: perpuskuBasePath,
              sourceDiscussionFilePath: discussion.filePath!,
              targetSubjectLinkedPath: targetSubjectLinkedPath,
            );
            discussion.filePath = newPath;
            log.writeln(
              '  > File HTML dipindahkan ke "$targetSubjectLinkedPath".',
            );
          } catch (e) {
            log.writeln('  > GAGAL memindahkan file HTML: $e');
          }
        } else {
          log.writeln(
            '  > File HTML tidak dipindahkan (sumber/tujuan tidak tertaut).',
          );
        }
      }
    }

    try {
      await discussionService.addDiscussions(targetSubjectJsonPath, toMove);
      log.writeln('--------------------');
      log.writeln('Berhasil memindahkan data ${toMove.length} diskusi.');

      allDiscussions.removeWhere((d) => selectedDiscussions.contains(d));
      selectedDiscussions.clear();
      filterAndSortDiscussions();
      await saveDiscussions();
    } catch (e) {
      log.writeln('--------------------');
      log.writeln('GAGAL memindahkan data diskusi: $e');
      rethrow;
    }

    return log.toString();
  }

  Future<void> createAndLinkHtmlFile(
    Discussion discussion,
    String subjectLinkedPath,
  ) async {
    final newRelativePath = await discussionService.createDiscussionFile(
      perpuskuBasePath: await getPerpuskuHtmlBasePath(),
      subjectLinkedPath: subjectLinkedPath,
      discussionName: discussion.discussion,
    );
    discussion.filePath = newRelativePath;
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  Future<void> writeHtmlToFile(String relativePath, String htmlContent) async {
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, relativePath);
    final file = File(fullPath);
    if (!await file.exists()) throw Exception("File target tidak ditemukan.");
    await file.writeAsString(htmlContent);
  }

  Future<void> openDiscussionFile(Discussion discussion) async {
    if (discussion.filePath == null) throw Exception('Tidak ada path file.');
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final contentPath = path.join(basePath, discussion.filePath!);
    final subjectPath = path.dirname(contentPath);
    final indexPath = path.join(subjectPath, 'index.html');

    if (!await File(contentPath).exists() || !await File(indexPath).exists()) {
      throw Exception('File konten atau index.html tidak ditemukan.');
    }

    final contentHtml = await File(contentPath).readAsString();
    final indexHtml = await File(indexPath).readAsString();
    final indexDoc = parse(indexHtml);
    final container = indexDoc.querySelector('#main-container');
    if (container == null) throw Exception('#main-container tidak ditemukan.');

    final contentDoc = parse(contentHtml);
    final images = contentDoc.querySelectorAll('img');
    for (var img in images) {
      final src = img.attributes['src'];
      if (src != null && !src.startsWith('http')) {
        final imgPath = path.join(subjectPath, src);
        if (await File(imgPath).exists()) {
          final bytes = await File(imgPath).readAsBytes();
          final mime = lookupMimeType(imgPath) ?? 'image/png';
          img.attributes['src'] = 'data:$mime;base64,${base64Encode(bytes)}';
        }
      }
    }
    container.innerHtml = contentDoc.body?.innerHtml ?? '';

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.html'),
    );
    await tempFile.writeAsString(indexDoc.outerHtml);

    final result = await OpenFile.open(tempFile.path);
    if (result.type != ResultType.done) throw Exception(result.message);
  }

  Future<void> editDiscussionFile(Discussion discussion) async {
    if (discussion.filePath == null) throw Exception('Tidak ada path file.');
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final contentPath = path.join(basePath, discussion.filePath!);

    if (!await File(contentPath).exists())
      throw Exception('File tidak ditemukan.');

    if (Platform.isLinux) {
      const editors = ['gedit', 'kate', 'mousepad', 'code', 'xdg-open'];
      for (final ed in editors) {
        final check = await Process.run('which', [ed]);
        if (check.exitCode == 0) {
          await Process.run(ed, [contentPath], runInShell: true);
          return;
        }
      }
      throw Exception('Tidak ditemukan editor teks yang kompatibel.');
    } else {
      final result = await OpenFile.open(contentPath);
      if (result.type != ResultType.done) throw Exception(result.message);
    }
  }
}
