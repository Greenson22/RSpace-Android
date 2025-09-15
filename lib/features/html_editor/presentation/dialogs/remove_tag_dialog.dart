// lib/features/html_editor/presentation/dialogs/remove_tag_dialog.dart

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Menampilkan dialog untuk menghapus tag HTML dari konten.
/// Mengembalikan string HTML yang telah dimodifikasi jika ada perubahan.
Future<String?> showRemoveTagDialog(
  BuildContext context,
  String currentHtml,
) async {
  return showDialog<String>(
    context: context,
    builder: (context) => RemoveTagDialog(currentHtml: currentHtml),
  );
}

class RemoveTagDialog extends StatefulWidget {
  final String currentHtml;

  const RemoveTagDialog({super.key, required this.currentHtml});

  @override
  State<RemoveTagDialog> createState() => _RemoveTagDialogState();
}

class _RemoveTagDialogState extends State<RemoveTagDialog> {
  Set<String> _availableTags = {};
  final Set<String> _selectedTags = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseHtmlAndExtractTags();
  }

  void _parseHtmlAndExtractTags() {
    Future(() {
      // ==> PERUBAHAN 1: Gunakan parse() bukan parseFragment() <==
      final document = html_parser.parse(widget.currentHtml);
      final tags = <String>{};

      void traverse(dom.Node node) {
        if (node is dom.Element) {
          if (node.localName != 'body' && node.localName != 'html') {
            tags.add(node.localName!);
          }
          for (var child in node.nodes) {
            traverse(child);
          }
        }
      }

      // ==> PERUBAHAN 2: Mulai traversal dari body <==
      if (document.body != null) {
        traverse(document.body!);
      }

      if (mounted) {
        setState(() {
          _availableTags = tags;
          _isLoading = false;
        });
      }
    });
  }

  void _handleRemoveTags() {
    if (_selectedTags.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // ==> PERUBAHAN 3: Gunakan parse() bukan parseFragment() <==
    final document = html_parser.parse(widget.currentHtml);

    void traverseAndRemove(dom.Element element) {
      final children = List<dom.Node>.from(element.nodes);
      for (final child in children) {
        if (child is dom.Element) {
          traverseAndRemove(child);

          if (_selectedTags.contains(child.localName)) {
            final childNodes = List<dom.Node>.from(child.nodes);
            for (final grandChild in childNodes) {
              child.parent!.insertBefore(grandChild, child);
            }
            child.remove();
          }
        }
      }
    }

    // Pengecekan null untuk keamanan
    if (document.body != null) {
      traverseAndRemove(document.body!);
    }

    Navigator.pop(context, document.body!.innerHtml);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Tag HTML'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableTags.isEmpty
            ? const Center(child: Text('Tidak ada tag yang ditemukan.'))
            : ListView(
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return CheckboxListTile(
                    title: Text('<$tag>'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _selectedTags.isEmpty ? null : _handleRemoveTags,
          child: const Text('Hapus Tag Terpilih'),
        ),
      ],
    );
  }
}
