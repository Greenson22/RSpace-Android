// lib/features/content_management/application/mixins/discussion_actions_mixin.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../features/html_editor/presentation/pages/html_editor_page.dart';
import '../../../../features/settings/application/theme_provider.dart';
import '../../../../features/webview_page/presentation/pages/webview_page.dart';
import '../../domain/models/discussion_model.dart';
import '../../domain/services/discussion_service.dart';
import '../../../../core/services/path_service.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import '../discussion_provider.dart';

mixin DiscussionActionsMixin on ChangeNotifier {
  DiscussionService get discussionService;
  PathService get pathService;
  String? get sourceSubjectLinkedPath;
  List<Discussion> get allDiscussions;
  set allDiscussions(List<Discussion> value);
  List<Discussion> get filteredDiscussions;
  Set<Discussion> get selectedDiscussions;

  void filterAndSortDiscussions();
  Future<void> saveDiscussions();
  void internalNotifyListeners();

  // ==> FUNGSI INI DIUBAH MENJADI PUBLIC (HAPUS GARIS BAWAH) <==
  String getCorrectRelativePath(Discussion discussion) {
    if (discussion.filePath == null || discussion.filePath!.isEmpty) {
      throw Exception('Path file untuk diskusi ini kosong atau tidak ada.');
    }

    if (discussion.filePath!.contains('/')) {
      return discussion.filePath!;
    }

    if (sourceSubjectLinkedPath == null || sourceSubjectLinkedPath!.isEmpty) {
      throw Exception(
        'Gagal merekonstruksi path file: Subject sumber tidak tertaut ke folder PerpusKu.',
      );
    }

    return path.join(sourceSubjectLinkedPath!, discussion.filePath!);
  }

  List<String> get repetitionCodes => kRepetitionCodes;

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

  void updateDiscussionCode(Discussion discussion, String newCode);

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

  void updatePointCode(Point point, String newCode);

  void markPointAsFinished(Point point) {
    point.finished = true;
    point.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

  Future<String> getPerpuskuHtmlBasePath() async {
    final perpuskuPath = await pathService.perpuskuDataPath;
    return path.join(perpuskuPath, 'file_contents', 'topics');
  }

  Future<String> readHtmlFromFile(Discussion discussion) async {
    // ==> GUNAKAN FUNGSI PUBLIK <==
    final String finalRelativePath = getCorrectRelativePath(discussion);
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, finalRelativePath);
    final file = File(fullPath);
    if (!await file.exists()) {
      throw Exception("File tidak ditemukan: $fullPath");
    }
    return await file.readAsString();
  }

  Future<void> updateDiscussionFilePath(
    Discussion discussion,
    String newRelativePath,
  ) async {
    discussion.filePath = newRelativePath;
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
        if (targetSubjectLinkedPath != null) {
          try {
            // ==> GUNAKAN FUNGSI PUBLIK <==
            final sourceRelativePath = getCorrectRelativePath(discussion);

            final newFileName = await discussionService.moveDiscussionFile(
              perpuskuBasePath: perpuskuBasePath,
              sourceRelativePath: sourceRelativePath,
              targetSubjectLinkedPath: targetSubjectLinkedPath,
            );

            if (newFileName != null) {
              discussion.filePath = path.join(
                targetSubjectLinkedPath,
                newFileName,
              );
              log.writeln(
                '  > File HTML dipindahkan ke "$targetSubjectLinkedPath".',
              );
            } else {
              log.writeln(
                '  > GAGAL memindahkan file HTML: File sumber tidak ditemukan.',
              );
            }
          } catch (e) {
            log.writeln('  > GAGAL memindahkan file HTML: $e');
          }
        } else {
          log.writeln(
            '  > File HTML tidak dipindahkan (tujuan tidak tertaut).',
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
    final perpuskuBasePath = await getPerpuskuHtmlBasePath();
    final newFileName = await discussionService.createDiscussionFile(
      perpuskuBasePath: perpuskuBasePath,
      subjectLinkedPath: subjectLinkedPath,
      discussionName: discussion.discussion,
    );
    discussion.filePath = path.join(subjectLinkedPath, newFileName);
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  Future<void> writeHtmlToFile(
    String relativeFilePath,
    String htmlContent,
  ) async {
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, relativeFilePath);
    final file = File(fullPath);
    if (!await file.exists()) {
      throw Exception("File target tidak ditemukan: $fullPath");
    }
    await file.writeAsString(htmlContent);
  }

  Future<void> openDiscussionFile(
    Discussion discussion,
    BuildContext context,
  ) async {
    // ==> GUNAKAN FUNGSI PUBLIK <==
    final finalRelativePath = getCorrectRelativePath(discussion);
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final contentPath = path.join(basePath, finalRelativePath);

    final subjectPath = path.dirname(contentPath);
    final indexPath = path.join(subjectPath, 'index.html');

    final contentFile = File(contentPath);
    final indexFile = File(indexPath);

    if (!await contentFile.exists()) {
      throw Exception('File konten tidak ditemukan: $contentPath');
    }

    if (!await indexFile.exists()) {
      const defaultIndexContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index</title>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>''';
      await indexFile.writeAsString(defaultIndexContent);
    }

    final contentHtml = await contentFile.readAsString();
    final indexHtml = await indexFile.readAsString();
    final indexDoc = parse(indexHtml);
    final container = indexDoc.querySelector('#main-container');
    if (container == null) {
      throw Exception(
        'Elemen #main-container tidak ditemukan di dalam index.html.',
      );
    }

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

    final finalHtmlContent = indexDoc.outerHtml;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (themeProvider.openInAppBrowser && Platform.isAndroid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: this as DiscussionProvider,
            child: WebViewPage(
              title: discussion.discussion,
              htmlContent: finalHtmlContent,
              discussion: discussion,
            ),
          ),
        ),
      );
    } else {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        path.join(
          tempDir.path,
          '${DateTime.now().millisecondsSinceEpoch}.html',
        ),
      );
      await tempFile.writeAsString(finalHtmlContent);
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) throw Exception(result.message);
    }
  }

  Future<void> editDiscussionFileWithSelection(
    Discussion discussion,
    BuildContext context,
  ) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final String? editorChoice = themeProvider.defaultHtmlEditor;

    // If a default is set, use it. Otherwise, show the dialog.
    if (editorChoice != null) {
      if (editorChoice == 'internal') {
        await _openWithInternalEditor(discussion, context);
      } else {
        await _openFileWithExternalEditor(discussion);
      }
    } else {
      final choice = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Editor'),
          content: const Text(
            'Buka dengan editor internal atau aplikasi eksternal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'internal'),
              child: const Text('Internal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'external'),
              child: const Text('Eksternal'),
            ),
          ],
        ),
      );

      if (choice == 'internal' && context.mounted) {
        await _openWithInternalEditor(discussion, context);
      } else if (choice == 'external') {
        await _openFileWithExternalEditor(discussion);
      }
    }
  }

  Future<void> _openWithInternalEditor(
    Discussion discussion,
    BuildContext context,
  ) async {
    final content = await readHtmlFromFile(discussion);
    // ==> GUNAKAN FUNGSI PUBLIK <==
    final correctPath = getCorrectRelativePath(discussion);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HtmlEditorPage(
          pageTitle: discussion.discussion,
          initialContent: content,
          onSave: (newContent) async {
            await writeHtmlToFile(correctPath, newContent);
          },
        ),
      ),
    );
  }

  Future<void> _openFileWithExternalEditor(Discussion discussion) async {
    // ==> GUNAKAN FUNGSI PUBLIK <==
    final finalRelativePath = getCorrectRelativePath(discussion);

    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final contentPath = path.join(basePath, finalRelativePath);

    if (!await File(contentPath).exists()) {
      throw Exception('File tidak ditemukan: $contentPath');
    }

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
