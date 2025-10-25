// lib/features/notes/presentation/pages/structured_note_view_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:my_aplication/features/notes/presentation/pages/structured_note_editor_page.dart';

class StructuredNoteViewPage extends StatelessWidget {
  final String topicName;
  final Note note;

  // Hapus 'const'
  StructuredNoteViewPage({
    super.key,
    required this.topicName,
    required this.note,
  }) : assert(note.type == NoteType.structured); // Pastikan tipenya benar

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy HH:mm',
      'id_ID',
    ).format(note.modifiedAt);

    final validFieldDefinitions = note.fieldDefinitions
        .where((field) => field.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => StructuredNoteEditorPage(
                    topicName: topicName,
                    note: note,
                  ),
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
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          note.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          note.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

            if (validFieldDefinitions.isNotEmpty && note.dataEntries.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  // ==> TAMBAHKAN KOLOM NOMOR DI AWAL <==
                  columns: [
                    const DataColumn(
                      label: Text(
                        'No.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true, // Membuatnya rata kanan (opsional)
                    ),
                    // Kolom lainnya dari field definitions
                    ...validFieldDefinitions
                        .map(
                          (field) => DataColumn(
                            label: Text(
                              field,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  // ==> GENERATE BARIS DENGAN NOMOR <==
                  rows: note.dataEntries.asMap().entries.map((indexedEntry) {
                    // Gunakan asMap().entries untuk mendapatkan index
                    int rowIndex = indexedEntry.key;
                    Map<String, String> entry = indexedEntry.value;
                    return DataRow(
                      cells: [
                        // Sel untuk nomor baris
                        DataCell(Text('${rowIndex + 1}')),
                        // Sel lainnya dari data entri
                        ...validFieldDefinitions.map((field) {
                          return DataCell(SelectableText(entry[field] ?? ''));
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              )
            else if (validFieldDefinitions.isNotEmpty &&
                note.dataEntries.isEmpty)
              const Center(child: Text('Belum ada data entri.'))
            else
              const Center(child: Text('Tidak ada field yang didefinisikan.')),
          ],
        ),
      ),
    );
  }
}
