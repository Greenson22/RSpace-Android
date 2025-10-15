// lib/features/notes/presentation/pages/note_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/notes/application/note_list_provider.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_editor_page.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_view_page.dart';
import 'package:provider/provider.dart';

class NoteListPage extends StatefulWidget {
  final String topicName;
  const NoteListPage({super.key, required this.topicName});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<NoteListProvider>(
        context,
        listen: false,
      ).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(BuildContext context, note) {
    final provider = Provider.of<NoteListProvider>(context, listen: false);
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Judul Catatan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Judul Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.renameNote(note, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String noteId,
    String noteTitle,
  ) {
    final provider = Provider.of<NoteListProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Anda yakin ingin menghapus catatan "$noteTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteNote(noteId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteListProvider(widget.topicName),
      child: Consumer<NoteListProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.topicName)),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari catatan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.notes.isEmpty
                      ? const Center(
                          child: Text('Belum ada catatan di topik ini.'),
                        )
                      : ListView.builder(
                          itemCount: provider.notes.length,
                          itemBuilder: (context, index) {
                            final note = provider.notes[index];
                            return ListTile(
                              leading: const Icon(Icons.note_outlined),
                              title: Text(note.title),
                              subtitle: Text(
                                'Diperbarui: ${DateFormat.yMd().add_jm().format(note.modifiedAt)}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'view') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NoteViewPage(
                                          topicName: widget.topicName,
                                          note: note,
                                        ),
                                      ),
                                    ).then((_) => provider.fetchNotes());
                                  } else if (value == 'rename') {
                                    _showRenameDialog(context, note);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(
                                      context,
                                      note.id,
                                      note.title,
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('Lihat Catatan'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Ubah Nama'),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoteViewPage(
                                      topicName: widget.topicName,
                                      note: note,
                                    ),
                                  ),
                                ).then((_) => provider.fetchNotes());
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteEditorPage(topicName: widget.topicName),
                  ),
                ).then((_) => provider.fetchNotes());
              },
              child: const Icon(Icons.add),
              tooltip: 'Tambah Catatan',
            ),
          );
        },
      ),
    );
  }
}
