// lib/features/content_management/presentation/subjects/subjects_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../domain/models/subject_model.dart';
import '../../application/discussion_provider.dart';
import '../../application/subject_provider.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/discussions_page.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/subject_dialogs.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/move_subject_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/subject_sort_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/widgets/subject_grid_tile.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/widgets/subject_list_tile.dart';
import 'package:my_aplication/core/widgets/ad_banner_widget.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/generate_index_template_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/generate_index_prompt_dialog.dart';
import 'package:my_aplication/features/html_editor/presentation/pages/html_editor_page.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/subject_password_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/timeline/discussion_timeline_page.dart';
import 'dialogs/view_json_dialog.dart';
import '../../../settings/application/theme_provider.dart';

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

  Future<void> _showJsonContent(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final content = await provider.getRawJsonContent(subject);
    if (mounted) {
      showViewJsonDialog(context, subject.name, content);
    }
  }

  Future<void> _toggleLock(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    if (subject.isLocked) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(subject.name),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'unlock'),
              child: const ListTile(
                leading: Icon(Icons.lock_open),
                title: Text('Buka Kunci'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'remove'),
              child: const ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Hapus Kunci Permanen'),
              ),
            ),
          ],
        ),
      );

      if (choice == 'unlock' && mounted) {
        final password = await showSubjectPasswordDialog(
          context: context,
          subjectName: subject.name,
          mode: PasswordDialogMode.enter,
        );
        if (password != null) {
          try {
            await provider.unlockSubject(subject.name, password);
          } catch (e) {
            _showSnackBar(e.toString(), isError: true);
          }
        }
      } else if (choice == 'remove' && mounted) {
        final password = await showSubjectPasswordDialog(
          context: context,
          subjectName: subject.name,
          mode: PasswordDialogMode.remove,
        );
        if (password != null) {
          try {
            await provider.removeLock(subject.name, password);
            _showSnackBar(
              'Kunci pada subject "${subject.name}" telah dihapus.',
            );
          } catch (e) {
            _showSnackBar(e.toString(), isError: true);
          }
        }
      }
    } else {
      final password = await showSubjectPasswordDialog(
        context: context,
        subjectName: subject.name,
        mode: PasswordDialogMode.set,
      );
      if (password != null) {
        try {
          await provider.lockSubject(subject.name, password);
          _showSnackBar('Subject "${subject.name}" berhasil dikunci.');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      }
    }
  }

  Future<void> _moveSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    final destinationTopic = await showMoveSubjectDialog(
      context,
      widget.topicName,
    );

    if (destinationTopic != null && mounted) {
      try {
        await provider.moveSubject(subject, destinationTopic);
        _showSnackBar(
          'Subject "${subject.name}" berhasil dipindahkan ke topik "${destinationTopic.name}".',
        );
      } catch (e) {
        _showSnackBar('Gagal memindahkan: ${e.toString()}', isError: true);
      }
    }
  }

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

  Future<void> _addSubject(BuildContext context) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    await showSubjectTextInputDialog(
      context: context,
      title: 'Tambah Subject Baru (Langkah 1/2)',
      label: 'Nama Subject di RSpace',
      onSave: (name) async {
        final newPath = await showLinkOrCreatePerpuskuDialog(
          context: context,
          forSubjectName: name,
        );

        if (newPath != null) {
          try {
            await provider.addSubject(name);
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

    final result = await showDeleteConfirmationDialog(
      context: context,
      subjectName: subject.name,
      linkedPath: subject.linkedPath,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await provider.deleteSubject(
          subject.name,
          deleteLinkedFolder: result['deleteFolder'] ?? false,
        );
        _showSnackBar('Subject "${subject.name}" berhasil dihapus.');
      } catch (e) {
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _changeIcon(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showIconPickerDialog(
      context: context,
      name: subject.name,
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

  Future<void> _toggleFreeze(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    try {
      await provider.toggleSubjectFreeze(subject.name);
      final message = subject.isFrozen ? 'diaktifkan kembali' : 'dibekukan';
      _showSnackBar('Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _showEditIndexOptions(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final editorChoice = themeProvider.defaultHtmlEditor;

    Future<void> openInternalEditor() async {
      try {
        final content = await provider.readIndexFileContent(subject);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HtmlEditorPage(
                pageTitle: 'Template: ${subject.name}',
                initialContent: content,
                onSave: (newContent) =>
                    provider.saveIndexFileContent(subject, newContent),
              ),
            ),
          );
        }
      } catch (e) {
        _showSnackBar('Gagal memuat konten: ${e.toString()}', isError: true);
      }
    }

    Future<void> openExternalEditor() async {
      try {
        await provider.editSubjectIndexFile(subject);
      } catch (e) {
        _showSnackBar('Gagal membuka file: ${e.toString()}', isError: true);
      }
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Metode Edit Template'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ai_direct'),
            child: const ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Generate dengan AI (Otomatis)'),
              subtitle: Text('Buat & simpan template baru berdasarkan tema.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ai_prompt'),
            child: const ListTile(
              leading: Icon(Icons.copy_all_outlined),
              title: Text('Generate Prompt (Manual)'),
              subtitle: Text('Buat prompt untuk digunakan di Gemini Web.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context); // Close the options dialog first
              if (editorChoice == 'internal') {
                await openInternalEditor();
              } else if (editorChoice == 'external') {
                await openExternalEditor();
              } else {
                // If no default is set, show the choice dialog
                final subChoice = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Pilih Editor'),
                    content: const Text(
                      'Buka dengan editor internal atau aplikasi eksternal?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'internal'),
                        child: const Text('Internal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'external'),
                        child: const Text('Eksternal'),
                      ),
                    ],
                  ),
                );
                if (subChoice == 'internal') {
                  await openInternalEditor();
                } else if (subChoice == 'external') {
                  await openExternalEditor();
                }
              }
            },
            child: const ListTile(
              leading: Icon(Icons.edit_document),
              title: Text('Edit Manual'),
              subtitle: Text('Buka file index.html di editor.'),
            ),
          ),
        ],
      ),
    );

    if (choice == 'ai_direct' && mounted) {
      final success = await showDialog<bool>(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: GenerateIndexTemplateDialog(subject: subject),
        ),
      );
      if (success == true && mounted) {
        _showSnackBar('Template baru berhasil dibuat oleh AI!');
      }
    } else if (choice == 'ai_prompt' && mounted) {
      await showGenerateIndexPromptDialog(context, subject);
    }
  }

  Future<void> _navigateToDiscussionsPage(
    BuildContext context,
    Subject subject,
  ) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );

    if (subject.isLocked && !subjectProvider.isUnlocked(subject.name)) {
      final password = await showSubjectPasswordDialog(
        context: context,
        subjectName: subject.name,
        mode: PasswordDialogMode.enter,
      );
      if (password == null) return;
      try {
        await subjectProvider.unlockSubject(subject.name, password);
        final unlockedSubject = subjectProvider.allSubjects.firstWhere(
          (s) => s.name == subject.name,
        );
        _navigate(context, unlockedSubject);
      } catch (e) {
        _showSnackBar(e.toString(), isError: true);
        return;
      }
    } else {
      _navigate(context, subject);
    }
  }

  Future<void> _navigate(BuildContext context, Subject subject) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    if (subject.isFrozen) {
      _showSnackBar('Subject ini sedang dibekukan dan tidak bisa dibuka.');
      return;
    }

    String? currentLinkedPath = subject.linkedPath;

    if (currentLinkedPath == null || currentLinkedPath.isEmpty) {
      final newPath = await showLinkOrCreatePerpuskuDialog(
        context: context,
        forSubjectName: subject.name,
      );

      if (!mounted) return;

      if (newPath != null) {
        try {
          await subjectProvider.updateSubjectLinkedPath(subject.name, newPath);
          currentLinkedPath = newPath;
        } catch (e) {
          _showSnackBar(
            'Gagal menautkan subject: ${e.toString()}',
            isError: true,
          );
          return;
        }
      } else {
        return;
      }
    }

    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(
            jsonFilePath,
            linkedPath: currentLinkedPath,
            subject: subject,
          ),
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

  void _navigateToTimelinePage(BuildContext context, Subject subject) {
    if (subject.isLocked &&
        !Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).isUnlocked(subject.name)) {
      _showSnackBar(
        'Buka kunci subjek terlebih dahulu untuk melihat linimasa.',
      );
      return;
    }

    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: subjectProvider,
          child: DiscussionTimelinePage(
            subjectName: subject.name,
            discussions: subject.discussions,
            subjectJsonPath: jsonFilePath,
          ),
        ),
      ),
    ).then((_) {
      subjectProvider.fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTransparent =
        themeProvider.backgroundImagePath != null ||
        themeProvider.isUnderwaterTheme;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isTransparent ? Colors.transparent : null,
        appBar: provider.isSelectionMode
            ? _buildSelectionAppBar(provider)
            : _buildDefaultAppBar(provider, isTransparent),
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
        floatingActionButton: provider.isSelectionMode
            ? null
            : FloatingActionButton(
                onPressed: () => _addSubject(context),
                tooltip: 'Tambah Subject',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  AppBar _buildSelectionAppBar(SubjectProvider provider) {
    return AppBar(
      title: Text('${provider.selectedSubjects.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => provider.selectAllFilteredSubjects(),
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.visibility_off_outlined),
          onPressed: () => provider.toggleVisibilitySelectedSubjects(),
          tooltip: 'Sembunyikan/Tampilkan Pilihan',
        ),
        IconButton(
          icon: const Icon(Icons.ac_unit_outlined),
          onPressed: () => provider.toggleFreezeSelectedSubjects(),
          tooltip: 'Bekukan/Cairkan Pilihan',
        ),
      ],
    );
  }

  AppBar _buildDefaultAppBar(SubjectProvider provider, bool isTransparent) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isTransparent ? 0 : null,
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
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'Urutkan Subject',
          onPressed: () => showSubjectSortDialog(context: context),
        ),
      ],
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
              key: ValueKey(subject.name + subject.position.toString()),
              subject: subject,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: () {
                if (provider.isSelectionMode) {
                  provider.toggleSubjectSelection(subject);
                } else {
                  _navigateToDiscussionsPage(context, subject);
                }
              },
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
              onLinkPath: () => _linkSubject(context, subject),
              onEditIndexFile: () => _showEditIndexOptions(context, subject),
              onMove: () => _moveSubject(context, subject),
              onToggleFreeze: () => _toggleFreeze(context, subject),
              onToggleLock: () => _toggleLock(context, subject),
              onTimeline: () => _navigateToTimelinePage(context, subject),
              onViewJson: () => _showJsonContent(context, subject),
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
              key: ValueKey(subject.name + subject.position.toString()),
              subject: subject,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: () {
                if (provider.isSelectionMode) {
                  provider.toggleSubjectSelection(subject);
                } else {
                  _navigateToDiscussionsPage(context, subject);
                }
              },
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
              onLinkPath: () => _linkSubject(context, subject),
              onEditIndexFile: () => _showEditIndexOptions(context, subject),
              onMove: () => _moveSubject(context, subject),
              onToggleFreeze: () => _toggleFreeze(context, subject),
              onToggleLock: () => _toggleLock(context, subject),
              onTimeline: () => _navigateToTimelinePage(context, subject),
              onViewJson: () => _showJsonContent(context, subject),
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
