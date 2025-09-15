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

// == KELAS BARU UNTUK MEREPRESENTASIKAN SETIAP ELEMEN ==
class _TaggableElement {
  final int id; // ID unik untuk instance ini, berdasarkan hashCode
  final dom.Element element;

  _TaggableElement(this.element) : id = element.hashCode;

  String get tagName => element.localName!;
  String get contentPreview {
    // Membuat pratinjau teks yang bersih
    final text = element.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return '(tidak ada konten teks)';
    }
    if (text.length > 40) {
      return '"${text.substring(0, 40)}..."';
    }
    return '"$text"';
  }

  // Digunakan untuk perbandingan di dalam Set
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TaggableElement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id;
}
// =======================================================

class RemoveTagDialog extends StatefulWidget {
  final String currentHtml;

  const RemoveTagDialog({super.key, required this.currentHtml});

  @override
  State<RemoveTagDialog> createState() => _RemoveTagDialogState();
}

class _RemoveTagDialogState extends State<RemoveTagDialog> {
  // ==> DIUBAH: Menggunakan model data yang baru <==
  List<_TaggableElement> _availableElements = [];
  final Set<_TaggableElement> _selectedElements = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseHtmlAndExtractElements();
  }

  // ==> LOGIKA PARSING DIPERBARUI TOTAL <==
  void _parseHtmlAndExtractElements() {
    Future(() {
      final document = html_parser.parse(widget.currentHtml);
      final elements = <_TaggableElement>[];

      void traverse(dom.Node node) {
        if (node is dom.Element) {
          if (node.localName != 'body' && node.localName != 'html') {
            elements.add(_TaggableElement(node));
          }
          // Lanjutkan traversal ke anak-anaknya
          for (var child in node.nodes) {
            traverse(child);
          }
        }
      }

      if (document.body != null) {
        traverse(document.body!);
      }
      if (mounted) {
        setState(() {
          _availableElements = elements;
          _isLoading = false;
        });
      }
    });
  }

  // ==> LOGIKA PENGHAPUSAN DIPERBARUI TOTAL <==
  void _handleRemoveTags() {
    if (_selectedElements.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Tidak perlu mem-parsing ulang, kita sudah punya referensi elemennya
    for (final taggableElement in _selectedElements) {
      final elementToRemove = taggableElement.element;
      final parent = elementToRemove.parent;

      if (parent != null) {
        final children = List<dom.Node>.from(elementToRemove.nodes);
        for (final child in children) {
          parent.insertBefore(child, elementToRemove);
        }
        elementToRemove.remove();
      }
    }

    // Cari root element (biasanya body) untuk mendapatkan innerHtml terbaru
    dom.Element? root = _selectedElements.first.element.parent;
    while (root?.parent != null) {
      root = root?.parent;
    }

    // Dapatkan innerHTML dari body setelah semua modifikasi
    final finalHtml = root?.innerHtml ?? widget.currentHtml;

    Navigator.pop(context, finalHtml);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Tag HTML'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableElements.isEmpty
            ? const Center(child: Text('Tidak ada tag yang bisa dihapus.'))
            : ListView.builder(
                // ==> UI MENGGUNAKAN ListView.builder <==
                itemCount: _availableElements.length,
                itemBuilder: (context, index) {
                  final element = _availableElements[index];
                  final isSelected = _selectedElements.contains(element);
                  return CheckboxListTile(
                    title: Text('<${element.tagName}>'),
                    subtitle: Text(
                      element.contentPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedElements.add(element);
                        } else {
                          _selectedElements.remove(element);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _selectedElements.isEmpty ? null : _handleRemoveTags,
          child: const Text('Hapus Tag Terpilih'),
        ),
      ],
    );
  }
}
