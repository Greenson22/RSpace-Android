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

// ==> TAMBAHKAN 'SingleTickerProviderStateMixin' <==
class _StructuredNoteEditorPageState extends State<StructuredNoteEditorPage>
    with SingleTickerProviderStateMixin {
  final NoteService _noteService = NoteService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late Note _currentNote;
  bool _isSaving = false;

  // State untuk mengelola input field definisi dan data
  List<TextEditingController> _fieldDefControllers = [];
  List<List<TextEditingController>> _dataEntryControllers = [];

  // ==> Controller untuk TabBar <==
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // ==> Inisialisasi TabController <==
    _tabController = TabController(length: 2, vsync: this); // 2 tab

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    _currentNote =
        widget.note ??
        Note(
          title: '',
          icon: '📊', // Icon default untuk structured
          type: NoteType.structured,
          fieldDefinitions: ['Field 1'],
          dataEntries: [],
        );

    if (widget.note != null && widget.note!.type != NoteType.structured) {
      _currentNote.type = NoteType.structured;
      if (_currentNote.fieldDefinitions.isEmpty) {
        _currentNote.fieldDefinitions = ['Field 1'];
      }
      _currentNote.dataEntries = [];
      _currentNote.content = '';
      _currentNote.icon = '📊';
    }

    _titleController = TextEditingController(text: _currentNote.title);

    _fieldDefControllers = _currentNote.fieldDefinitions
        .map((field) => TextEditingController(text: field))
        .toList();

    _dataEntryControllers = _currentNote.dataEntries.map((entry) {
      return _currentNote.fieldDefinitions.map((field) {
        return TextEditingController(text: entry[field] ?? '');
      }).toList();
    }).toList();

    if (_fieldDefControllers.isEmpty) {
      _addFieldDefinition(); // Panggil setelah inisialisasi awal
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController
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
      for (var rowControllers in _dataEntryControllers) {
        // Tambahkan controller baru ke setiap baris data yang ada
        rowControllers.add(TextEditingController());
      }
      // Pindah ke tab Definisi Field jika baru ditambahkan
      _tabController.animateTo(1);
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
    // Konfirmasi sebelum menghapus
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Field?'),
        content: Text(
          'Anda yakin ingin menghapus field "${_fieldDefControllers[index].text}" beserta datanya di semua entri?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog konfirmasi
              setState(() {
                _fieldDefControllers[index].dispose();
                _fieldDefControllers.removeAt(index);
                // Hapus data terkait di semua entri
                for (var rowControllers in _dataEntryControllers) {
                  if (rowControllers.length > index) {
                    rowControllers[index].dispose();
                    rowControllers.removeAt(index);
                  }
                }
              });
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addDataEntry() {
    setState(() {
      _dataEntryControllers.add(
        List.generate(
          _fieldDefControllers.length,
          (_) => TextEditingController(),
        ),
      );
      // Pindah ke tab Data Entri jika baru ditambahkan
      _tabController.animateTo(0);
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
    for (int i = 0; i < _fieldDefControllers.length; i++) {
      if (_fieldDefControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nama Field ke-${i + 1} tidak boleh kosong.'),
            backgroundColor: Colors.red,
          ),
        );
        _tabController.animateTo(1); // Arahkan ke tab field
        return;
      }
    }

    setState(() => _isSaving = true);

    _currentNote.title = _titleController.text;
    _currentNote.modifiedAt = DateTime.now();
    _currentNote.icon = _currentNote.icon; // Pastikan ikon tersimpan

    _currentNote.fieldDefinitions = _fieldDefControllers
        .map((c) => c.text.trim())
        .toList();

    _currentNote.dataEntries = _dataEntryControllers.map((rowControllers) {
      final entry = <String, String>{};
      for (int i = 0; i < _currentNote.fieldDefinitions.length; i++) {
        if (i < rowControllers.length) {
          entry[_currentNote.fieldDefinitions[i]] = rowControllers[i].text;
        } else {
          entry[_currentNote.fieldDefinitions[i]] =
              ''; // Handle jika controller kurang
        }
      }
      // Hapus field yang tidak ada lagi definisinya dari entri data
      entry.removeWhere(
        (key, value) => !_currentNote.fieldDefinitions.contains(key),
      );
      return entry;
    }).toList();

    _currentNote.type = NoteType.structured;
    _currentNote.content = '';

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
        // ==> Tambahkan TabBar di AppBar <==
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Data Entri'),
            Tab(icon: Icon(Icons.edit_note), text: 'Definisi Field'),
          ],
        ),
      ),
      // ==> Ubah Body menjadi TabBarView <==
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // Pindahkan Form ke sini agar validasi bekerja di kedua tab
          key: _formKey,
          child: Column(
            children: [
              // --- Judul dan Ikon (tetap di atas TabBarView) ---
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
              // --- TabBarView untuk konten ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDataEntriesTab(), // Tab untuk Data Entri
                    _buildFieldDefinitionsTab(), // Tab untuk Definisi Field
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==> Widget untuk Tab Definisi Field <==
  Widget _buildFieldDefinitionsTab() {
    // Gunakan ListView agar bisa di-scroll jika field banyak
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
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
                        // Validasi bisa ditambahkan di sini jika perlu
                        // validator: (value) => value!.trim().isEmpty ? 'Nama field kosong' : null,
                        onChanged: (_) => setState(
                          () {},
                        ), // Update UI saat nama field berubah
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
        ],
      ),
    );
  }

  // ==> Widget untuk Tab Data Entri <==
  Widget _buildDataEntriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
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
        ),
        Expanded(
          child: _dataEntryControllers.isEmpty
              ? const Center(
                  child: Text('Belum ada data. Klik + untuk menambah.'),
                )
              : ListView.builder(
                  itemCount: _dataEntryControllers.length,
                  itemBuilder: (context, rowIndex) {
                    // Pastikan jumlah controller di baris data sesuai dengan jumlah field
                    // Ini penting jika field baru saja ditambahkan/dihapus
                    while (_dataEntryControllers[rowIndex].length <
                        _fieldDefControllers.length) {
                      _dataEntryControllers[rowIndex].add(
                        TextEditingController(),
                      );
                    }
                    while (_dataEntryControllers[rowIndex].length >
                        _fieldDefControllers.length) {
                      _dataEntryControllers[rowIndex].removeLast().dispose();
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _fieldDefControllers
                                  .length, // Gunakan jumlah field def
                              itemBuilder: (context, colIndex) {
                                // Dapatkan nama field yang benar
                                final fieldName =
                                    _fieldDefControllers[colIndex].text
                                        .trim()
                                        .isNotEmpty
                                    ? _fieldDefControllers[colIndex].text.trim()
                                    : 'Field ${colIndex + 1}'; // Fallback

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: TextFormField(
                                    controller:
                                        _dataEntryControllers[rowIndex][colIndex],
                                    decoration: InputDecoration(
                                      labelText:
                                          fieldName, // Gunakan nama field sebagai label
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
                                onPressed: () => _removeDataEntry(rowIndex),
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
    );
  }
}

// Widget _AddRangedSubMateriDialog tidak diperlukan di file ini, hapus jika ada.
