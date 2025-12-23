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
import 'package:markdown/markdown.dart' as md; // Import library markdown

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
    // Deteksi tipe file berdasarkan ekstensi
    if (newRelativePath.toLowerCase().endsWith('.md')) {
      discussion.linkType = DiscussionLinkType.markdown;
    } else {
      discussion.linkType = DiscussionLinkType.html;
    }
    filterAndSortDiscussions();
    await saveDiscussions();
    internalNotifyListeners();
  }

  Future<void> removeDiscussionFilePath(Discussion discussion) async {
    discussion.filePath = null;
    discussion.linkType = DiscussionLinkType.none;
    filterAndSortDiscussions();
    await saveDiscussions();
    internalNotifyListeners();
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
                '  > File dipindahkan ke "$targetSubjectLinkedPath".',
              );
            } else {
              log.writeln(
                '  > GAGAL memindahkan file: File sumber tidak ditemukan.',
              );
            }
          } catch (e) {
            log.writeln('  > GAGAL memindahkan file: $e');
          }
        } else {
          log.writeln('  > File tidak dipindahkan (tujuan tidak tertaut).');
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

  Future<void> createAndLinkMarkdownFile(
    Discussion discussion,
    String subjectLinkedPath,
  ) async {
    final perpuskuBasePath = await getPerpuskuHtmlBasePath();
    // Sanitasi nama file
    final safeName = discussion.discussion.replaceAll(RegExp(r'[^\w\s-]'), '');
    final fileName = '$safeName.md';
    final fullPath = path.join(perpuskuBasePath, subjectLinkedPath, fileName);

    final file = File(fullPath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(
        '# ${discussion.discussion}\n\nMulailah menulis catatan...',
      );
    }

    discussion.filePath = path.join(subjectLinkedPath, fileName);
    discussion.linkType = DiscussionLinkType.markdown;
    filterAndSortDiscussions();
    await saveDiscussions();
    internalNotifyListeners();
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
    discussion.linkType = DiscussionLinkType.html;
    filterAndSortDiscussions();
    await saveDiscussions();
    internalNotifyListeners();
  }

  Future<void> writeHtmlToFile(String relativeFilePath, String content) async {
    final basePath = await getPerpuskuHtmlBasePath();
    final fullPath = path.join(basePath, relativeFilePath);
    final file = File(fullPath);
    if (!await file.exists()) {
      throw Exception("File target tidak ditemukan: $fullPath");
    }
    await file.writeAsString(content);
  }

  Future<void> openDiscussionFile(
    Discussion discussion,
    BuildContext context,
  ) async {
    // 1. Auto-Create untuk Markdown jika file belum ada
    if (discussion.linkType == DiscussionLinkType.markdown) {
      if (discussion.filePath == null || discussion.filePath!.isEmpty) {
        if (sourceSubjectLinkedPath != null) {
          await createAndLinkMarkdownFile(discussion, sourceSubjectLinkedPath!);
        } else {
          throw Exception(
            'Tidak bisa membuka file: Folder subjek tidak tertaut.',
          );
        }
      }
    }

    final finalRelativePath = getCorrectRelativePath(discussion);
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');

    // ==========================================
    // HANDLING MARKDOWN
    // ==========================================
    if (discussion.linkType == DiscussionLinkType.markdown) {
      final fullPath = path.join(basePath, finalRelativePath);
      final file = File(fullPath);

      if (!await file.exists()) {
        throw Exception('File Markdown tidak ditemukan: $fullPath');
      }

      // 1. Baca konten mentah
      final rawContent = await file.readAsString();

      // 2. Konversi ke HTML menggunakan package markdown
      final htmlBody = md.markdownToHtml(
        rawContent,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      // 3. Bungkus dengan HTML & CSS agar cantik
      final styledHtmlWrapper =
          '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${discussion.discussion}</title>
    <style>
      body { 
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
        line-height: 1.6; 
        padding: 20px; 
        color: #24292e; 
        max-width: 800px; 
        margin: 0 auto; 
      }
      h1, h2, h3 { border-bottom: 1px solid #eaecef; padding-bottom: .3em; }
      code { 
        background-color: #f6f8fa; 
        padding: 0.2em 0.4em; 
        border-radius: 3px; 
        font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace; 
        font-size: 85%; 
      }
      pre { 
        background-color: #f6f8fa; 
        padding: 16px; 
        border-radius: 6px; 
        overflow: auto; 
      }
      pre code { background-color: transparent; padding: 0; }
      blockquote { 
        color: #6a737d; 
        border-left: 0.25em solid #dfe2e5; 
        padding: 0 1em; 
        margin: 0; 
      }
      table { border-collapse: collapse; width: 100%; margin-bottom: 16px; }
      table, th, td { border: 1px solid #dfe2e5; }
      th, td { padding: 6px 13px; }
      tr:nth-child(2n) { background-color: #f6f8fa; }
      img { max-width: 100%; box-shadow: 0 4px 8px rgba(0,0,0,0.1); border-radius: 8px; }
      a { color: #0366d6; text-decoration: none; }
      a:hover { text-decoration: underline; }
      ul, ol { padding-left: 2em; }
    </style>
</head>
<body>
    $htmlBody
</body>
</html>
''';

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      if (themeProvider.openInAppBrowser && Platform.isAndroid) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: this as DiscussionProvider,
              child: WebViewPage(
                title: discussion.discussion,
                htmlContent: styledHtmlWrapper,
                discussion: discussion,
              ),
            ),
          ),
        );
      } else {
        // Mode Desktop/External: Simpan sementara sebagai .html agar dibuka browser
        final tempDir = await getTemporaryDirectory();
        final safeName = discussion.discussion.replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        );
        final tempFile = File(
          path.join(tempDir.path, '${safeName}_preview.html'),
        );
        await tempFile.writeAsString(styledHtmlWrapper);

        final result = await OpenFile.open(tempFile.path);
        if (result.type != ResultType.done) {
          throw Exception(result.message);
        }
      }
      return;
    }

    // ==========================================
    // HANDLING HTML BIASA
    // ==========================================
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
    // Handling Editor Markdown
    if (discussion.linkType == DiscussionLinkType.markdown) {
      await _openWithInternalMarkdownEditor(discussion, context);
      return;
    }

    // Default HTML Editor
    final content = await readHtmlFromFile(discussion);
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

  Future<void> _openWithInternalMarkdownEditor(
    Discussion discussion,
    BuildContext context,
  ) async {
    // 1. Cek apakah path file kosong. Jika ya, coba buat file baru.
    if (discussion.filePath == null || discussion.filePath!.isEmpty) {
      if (sourceSubjectLinkedPath != null &&
          sourceSubjectLinkedPath!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membuat file catatan baru...'),
            duration: Duration(seconds: 1),
          ),
        );
        await createAndLinkMarkdownFile(discussion, sourceSubjectLinkedPath!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal: Folder subjek tidak tertaut, tidak bisa membuat file.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final finalRelativePath = getCorrectRelativePath(discussion);
    final perpuskuPath = await pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final fullPath = path.join(basePath, finalRelativePath);
    final file = File(fullPath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('# ${discussion.discussion}');
    }

    String content = await file.readAsString();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _SimpleMarkdownEditor(
            title: discussion.discussion,
            initialContent: content,
            onSave: (newContent) async {
              await file.writeAsString(newContent);
            },
          ),
        ),
      );
    }
  }

  Future<void> _openFileWithExternalEditor(Discussion discussion) async {
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

// Widget Editor Sederhana untuk Markdown
class _SimpleMarkdownEditor extends StatefulWidget {
  final String title;
  final String initialContent;
  final Function(String) onSave;

  const _SimpleMarkdownEditor({
    required this.title,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<_SimpleMarkdownEditor> createState() => _SimpleMarkdownEditorState();
}

class _SimpleMarkdownEditorState extends State<_SimpleMarkdownEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
            onPressed: () {
              widget.onSave(_controller.text);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Disimpan!')));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis markdown di sini...',
          ),
        ),
      ),
    );
  }
}
