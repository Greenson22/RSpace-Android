// lib/features/html_editor/presentation/pages/html_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../content_management/application/discussion_provider.dart';
import '../../../content_management/domain/models/discussion_model.dart';

class HtmlEditorPage extends StatefulWidget {
  final Discussion discussion;

  const HtmlEditorPage({super.key, required this.discussion});

  @override
  State<HtmlEditorPage> createState() => _HtmlEditorPageState();
}

class _HtmlEditorPageState extends State<HtmlEditorPage> {
  late final TextEditingController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFileContent();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      _controller.text = content;
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
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    try {
      await provider.writeHtmlToFile(
        widget.discussion.filePath!,
        _controller.text,
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveFileContent,
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
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan konten HTML di sini...',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
    );
  }
}
