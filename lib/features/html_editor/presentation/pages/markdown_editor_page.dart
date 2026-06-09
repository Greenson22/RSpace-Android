// lib/features/html_editor/presentation/pages/markdown_editor_page.dart

import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/markdown.dart'; // Bahasa untuk Markdown

import '../themes/editor_themes.dart';

class MarkdownEditorPage extends StatefulWidget {
  final String pageTitle;
  final String initialContent;
  final Future<void> Function(String newContent) onSave;

  const MarkdownEditorPage({
    super.key,
    required this.pageTitle,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage> {
  CodeController? _controller;
  bool _isLoading = true;
  String? _error;

  late EditorTheme _selectedTheme;
  String _previousText = '';
  bool _isLineDeletionMode = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = editorThemes.first;
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    // Menyaring isi konten awal menggunakan fungsi sanitasi sebelum diserahkan ke CodeController
    final sanitizedContent = _sanitizeUtf16(widget.initialContent);

    _controller = CodeController(text: sanitizedContent, language: markdown);
    _previousText = _controller!.text;
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
    _controller?.dispose();
    super.dispose();
  }

  // FUNGSI UTAS SANITASI UNTUK MENCEGAH EROR INVALID UTF-16 PADA GRAPHIC CANVAS FLUTTER
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

  Future<void> _saveFileContent() async {
    if (_controller == null) return;
    try {
      await widget.onSave(_controller!.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File Markdown berhasil disimpan!'),
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
          title: Text(
            'Edit MD: ${widget.pageTitle}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foregroundColor),
          ),
          iconTheme: IconThemeData(color: foregroundColor),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: _isLineDeletionMode ? Colors.amber : foregroundColor,
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
