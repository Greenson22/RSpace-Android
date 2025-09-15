// lib/features/html_editor/presentation/pages/html_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart'; // Bahasa untuk HTML

import '../../../content_management/application/discussion_provider.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../../core/services/storage_service.dart';
import '../themes/editor_themes.dart';

class HtmlEditorPage extends StatefulWidget {
  final Discussion discussion;

  const HtmlEditorPage({super.key, required this.discussion});

  @override
  State<HtmlEditorPage> createState() => _HtmlEditorPageState();
}

class _HtmlEditorPageState extends State<HtmlEditorPage> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  CodeController? _controller;
  bool _isLoading = true;
  String? _error;

  late EditorTheme _selectedTheme;

  // ==> AWAL PENAMBAHAN: Variabel untuk logika hapus tag berpasangan <==
  String _previousText = '';
  bool _isAutoEditing = false;
  // ==> AKHIR PENAMBAHAN <==

  // ==> AWAL PENAMBAHAN: State untuk mode pilih baris <==
  bool _isLineSelectionMode = false;
  // ==> AKHIR PENAMBAHAN <==

  @override
  void initState() {
    super.initState();
    _selectedTheme = editorThemes.first;
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    await _loadTheme();
    await _loadFileContent();
  }

  Future<void> _loadTheme() async {
    final themeName = await _prefsService.loadHtmlEditorTheme();
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
      await _prefsService.saveHtmlEditorTheme(newTheme.name);
    }
  }

  @override
  void dispose() {
    // ==> PERBAIKAN: Hapus listener sebelum dispose <==
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadFileContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      final content = await provider.readHtmlFromFile(
        widget.discussion.filePath!,
      );

      _controller = CodeController(text: content, language: xml);

      // ==> AWAL PENAMBAHAN: Tambahkan listener ke controller <==
      _previousText = _controller!.text;
      _controller!.addListener(_onTextChanged);
      // ==> AKHIR PENAMBAHAN <==
    } catch (e) {
      setState(() {
        _error = "Gagal memuat file: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==> FUNGSI BARU: Listener untuk mendeteksi perubahan teks <==
  void _onTextChanged() {
    if (_isAutoEditing) return;

    final currentText = _controller!.text;
    final currentSelection = _controller!.selection;

    // Cek apakah ada teks yang dihapus
    if (currentText.length < _previousText.length) {
      final start = currentSelection.start;
      final deletedText = _previousText.substring(
        start,
        start + (_previousText.length - currentText.length),
      );

      // Regex untuk mendeteksi tag pembuka (bukan self-closing)
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

  // ==> FUNGSI BARU: Logika untuk mencari dan menghapus tag penutup <==
  void _findAndRemoveMatchingTag(String tagName, int deletionStartOffset) {
    String text = _controller!.text;
    int searchIndex = deletionStartOffset;
    int balance = 1; // Mulai dengan 1 karena tag pembuka baru saja dihapus

    while (searchIndex < text.length) {
      final nextOpeningTag = text.indexOf('<$tagName', searchIndex);
      final nextClosingTag = text.indexOf('</$tagName>', searchIndex);

      if (nextClosingTag == -1) {
        // Tidak ada lagi tag penutup, hentikan pencarian
        break;
      }

      if (nextOpeningTag != -1 && nextOpeningTag < nextClosingTag) {
        // Ditemukan tag pembuka lain sebelum tag penutup
        balance++;
        searchIndex = nextOpeningTag + 1;
      } else {
        // Ditemukan tag penutup
        balance--;
        searchIndex = nextClosingTag + 1;

        if (balance == 0) {
          // Ini adalah tag penutup yang berpasangan
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

          // Delay singkat sebelum mengizinkan edit lagi
          Future.delayed(const Duration(milliseconds: 50), () {
            _isAutoEditing = false;
          });
          return;
        }
      }
    }
  }

  // ==> FUNGSI BARU: Logika untuk memilih baris saat diklik <==
  void _handleLineSelection() {
    if (!_isLineSelectionMode || _controller == null) return;

    final text = _controller!.text;
    final offset = _controller!.selection.baseOffset;

    // Cari awal baris
    int start = offset;
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }

    // Cari akhir baris
    int end = offset;
    while (end < text.length && text[end] != '\n') {
      end++;
    }

    setState(() {
      _controller!.selection = TextSelection(
        baseOffset: start,
        extentOffset: end,
      );
    });
  }
  // ==> AKHIR FUNGSI BARU <==

  Future<void> _saveFileContent() async {
    if (_controller == null) return;
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    try {
      await provider.writeHtmlToFile(
        widget.discussion.filePath!,
        _controller!.text,
      );
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
          'Edit: ${widget.discussion.discussion}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // ==> AWAL PENAMBAHAN: Tombol toggle untuk mode pilih baris <==
          IconButton(
            icon: Icon(
              Icons.select_all,
              color: _isLineSelectionMode ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _isLineSelectionMode = !_isLineSelectionMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isLineSelectionMode
                        ? 'Mode Pilih Baris Aktif'
                        : 'Mode Pilih Baris Nonaktif',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Aktifkan/Nonaktifkan Mode Pilih Baris',
          ),
          // ==> AKHIR PENAMBAHAN <==
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
                  // ==> AWAL PENAMBAHAN: Tambahkan callback onTap <==
                  onTap: _handleLineSelection,
                  // ==> AKHIR PENAMBAHAN <==
                ),
              ),
            ),
    );
  }
}
