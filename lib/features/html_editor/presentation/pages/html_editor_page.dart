// lib/features/html_editor/presentation/pages/html_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart'; // Bahasa untuk HTML

import '../../../settings/application/theme_provider.dart';
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
    await _loadTheme();
    _controller = CodeController(text: widget.initialContent, language: xml);
    _previousText = _controller!.text;
    _controller!.addListener(_onTextChanged);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final themeName = themeProvider.htmlEditorTheme;

    if (themeName != null) {
      final themeIndex = editorThemes.indexWhere((t) => t.name == themeName);
      if (themeIndex != -1) {
        setState(() {
          _selectedTheme = editorThemes[themeIndex];
        });
      }
    }
  }

  Future<void> _handleThemeChanged(EditorTheme? newTheme) async {
    if (newTheme != null) {
      setState(() {
        _selectedTheme = newTheme;
      });
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.saveHtmlEditorTheme(newTheme.name);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isAutoEditing) return;

    final currentText = _controller!.text;
    final currentSelection = _controller!.selection;

    if (currentText.length < _previousText.length) {
      final start = currentSelection.start;
      final deletedText = _previousText.substring(
        start,
        start + (_previousText.length - currentText.length),
      );

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
          final newText =
              text.substring(0, nextClosingTag) +
              text.substring(nextClosingTag + tagName.length + 3);

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
    final newText = text.substring(0, start) + text.substring(end);
    _controller!.text = newText;
    _controller!.selection = TextSelection.fromPosition(
      TextPosition(offset: start),
    );
  }

  void _stripAllHtmlTags() {
    if (_controller == null) return;
    final currentText = _controller!.text;
    final newText = currentText.replaceAll(RegExp(r'<[^>]*>'), '');
    _controller!.text = newText;
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
      _controller!.text = match.group(1)!.trim();
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
      final newText = currentText.replaceFirst(bodyContentRegex, bodyContent);
      _controller!.text = newText;
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
    final newText = currentText.replaceAll(
      RegExp(
        r'<head[^>]*>[\s\S]*?<\/head>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    _controller!.text = newText;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit: ${widget.pageTitle}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: _isLineDeletionMode ? Colors.amber : null,
            ),
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
            icon: const Icon(Icons.text_format),
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
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            dropdownColor: Colors.grey[800],
            underline: Container(),
          ),
          IconButton(
            icon: const Icon(Icons.save),
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
                  textStyle: const TextStyle(fontFamily: 'monospace'),
                  onTap: _handleLineDeletion,
                ),
              ),
            ),
    );
  }
}
