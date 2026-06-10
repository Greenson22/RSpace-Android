import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/subjects/providers/subject_provider.dart';

// Imports Refactored Components
import 'widgets/subjects_app_bar.dart';
import 'widgets/subjects_list_view.dart';
import 'utils/subject_actions_handler.dart';

class SubjectsPage extends StatefulWidget {
  final String topicName;
  final Color themeColor; // <--- 1. TAMBAHKAN PROPERTI WARNA TEMA WARISAN

  // 2. UPDATE CONSTRUCTOR UNTUK MENERIMA WARNA
  const SubjectsPage({
    super.key,
    required this.topicName,
    required this.themeColor, // <--- WAJIB DIISI
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isSearching = false;
  int _focusedIndex = 0;
  bool _isKeyboardActive = false;
  Timer? _focusTimer;

  // 3. SEKARANG DAFTAR _themePalettes DAN FUNGSI _getThemeColorFromTitle TELAH DIHAPUS
  // KARENA KITA MENGGUNAKAN WARNA LANGSUNG DARI widget.themeColor

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
      Provider.of<SubjectProvider>(
        context,
        listen: false,
      ).search(_searchController.text);
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
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isKeyboardActive = false);
        });

        final provider = Provider.of<SubjectProvider>(context, listen: false);
        final totalItems = provider.filteredSubjects.length;
        if (totalItems == 0) return;

        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusedIndex = (_focusedIndex + 1);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _focusedIndex = (_focusedIndex - 1);
            if (_focusedIndex < 0) _focusedIndex = 0;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final provider = Provider.of<SubjectProvider>(context, listen: false);
        if (_focusedIndex < provider.filteredSubjects.length) {
          SubjectActionsHandler.navigateToDiscussionsPage(
            context,
            provider.filteredSubjects[_focusedIndex],
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);

    // 4. SET VARIABEL WARNA LANGSUNG MENGAMBIL DATA DARI WIDGET INDUKNYA
    final Color dynamicThemeColor = widget.themeColor;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: SubjectsAppBar(
          topicName: widget.topicName,
          isSelectionMode: provider.isSelectionMode,
          isSearching: _isSearching,
          searchController: _searchController,
          backgroundColor:
              dynamicThemeColor, // Menggunakan warna tema yang konsisten
          onToggleSearch: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            });
          },
          onMenuSelected: (value) {
            if (value == 'import_zip') {
              SubjectActionsHandler.importSubjectsZip(context);
            } else if (value == 'show_hidden') {
              provider.toggleShowHidden();
            }
          },
          onExportSelected: () => SubjectActionsHandler.exportSelectedSubjects(
            context,
            widget.topicName,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SubjectsListView(
                isKeyboardActive: _isKeyboardActive,
                focusedIndex: _focusedIndex,
                onTap: (ctx, subject) {
                  if (provider.isSelectionMode) {
                    provider.toggleSubjectSelection(subject);
                  } else {
                    SubjectActionsHandler.navigateToDiscussionsPage(
                      ctx,
                      subject,
                    );
                  }
                },
                onEdit: (ctx, subject) =>
                    SubjectActionsHandler.renameSubject(ctx, subject),
                onDelete: (ctx, subject) =>
                    SubjectActionsHandler.deleteSubject(ctx, subject),
                onToggleVisibility: (ctx, subject) =>
                    SubjectActionsHandler.toggleVisibility(ctx, subject),
                onLinkPath: (ctx, subject) =>
                    SubjectActionsHandler.linkSubject(ctx, subject),
                onEditIndexFile: (ctx, subject) =>
                    SubjectActionsHandler.showEditIndexOptions(ctx, subject),
                onMove: (ctx, subject) => SubjectActionsHandler.moveSubject(
                  ctx,
                  subject,
                  widget.topicName,
                ),
                onToggleFreeze: (ctx, subject) =>
                    SubjectActionsHandler.toggleFreeze(ctx, subject),
                onToggleLock: (ctx, subject) =>
                    SubjectActionsHandler.toggleLock(ctx, subject),
                onTimeline: (ctx, subject) =>
                    SubjectActionsHandler.navigateToTimelinePage(ctx, subject),
                onViewJson: (ctx, subject) =>
                    SubjectActionsHandler.showJsonContent(ctx, subject),
                onExport: (ctx, subject) =>
                    SubjectActionsHandler.exportSingleSubjectZip(ctx, subject),
              ),
            ),
          ],
        ),
        floatingActionButton: provider.isSelectionMode
            ? null
            : FloatingActionButton(
                onPressed: () => SubjectActionsHandler.addSubject(context),
                tooltip: 'Tambah Subject',
                backgroundColor:
                    dynamicThemeColor, // Setel warna FAB agar serasi dengan AppBar
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
