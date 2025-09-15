// lib/features/html_editor/presentation/pages/html_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart'; // Bahasa untuk HTML

import '../../../content_management/application/discussion_provider.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../../core/services/storage_service.dart'; // Import service penyimpanan
import '../dialogs/remove_tag_dialog.dart'; // ==> IMPORT DIALOG BARU
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

  @override
  void initState() {
    super.initState();
    // Inisialisasi tema default sebelum memuat
    _selectedTheme = editorThemes.first;
    _initializeEditor();
  }

  // Gabungkan pemuatan tema dan konten file
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
      // Simpan tema yang baru dipilih
      await _prefsService.saveHtmlEditorTheme(newTheme.name);
    }
  }

  @override
  void dispose() {
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

  // ==> FUNGSI BARU UNTUK MEMANGGIL DIALOG PENGHAPUSAN TAG <==
  Future<void> _openRemoveTagDialog() async {
    if (_controller == null) return;

    final newHtmlContent = await showRemoveTagDialog(
      context,
      _controller!.text,
    );

    if (newHtmlContent != null) {
      setState(() {
        _controller!.text = newHtmlContent;
      });
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
          // ==> TOMBOL BARU DITAMBAHKAN DI SINI <==
          IconButton(
            icon: const Icon(Icons.format_clear),
            onPressed: _isLoading || _controller == null
                ? null
                : _openRemoveTagDialog,
            tooltip: 'Hapus Tag (Unwrap)',
          ),
          DropdownButton<EditorTheme>(
            value: _selectedTheme,
            onChanged:
                _handleThemeChanged, // Panggil fungsi baru saat tema berubah
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
                ),
              ),
            ),
    );
  }
}
