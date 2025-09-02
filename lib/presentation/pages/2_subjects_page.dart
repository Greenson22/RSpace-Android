// lib/presentation/pages/2_subjects_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/models/subject_model.dart';
import '../providers/discussion_provider.dart';
import '../providers/subject_provider.dart';
import '3_discussions_page.dart';
import '2_subjects_page/dialogs/subject_dialogs.dart';
import '2_subjects_page/widgets/subject_grid_tile.dart';
import '2_subjects_page/widgets/subject_list_tile.dart';
import '../widgets/ad_banner_widget.dart';

class SubjectsPage extends StatefulWidget {
  final String topicName;

  const SubjectsPage({super.key, required this.topicName});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = 0;

  Timer? _focusTimer;
  bool _isKeyboardActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    _searchController.addListener(() {
      final provider = Provider.of<SubjectProvider>(context, listen: false);
      provider.search(_searchController.text);
      setState(() => _focusedIndex = 0);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      return;
    }

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isKeyboardActive = false);
        });

        final provider = Provider.of<SubjectProvider>(context, listen: false);
        final totalItems = provider.filteredSubjects.length;
        if (totalItems == 0) return;

        int crossAxisCount = (MediaQuery.of(context).size.width > 600)
            ? (MediaQuery.of(context).size.width / 200).floor()
            : 1;

        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusedIndex = (_focusedIndex + crossAxisCount);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _focusedIndex = (_focusedIndex - crossAxisCount);
            if (_focusedIndex < 0) _focusedIndex = 0;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _focusedIndex = (_focusedIndex + 1);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _focusedIndex = (_focusedIndex - 1);
            if (_focusedIndex < 0) _focusedIndex = 0;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final provider = Provider.of<SubjectProvider>(context, listen: false);
        if (_focusedIndex < provider.filteredSubjects.length) {
          _navigateToDiscussionsPage(
            context,
            provider.filteredSubjects[_focusedIndex],
          );
        }
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // ==> FUNGSI DIPERBARUI: Sekarang hanya memanggil dialog baru <==
  Future<void> _linkSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final newPath = await showLinkOrCreatePerpuskuDialog(
      context: context,
      forSubjectName: subject.name,
    );

    if (newPath != null) {
      try {
        await provider.updateSubjectLinkedPath(subject.name, newPath);
        _showSnackBar('Subject "${subject.name}" berhasil ditautkan.');
      } catch (e) {
        _showSnackBar(
          'Gagal menautkan subject: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // ==> FUNGSI DIPERBARUI: Alur diubah total <==
  Future<void> _addSubject(BuildContext context) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    // Langkah 1: Minta nama subject RSpace
    await showSubjectTextInputDialog(
      context: context,
      title: 'Tambah Subject Baru (Langkah 1/2)',
      label: 'Nama Subject di RSpace',
      onSave: (name) async {
        // Langkah 2: Setelah nama didapat, langsung minta untuk menautkan/membuat folder PerpusKu
        final newPath = await showLinkOrCreatePerpuskuDialog(
          context: context,
          forSubjectName: name,
        );

        // Langkah 3: Jika path berhasil didapat, baru buat subject RSpace dan simpan pathnya
        if (newPath != null) {
          try {
            // Buat subject di RSpace
            await provider.addSubject(name);
            // Langsung update dengan linkedPath yang baru
            await provider.updateSubjectLinkedPath(name, newPath);
            _showSnackBar(
              'Subject "$name" berhasil ditambahkan dan ditautkan.',
            );
          } catch (e) {
            _showSnackBar(e.toString(), isError: true);
          }
        }
      },
    );
  }

  Future<void> _renameSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showSubjectTextInputDialog(
      context: context,
      title: 'Ubah Nama Subject',
      label: 'Nama Baru',
      initialValue: subject.name,
      onSave: (newName) async {
        try {
          await provider.renameSubject(subject.name, newName);
          _showSnackBar('Subject berhasil diubah menjadi "$newName".');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showDeleteConfirmationDialog(
      context: context,
      subjectName: subject.name,
      onDelete: () async {
        try {
          await provider.deleteSubject(subject.name);
          _showSnackBar('Subject "${subject.name}" berhasil dihapus.');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> _changeIcon(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showIconPickerDialog(
      context: context,
      name: subject.name, // Kirim nama subject
      onIconSelected: (newIcon) async {
        try {
          await provider.updateSubjectIcon(subject.name, newIcon);
          _showSnackBar('Ikon untuk "${subject.name}" diubah.');
        } catch (e) {
          _showSnackBar('Gagal mengubah ikon: ${e.toString()}', isError: true);
        }
      },
    );
  }

  Future<void> _toggleVisibility(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final newVisibility = !subject.isHidden;
    try {
      await provider.toggleSubjectVisibility(subject.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      _showSnackBar('Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  // ==> FUNGSI DIPERBARUI: Menangani penautan wajib sebelum navigasi <==
  // ==> FUNGSI BARU UNTUK MENANGANI AKSI EDIT <==
  Future<void> _editIndexFile(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    try {
      await provider.editSubjectIndexFile(subject);
    } catch (e) {
      _showSnackBar('Gagal membuka file: ${e.toString()}', isError: true);
    }
  }

  // ... (sisa fungsi tidak berubah)

  Future<void> _navigateToDiscussionsPage(
    BuildContext context,
    Subject subject,
  ) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );

    String? currentLinkedPath = subject.linkedPath;

    // Jika belum tertaut, paksa pengguna untuk menautkan
    if (currentLinkedPath == null || currentLinkedPath.isEmpty) {
      final newPath = await showLinkOrCreatePerpuskuDialog(
        context: context,
        forSubjectName: subject.name,
      );

      // ==> PERBAIKAN DIMULAI DI SINI <==
      // Cek apakah widget masih ada setelah dialog ditutup.
      if (!mounted) return;
      // ==> PERBAIKAN SELESAI DI SINI <==

      if (newPath != null) {
        try {
          await subjectProvider.updateSubjectLinkedPath(subject.name, newPath);
          currentLinkedPath = newPath; // Update path untuk navigasi
        } catch (e) {
          _showSnackBar(
            'Gagal menautkan subject: ${e.toString()}',
            isError: true,
          );
          return; // Hentikan navigasi jika penautan gagal
        }
      } else {
        return; // Hentikan navigasi jika pengguna membatalkan dialog
      }
    }

    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );

    // Pastikan untuk menggunakan context yang aman di sini juga.
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(jsonFilePath),
          child: DiscussionsPage(
            subjectName: subject.name,
            linkedPath: currentLinkedPath,
          ),
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      subjectProvider.fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? _buildSearchField()
              : Text(
                  'Subjects: ${widget.topicName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchController.clear();
                });
              },
            ),
            IconButton(
              icon: Icon(
                provider.showHiddenSubjects
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => provider.toggleShowHidden(),
              tooltip: provider.showHiddenSubjects
                  ? 'Sembunyikan Subjects Tersembunyi'
                  : 'Tampilkan Subjects Tersembunyi',
            ),
          ],
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return _buildGridView(context);
                  } else {
                    return _buildListView(context);
                  }
                },
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addSubject(context),
          tooltip: 'Tambah Subject',
          icon: const Icon(Icons.add),
          label: const Text('Tambah Subject'),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Cari subject...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.filteredSubjects.isEmpty) {
          return _buildEmptyState(provider);
        }
        final subjectsToShow = provider.filteredSubjects;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subject = subjectsToShow[index];
            return SubjectListTile(
              key: ValueKey(subject.name),
              subject: subject,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: () => _navigateToDiscussionsPage(context, subject),
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
              onLinkPath: () => _linkSubject(context, subject),
              // ==> TAMBAHKAN PROPERTI BARU <==
              onEditIndexFile: () => _editIndexFile(context, subject),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.filteredSubjects.isEmpty) {
          return _buildEmptyState(provider);
        }
        final subjectsToShow = provider.filteredSubjects;
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width / 200).floor(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subject = subjectsToShow[index];
            return SubjectGridTile(
              key: ValueKey(subject.name),
              subject: subject,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: () => _navigateToDiscussionsPage(context, subject),
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
              onLinkPath: () => _linkSubject(context, subject),
              // ==> TAMBAHKAN PROPERTI BARU <==
              onEditIndexFile: () => _editIndexFile(context, subject),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(SubjectProvider provider) {
    if (provider.allSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Subject',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah subject di topik ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    final isSearching = provider.searchQuery.isNotEmpty;
    if (provider.filteredSubjects.isEmpty) {
      if (isSearching) {
        return const Center(child: Text('Subject tidak ditemukan.'));
      } else if (!provider.showHiddenSubjects) {
        return const Center(
          child: Text(
            'Tidak ada subject yang terlihat.\nCoba tampilkan subject tersembunyi.',
            textAlign: TextAlign.center,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
