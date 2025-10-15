// lib/features/notes/presentation/pages/note_view_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_editor_page.dart';

class NoteViewPage extends StatelessWidget {
  final String topicName;
  final Note note;

  const NoteViewPage({super.key, required this.topicName, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy HH:mm',
      'id_ID',
    ).format(note.modifiedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      NoteEditorPage(topicName: topicName, note: note),
                ),
              );
            },
            tooltip: 'Edit Catatan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: note.title));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul disalin.')),
                    );
                  },
                  tooltip: 'Salin Judul',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diubah: $formattedDate',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            MarkdownBody(
              data: note.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(
                theme,
              ).copyWith(p: theme.textTheme.bodyLarge?.copyWith(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
