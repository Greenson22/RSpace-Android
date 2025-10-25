// lib/features/notes/presentation/pages/structured_note_editor_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:my_aplication/features/notes/infrastructure/note_service.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class StructuredNoteEditorPage extends StatefulWidget {
  final String topicName;
  final Note? note; // Bisa null jika membuat baru

  const StructuredNoteEditorPage({
    super.key,
    required this.topicName,
    this.note,
  });

  @override
  State<StructuredNoteEditorPage> createState() =>
      _StructuredNoteEditorPageState();
}

class _StructuredNoteEditorPageState extends State<StructuredNoteEditorPage> {
  final NoteService _noteService = NoteService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late Note _currentNote;
  bool _isSaving = false;

  // State untuk mengelola input field definisi dan data
  List<TextEditingController> _fieldDefControllers = [];
  List<List<TextEditingController>> _dataEntryControllers = [];

  @override
  void initState() {
    super.initState();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _currentNote =
        widget.note ??
        Note(
          title: '',
          content: '', // Konten tidak digunakan di sini
          icon: themeProvider.defaultNoteIcon,
          type: NoteType.structured, // Set tipe ke structured
          fieldDefinitions: ['Field 1'], // Default field awal
          dataEntries: [],
        );

    // Jika note yang ada bukan structured, konversi (atau beri error)
    if (widget.note != null && widget.note!.type != NoteType.structured) {
      _currentNote.type = NoteType.structured;
      if (_currentNote.fieldDefinitions.isEmpty) {
        _currentNote.fieldDefinitions = [
          'Field 1',
        ]; // Pastikan ada field default
      }
      _currentNote.dataEntries = []; // Kosongkan data lama jika ada
      _currentNote.content = ''; // Kosongkan konten teks
      _currentNote.icon = '📊'; // Ganti ikon
    }

    _titleController = TextEditingController(text: _currentNote.title);

    // Inisialisasi controller untuk field definitions
    _fieldDefControllers = _currentNote.fieldDefinitions
        .map((field) => TextEditingController(text: field))
        .toList();

    // Inisialisasi controller untuk data entries
    _dataEntryControllers = _currentNote.dataEntries.map((entry) {
      return _currentNote.fieldDefinitions.map((field) {
        return TextEditingController(text: entry[field] ?? '');
      }).toList();
    }).toList();

    // Pastikan selalu ada minimal satu field definition controller
    if (_fieldDefControllers.isEmpty) {
      _addFieldDefinition();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _fieldDefControllers) {
      controller.dispose();
    }
    for (var rowControllers in _dataEntryControllers) {
      for (var controller in rowControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _addFieldDefinition() {
    setState(() {
      final newController = TextEditingController(text: 'Field Baru');
      _fieldDefControllers.add(newController);
      // Tambahkan controller kosong ke setiap data entry yang sudah ada
      for (var rowControllers in _dataEntryControllers) {
        rowControllers.add(TextEditingController());
      }
    });
  }

  void _removeFieldDefinition(int index) {
    if (_fieldDefControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada satu field.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _fieldDefControllers[index].dispose();
      _fieldDefControllers.removeAt(index);
      // Hapus controller terkait dari setiap data entry
      for (var rowControllers in _dataEntryControllers) {
        if (rowControllers.length > index) {
          rowControllers[index].dispose();
          rowControllers.removeAt(index);
        }
      }
    });
  }

  void _addDataEntry() {
    setState(() {
      _dataEntryControllers.add(
        List.generate(
          _fieldDefControllers.length,
          (_) => TextEditingController(),
        ),
      );
    });
  }

  void _removeDataEntry(int index) {
    setState(() {
      for (var controller in _dataEntryControllers[index]) {
        controller.dispose();
      }
      _dataEntryControllers.removeAt(index);
    });
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    // Validasi tambahan: cek nama field tidak boleh kosong
    for (int i = 0; i < _fieldDefControllers.length; i++) {
      if (_fieldDefControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nama Field ke-${i + 1} tidak boleh kosong.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    _currentNote.title = _titleController.text;
    _currentNote.modifiedAt = DateTime.now();

    // Update field definitions dari controllers
    _currentNote.fieldDefinitions = _fieldDefControllers
        .map((c) => c.text.trim())
        .toList();

    // Update data entries dari controllers
    _currentNote.dataEntries = _dataEntryControllers.map((rowControllers) {
      final entry = <String, String>{};
      for (int i = 0; i < _currentNote.fieldDefinitions.length; i++) {
        if (i < rowControllers.length) {
          // Safety check
          entry[_currentNote.fieldDefinitions[i]] = rowControllers[i].text;
        }
      }
      return entry;
    }).toList();

    // Pastikan tipe adalah structured sebelum menyimpan
    _currentNote.type = NoteType.structured;
    _currentNote.content = ''; // Kosongkan content teks

    try {
      await _noteService.saveNote(widget.topicName, _currentNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _changeIcon() {
    showIconPickerDialog(
      context: context,
      name: _titleController.text.isNotEmpty
          ? _titleController.text
          : "Catatan Terstruktur",
      onIconSelected: (newIcon) {
        setState(() {
          _currentNote.icon = newIcon;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'Catatan Terstruktur Baru' : 'Edit Catatan',
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Simpan Catatan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Judul dan Ikon ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                    child: InkWell(
                      onTap: _changeIcon,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentNote.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Catatan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? 'Judul tidak boleh kosong'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Manajemen Field Definitions ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Definisi Field (Kolom)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addFieldDefinition,
                    tooltip: 'Tambah Field',
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fieldDefControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fieldDefControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Nama Field ${index + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeFieldDefinition(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 24),

              // --- Manajemen Data Entries ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Data Entri (Baris)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addDataEntry,
                    tooltip: 'Tambah Data',
                  ),
                ],
              ),
              Expanded(
                child: _dataEntryControllers.isEmpty
                    ? const Center(
                        child: Text('Belum ada data. Klik + untuk menambah.'),
                      )
                    : ListView.builder(
                        itemCount: _dataEntryControllers.length,
                        itemBuilder: (context, rowIndex) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _fieldDefControllers.length,
                                    itemBuilder: (context, colIndex) {
                                      // Pastikan controller ada sebelum diakses
                                      if (colIndex >=
                                          _dataEntryControllers[rowIndex]
                                              .length) {
                                        return const SizedBox.shrink(); // Atau tampilkan error/placeholder
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: TextFormField(
                                          controller:
                                              _dataEntryControllers[rowIndex][colIndex],
                                          decoration: InputDecoration(
                                            labelText:
                                                _fieldDefControllers.length >
                                                    colIndex
                                                ? _fieldDefControllers[colIndex]
                                                          .text
                                                          .trim()
                                                          .isNotEmpty
                                                      ? _fieldDefControllers[colIndex]
                                                            .text
                                                            .trim()
                                                      : 'Field ${colIndex + 1}' // Fallback label
                                                : 'Field ${colIndex + 1}', // Fallback jika controller tidak ada
                                            border: const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _removeDataEntry(rowIndex),
                                      tooltip: 'Hapus Data Ini',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
