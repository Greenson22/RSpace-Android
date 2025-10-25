// lib/features/notes/presentation/pages/note_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/notes/application/note_list_provider.dart';
import 'package:my_aplication/features/notes/application/note_topic_provider.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart'; // Import Note model
import 'package:my_aplication/features/notes/presentation/pages/note_editor_page.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_view_page.dart';
import 'package:provider/provider.dart';
// Import ThemeProvider
import 'package:my_aplication/features/settings/application/theme_provider.dart';
// ==> Import Editor & Viewer Baru <==
import 'structured_note_editor_page.dart';
import 'structured_note_view_page.dart';

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

  // Fungsi dialog _showRenameDialog, _showChangeIconDialog, _showDeleteDialog, _showMoveDialog, _showSortDialog tidak berubah
  // ... (Salin fungsi-fungsi dialog dari kode Anda sebelumnya ke sini) ...
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

  Future<void> _showMoveDialog(BuildContext context) async {
    final noteListProvider = Provider.of<NoteListProvider>(
      context,
      listen: false,
    );

    final destinationTopic = await showDialog<String>(
      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => NoteTopicProvider(),
        child: Consumer<NoteTopicProvider>(
          builder: (context, topicProvider, child) {
            final topics = topicProvider.topics
                .where((t) => t.name != widget.topicName)
                .toList();
            return SimpleDialog(
              title: const Text('Pindahkan ke Topik...'),
              children: topics
                  .map(
                    (topic) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, topic.name),
                      child: Text(topic.name),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );

    if (destinationTopic != null) {
      await noteListProvider.moveSelected(destinationTopic);
    }
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
                    value: false, // Perbaikan: false untuk terbaru/A-Z
                    groupValue: sortAscending,
                    onChanged: (value) =>
                        setDialogState(() => sortAscending = false),
                  ),
                  RadioListTile<bool>(
                    title: Text(sortType == 'title' ? 'Z-A' : 'Terlama'),
                    value: true, // Perbaikan: true untuk terlama/Z-A
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
                    // Logika sortAscending dibalik untuk date
                    bool isActuallyAscending = sortType == 'title'
                        ? sortAscending
                        : !sortAscending;
                    provider.applySort(sortType, isActuallyAscending);
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

  // ==> Fungsi untuk menampilkan dialog pilihan tipe catatan <==
  Future<NoteType?> _showNoteTypeSelectionDialog(BuildContext context) {
    return showDialog<NoteType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Tipe Catatan Baru'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, NoteType.text),
            child: const ListTile(
              leading: Icon(Icons.notes),
              title: Text('Catatan Teks Biasa'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, NoteType.structured),
            child: const ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text('Catatan Terstruktur'),
              subtitle: Text('(Buat field sendiri)'),
            ),
          ),
        ],
      ),
    );
  }

  // ==> Fungsi untuk navigasi ke editor yang sesuai <==
  void _navigateToEditor(BuildContext context, NoteType type, {Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (type == NoteType.structured) {
            return StructuredNoteEditorPage(
              topicName: widget.topicName,
              note: note,
            );
          } else {
            return NoteEditorPage(topicName: widget.topicName, note: note);
          }
        },
      ),
      // Refresh list setelah kembali dari editor
    ).then(
      (_) => Provider.of<NoteListProvider>(context, listen: false).fetchNotes(),
    );
  }

  // ==> Fungsi untuk navigasi ke viewer yang sesuai <==
  void _navigateToViewer(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (note.type == NoteType.structured) {
            return StructuredNoteViewPage(
              topicName: widget.topicName,
              note: note,
            );
          } else {
            return NoteViewPage(topicName: widget.topicName, note: note);
          }
        },
      ),
      // Refresh list setelah kembali dari viewer (jika ada perubahan di sana nanti)
    ).then(
      (_) => Provider.of<NoteListProvider>(context, listen: false).fetchNotes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteListProvider(widget.topicName),
      child: Consumer<NoteListProvider>(
        builder: (context, provider, child) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final isTransparent =
              themeProvider.backgroundImagePath != null ||
              themeProvider.isUnderwaterTheme;

          return Scaffold(
            backgroundColor: isTransparent ? Colors.transparent : null,
            appBar: provider.isSelectionMode
                ? AppBar(
                    // ... (AppBar mode seleksi tetap sama) ...
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => provider.clearSelection(),
                    ),
                    title: Text('${provider.selectedNotes.length} dipilih'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.drive_file_move_outline),
                        onPressed: () => _showMoveDialog(context),
                        tooltip: 'Pindahkan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed =
                              await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Catatan?'),
                                  content: Text(
                                    'Anda yakin ingin menghapus ${provider.selectedNotes.length} catatan yang dipilih?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (confirmed) {
                            await provider.deleteSelected();
                          }
                        },
                        tooltip: 'Hapus',
                      ),
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () => provider.selectAll(),
                        tooltip: 'Pilih Semua',
                      ),
                    ],
                  )
                : AppBar(
                    backgroundColor: isTransparent ? Colors.transparent : null,
                    elevation: isTransparent ? 0 : null,
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
                            final isSelected = provider.selectedNotes.contains(
                              note,
                            );
                            return ListTile(
                              tileColor: isSelected
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.2)
                                  : null,
                              leading: Text(
                                note.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(note.title),
                              subtitle: Text(
                                // ==> Tampilkan jumlah data jika terstruktur
                                note.type == NoteType.structured
                                    ? '${note.dataEntries.length} data entries • ${DateFormat.yMd().add_jm().format(note.modifiedAt)}'
                                    : 'Diperbarui: ${DateFormat.yMd().add_jm().format(note.modifiedAt)}',
                              ),
                              trailing: provider.isSelectionMode
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        // ==> Arahkan ke editor yang sesuai
                                        if (value == 'edit') {
                                          _navigateToEditor(
                                            context,
                                            note.type,
                                            note: note,
                                          );
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
                                        // ==> Ubah teks menu 'Lihat' menjadi 'Edit'
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Lihat / Edit Catatan'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'rename',
                                          child: Text('Ubah Judul'),
                                        ),
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
                                if (provider.isSelectionMode) {
                                  provider.toggleSelection(note);
                                } else {
                                  // ==> Arahkan ke viewer yang sesuai
                                  _navigateToViewer(context, note);
                                }
                              },
                              onLongPress: () {
                                provider.toggleSelection(note);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: provider.isSelectionMode
                ? null
                : FloatingActionButton(
                    onPressed: () async {
                      // ==> Tampilkan dialog pemilihan tipe
                      final selectedType = await _showNoteTypeSelectionDialog(
                        context,
                      );
                      if (selectedType != null) {
                        _navigateToEditor(context, selectedType);
                      }
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
