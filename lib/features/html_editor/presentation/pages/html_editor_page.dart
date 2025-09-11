// lib/features/html_editor/presentation/pages/html_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart'; // Bahasa untuk HTML

import '../../../content_management/application/discussion_provider.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../themes/editor_themes.dart'; // Import file tema baru

class HtmlEditorPage extends StatefulWidget {
  final Discussion discussion;

  const HtmlEditorPage({super.key, required this.discussion});

  @override
  State<HtmlEditorPage> createState() => _HtmlEditorPageState();
}

class _HtmlEditorPageState extends State<HtmlEditorPage> {
  CodeController? _controller;
  bool _isLoading = true;
  String? _error;

  // State baru untuk mengelola tema yang dipilih
  late EditorTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    // Inisialisasi tema default
    _selectedTheme = editorThemes.first;
    _loadFileContent();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit: ${widget.discussion.discussion}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Dropdown untuk memilih tema
          DropdownButton<EditorTheme>(
            value: _selectedTheme,
            onChanged: (EditorTheme? newTheme) {
              if (newTheme != null) {
                setState(() {
                  _selectedTheme = newTheme;
                });
              }
            },
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
            underline: Container(), // Menghilangkan garis bawah
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
                // Gunakan tema yang dipilih dari state
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
