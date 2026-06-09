// lib/features/html_editor/presentation/pages/html_editor_page.dart
import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart'; // Bahasa untuk HTML
import '../themes/editor_themes.dart';

class HtmlEditorPage extends StatefulWidget {
  final String pageTitle;
  final String initialContent;
  final Future<void> Function(String newContent) onSave;

  const HtmlEditorPage({
    super.key,
    required this.pageTitle,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<HtmlEditorPage> createState() => _HtmlEditorPageState();
}

class _HtmlEditorPageState extends State<HtmlEditorPage> {
  CodeController? _controller;
  bool _isLoading = true;
  String? _error;
  late EditorTheme _selectedTheme;
  String _previousText = '';
  bool _isAutoEditing = false;
  bool _isLineDeletionMode = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = editorThemes.first;
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    final sanitizedContent = _sanitizeUtf16(widget.initialContent);
    _controller = CodeController(text: sanitizedContent, language: xml);
    _previousText = _controller!.text;
    _controller!.addListener(_onTextChanged);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleThemeChanged(EditorTheme? newTheme) {
    if (newTheme != null) {
      setState(() {
        _selectedTheme = newTheme;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  String _sanitizeUtf16(String input) {
    if (input.isEmpty) return input;
    try {
      final cleanRegex = input.replaceAll(
        RegExp(
          r'[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]',
        ),
        '',
      );
      return String.fromCharCodes(cleanRegex.runes);
    } catch (_) {
      return input.replaceAll(
        RegExp(r'[^\x00-\x7F\x80-\xFF\u0100-\uFFFF]'),
        '',
      );
    }
  }

  void _onTextChanged() {
    if (_isAutoEditing) return;
    final currentText = _controller!.text;
    final currentSelection = _controller!.selection;
    if (currentText.length < _previousText.length) {
      final start = currentSelection.start;
      if (start < 0 || start > _previousText.length) return;
      try {
        final deletedLength = _previousText.length - currentText.length;
        final endLocation = start + deletedLength;
        if (endLocation <= _previousText.length) {
          final deletedText = _previousText.substring(start, endLocation);
          final openingTagRegex = RegExp(r'^<([a-zA-Z0-9]+)\s*.*?>$');
          final selfClosingTags = {'br', 'hr', 'img', 'input', 'meta', 'link'};
          final match = openingTagRegex.firstMatch(deletedText.trim());
          if (match != null) {
            final tagName = match.group(1);
            if (tagName != null &&
                !selfClosingTags.contains(tagName.toLowerCase())) {
              _findAndRemoveMatchingTag(tagName, start);
            }
          }
        }
      } catch (e) {
        // Mencegah crash akibat kegagalan substring acak saat mengetik sangat cepat
      }
    }
    _previousText = currentText;
  }

  void _findAndRemoveMatchingTag(String tagName, int deletionStartOffset) {
    String text = _controller!.text;
    int searchIndex = deletionStartOffset;
    int balance = 1;
    while (searchIndex < text.length) {
      final nextOpeningTag = text.indexOf('<$tagName', searchIndex);
      final nextClosingTag = text.indexOf('</$tagName>', searchIndex);
      if (nextClosingTag == -1) {
        break;
      }
      if (nextOpeningTag != -1 && nextOpeningTag < nextClosingTag) {
        balance++;
        searchIndex = nextOpeningTag + 1;
      } else {
        balance--;
        searchIndex = nextClosingTag + 1;
        if (balance == 0) {
          _isAutoEditing = true;
          final newTextRaw =
              text.substring(0, nextClosingTag) +
              text.substring(nextClosingTag + tagName.length + 3);
          final newText = _sanitizeUtf16(newTextRaw);
          final selection = TextSelection.fromPosition(
            TextPosition(offset: deletionStartOffset),
          );
          _controller!.text = newText;
          _controller!.selection = selection;
          _previousText = newText;
          Future.delayed(const Duration(milliseconds: 50), () {
            _isAutoEditing = false;
          });
          return;
        }
      }
    }
  }

  void _handleLineDeletion() {
    if (!_isLineDeletionMode || _controller == null) return;
    final text = _controller!.text;
    final offset = _controller!.selection.baseOffset;
    int start = offset;
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }
    int end = offset;
    while (end < text.length && text[end] != '\n') {
      end++;
    }
    if (end < text.length && text[end] == '\n') {
      end++;
    } else if (start > 0 && text[start - 1] == '\n') {
      start--;
    }
    final newTextRaw = text.substring(0, start) + text.substring(end);
    final newText = _sanitizeUtf16(newTextRaw);
    _controller!.text = newText;
    _controller!.selection = TextSelection.fromPosition(
      TextPosition(offset: start),
    );
  }

  void _stripAllHtmlTags() {
    if (_controller == null) return;
    final currentText = _controller!.text;
    final newTextRaw = currentText.replaceAll(RegExp(r'<[^>]*>'), '');
    _controller!.text = _sanitizeUtf16(newTextRaw);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua tag HTML telah dihapus.')),
    );
  }

  void _extractBodyContent() {
    if (_controller == null) return;
    final currentText = _controller!.text;
    final bodyContentRegex = RegExp(
      r'<body[^>]*>([\s\S]*?)<\/body>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = bodyContentRegex.firstMatch(currentText);
    if (match != null && match.group(1) != null) {
      final newTextRaw = match.group(1)!.trim();
      _controller!.text = _sanitizeUtf16(newTextRaw);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya konten <body> yang dipertahankan.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag <body> tidak ditemukan.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _stripBodyTags() {
    if (_controller == null) return;
    final currentText = _controller!.text;
    final bodyContentRegex = RegExp(
      r'<body[^>]*>([\s\S]*?)<\/body>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = bodyContentRegex.firstMatch(currentText);
    if (match != null && match.group(1) != null) {
      final bodyContent = match.group(1)!;
      final newTextRaw = currentText.replaceFirst(
        bodyContentRegex,
        bodyContent,
      );
      _controller!.text = _sanitizeUtf16(newTextRaw);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag <body> telah dihapus.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag <body> tidak ditemukan.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _stripHead() {
    if (_controller == null) return;
    final currentText = _controller!.text;
    final newTextRaw = currentText.replaceAll(
      RegExp(
        r'<head[^>]*>[\s\S]*?<\/head>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    _controller!.text = _sanitizeUtf16(newTextRaw);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bagian <head> telah dihapus.')),
    );
  }

  Future<void> _saveFileContent() async {
    if (_controller == null) return;
    try {
      await widget.onSave(_controller!.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // MENGEKSTRAK WARNA UTAMA DARI TEMA EDITOR YANG DIPILIH
    final Color editorBackgroundColor =
        _selectedTheme.theme['root']?.backgroundColor ??
        (_selectedTheme.name.toLowerCase().contains('light')
            ? Colors.white
            : const Color(0xFF1E1E1E));
    final Color editorTextColor =
        _selectedTheme.theme['root']?.color ??
        (_selectedTheme.name.toLowerCase().contains('light')
            ? Colors.black87
            : Colors.white70);

    final bool isLightTheme =
        _selectedTheme.name.toLowerCase().contains('light') ||
        _selectedTheme.name == 'GitHub' ||
        _selectedTheme.name == 'Xcode';
    final Color appBarColor = isLightTheme
        ? Colors.grey[200]!
        : Colors.grey[900]!;
    final Color foregroundColor = isLightTheme ? Colors.black87 : Colors.white;

    // === ADAPTASI UKURAN DINAMIS SESUAI DISCUSSIONS_PAGE ===
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseAppBarIconSize = 18.0;
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;
    // =======================================================

    return Theme(
      data: ThemeData(
        brightness: isLightTheme ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: editorBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: editorBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          foregroundColor: foregroundColor,
          // Menyamakan properti tema ikon bawaan AppBar
          iconTheme: IconThemeData(
            size: scaledAppBarIconSize,
            color: foregroundColor,
          ),
          title: Text(
            'Edit: ${widget.pageTitle}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: _isLineDeletionMode ? Colors.amber : foregroundColor,
              ),
              iconSize: scaledAppBarIconSize, // Ditambahkan ukuran skala
              onPressed: () {
                setState(() {
                  _isLineDeletionMode = !_isLineDeletionMode;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isLineDeletionMode
                          ? 'Mode Hapus Baris Aktif'
                          : 'Mode Hapus Baris Nonaktif',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Aktifkan/Nonaktifkan Mode Hapus Baris',
            ),
            PopupMenuButton<VoidCallback>(
              icon: Icon(Icons.text_format, color: foregroundColor),
              iconSize: scaledAppBarIconSize, // Ditambahkan ukuran skala
              tooltip: 'Olah Teks',
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _extractBodyContent,
                  child: const Text('Ekstrak Konten Body'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _stripAllHtmlTags,
                  child: const Text('Hapus Semua Tag HTML'),
                ),
                PopupMenuItem(
                  value: _stripBodyTags,
                  child: const Text('Hapus Tag Body (Kecuali Isi)'),
                ),
                PopupMenuItem(
                  value: _stripHead,
                  child: const Text('Hapus Head & Isinya'),
                ),
              ],
            ),
            DropdownButton<EditorTheme>(
              value: _selectedTheme,
              onChanged: _handleThemeChanged,
              items: editorThemes.map<DropdownMenuItem<EditorTheme>>((
                EditorTheme theme,
              ) {
                return DropdownMenuItem<EditorTheme>(
                  value: theme,
                  child: Text(
                    theme.name,
                    style: TextStyle(color: foregroundColor),
                  ),
                );
              }).toList(),
              dropdownColor: appBarColor,
              underline: Container(),
              iconEnabledColor: foregroundColor,
            ),
            IconButton(
              icon: Icon(Icons.save, color: foregroundColor),
              iconSize: scaledAppBarIconSize, // Ditambahkan ukuran skala
              onPressed: _isLoading || _controller == null
                  ? null
                  : _saveFileContent,
              tooltip: 'Simpan Perubahan',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: CodeTheme(
                  data: CodeThemeData(styles: _selectedTheme.theme),
                  child: CodeField(
                    controller: _controller!,
                    expands: true,
                    textStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: editorTextColor,
                    ),
                    onTap: _handleLineDeletion,
                    background: editorBackgroundColor,
                  ),
                ),
              ),
      ),
    );
  }
}
