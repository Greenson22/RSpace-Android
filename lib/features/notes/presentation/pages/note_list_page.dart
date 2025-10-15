// lib/features/notes/presentation/pages/note_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
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

  // ==> FUNGSI BARU UNTUK MENGUBAH IKON <==
  void _showChangeIconDialog(BuildContext context, note) {
    final provider = Provider.of<NoteListProvider>(context, listen: false);
    showIconPickerDialog(
      context: context,
      name: note.title,
      onIconSelected: (newIcon) {
        provider.updateNoteIcon(note, newIcon);
      },
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

  Future<void> _showSortDialog(BuildContext context) async {
    final provider = Provider.of<NoteListProvider>(context, listen: false);
    String sortType = provider.sortType;
    bool sortAscending = provider.sortAscending;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Urutkan Catatan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Urutkan berdasarkan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Tanggal Modifikasi'),
                    value: 'modifiedAt',
                    groupValue: sortType,
                    onChanged: (value) =>
                        setDialogState(() => sortType = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Judul'),
                    value: 'title',
                    groupValue: sortType,
                    onChanged: (value) =>
                        setDialogState(() => sortType = value!),
                  ),
                  const Divider(),
                  const Text(
                    'Urutan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<bool>(
                    title: Text(sortType == 'title' ? 'A-Z' : 'Terbaru'),
                    value: false,
                    groupValue: sortAscending,
                    onChanged: (value) =>
                        setDialogState(() => sortAscending = false),
                  ),
                  RadioListTile<bool>(
                    title: Text(sortType == 'title' ? 'Z-A' : 'Terlama'),
                    value: true,
                    groupValue: sortAscending,
                    onChanged: (value) =>
                        setDialogState(() => sortAscending = true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    bool isAsc = sortType == 'title'
                        ? sortAscending
                        : !sortAscending;
                    provider.applySort(sortType, isAsc);
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteListProvider(widget.topicName),
      child: Consumer<NoteListProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.topicName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortDialog(context),
                  tooltip: 'Urutkan Catatan',
                ),
              ],
            ),
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
                              // ==> TAMPILKAN IKON CATATAN <==
                              leading: Text(
                                note.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
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
                                  } else if (value == 'icon') {
                                    _showChangeIconDialog(context, note);
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
                                  // ==> MENU BARU <==
                                  const PopupMenuItem(
                                    value: 'icon',
                                    child: Text('Ubah Ikon'),
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
