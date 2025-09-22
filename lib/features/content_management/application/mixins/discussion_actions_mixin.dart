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
  // ... (dependencies dan abstract methods tidak berubah) ...
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

  // ... (selection actions, lifecycle, dan point actions tidak berubah) ...
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

  // This should be implemented by the main provider
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

  // This should be implemented by the main provider
  void updatePointCode(Point point, String newCode);

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

  // --- PERUBAHAN SIGNIFIKAN DI BAWAH INI ---

  Future<String> getPerpuskuHtmlBasePath() async {
    final perpuskuPath = await pathService.perpuskuDataPath;
    return path.join(perpuskuPath, 'file_contents', 'topics');
  }

  // >> DIPERBARUI: Sekarang menerima subject's linkedPath dan nama file
  Future<String> readHtmlFromFile(
    String subjectLinkedPath,
    String fileName,
  ) async {
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, subjectLinkedPath, fileName);
    final file = File(fullPath);
    if (!await file.exists())
      throw Exception("File tidak ditemukan: $fullPath");
    return await file.readAsString();
  }

  // >> DIPERBARUI: Hanya menyimpan nama file
  Future<void> updateDiscussionFilePath(
    Discussion discussion,
    String fileName,
  ) async {
    discussion.filePath = fileName;
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
            // Gabungkan path untuk mendapatkan path sumber yang lengkap
            final sourceRelativePath = path.join(
              sourceSubjectLinkedPath!,
              discussion.filePath!,
            );

            final newFileName = await discussionService.moveDiscussionFile(
              perpuskuBasePath: perpuskuBasePath,
              sourceRelativePath: sourceRelativePath,
              targetSubjectLinkedPath: targetSubjectLinkedPath,
            );
            discussion.filePath = newFileName;
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
    // Service sekarang mengembalikan nama file saja
    final newFileName = await discussionService.createDiscussionFile(
      perpuskuBasePath: await getPerpuskuHtmlBasePath(),
      subjectLinkedPath: subjectLinkedPath,
      discussionName: discussion.discussion,
    );
    discussion.filePath = newFileName;
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  // >> DIPERBARUI: Membutuhkan subject's linkedPath
  Future<void> writeHtmlToFile(
    String subjectLinkedPath,
    String fileName,
    String htmlContent,
  ) async {
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, subjectLinkedPath, fileName);
    final file = File(fullPath);
    if (!await file.exists()) throw Exception("File target tidak ditemukan.");
    await file.writeAsString(htmlContent);
  }

  Future<void> openDiscussionFile(
    Discussion discussion,
    BuildContext context,
  ) async {
    if (sourceSubjectLinkedPath == null || discussion.filePath == null) {
      throw Exception('Path tidak lengkap atau tidak ada.');
    }
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');

    // Bangun path lengkap
    final contentPath = path.join(
      basePath,
      sourceSubjectLinkedPath!,
      discussion.filePath!,
    );
    final subjectPath = path.dirname(contentPath);
    final indexPath = path.join(subjectPath, 'index.html');

    if (!await File(contentPath).exists() || !await File(indexPath).exists()) {
      throw Exception('File konten atau index.html tidak ditemukan.');
    }

    // ... sisa logika (parsing HTML, dll) tetap sama
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: this as DiscussionProvider,
            child: HtmlEditorPage(discussion: discussion),
          ),
        ),
      );
    } else if (choice == 'external') {
      await _openFileWithExternalEditor(discussion);
    }
  }

  Future<void> _openFileWithExternalEditor(Discussion discussion) async {
    if (sourceSubjectLinkedPath == null || discussion.filePath == null) {
      throw Exception('Path tidak lengkap atau tidak ada.');
    }

    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final contentPath = path.join(
      basePath,
      sourceSubjectLinkedPath!,
      discussion.filePath!,
    );

    if (!await File(contentPath).exists()) {
      throw Exception('File tidak ditemukan.');
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
