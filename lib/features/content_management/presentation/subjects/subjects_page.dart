import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/application/subject_provider.dart';

// Imports Refactored Components
import 'widgets/subjects_app_bar.dart';
import 'widgets/subjects_list_view.dart';
import 'utils/subject_actions_handler.dart';

class SubjectsPage extends StatefulWidget {
  final String topicName;
  const SubjectsPage({super.key, required this.topicName});

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
        event.logicalKey == LogicalKeyboardKey.altRight)
      return;

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

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: SubjectsAppBar(
          topicName: widget.topicName,
          isSelectionMode: provider.isSelectionMode,
          isSearching: _isSearching,
          searchController: _searchController,
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
                onRename: (ctx, subject) =>
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
                onIconChange: (BuildContext p1, p2) {},
              ),
            ),
            // PERUBAHAN DI SINI: AdBannerWidget() telah dihapus dari hirarki Column
          ],
        ),
        floatingActionButton: provider.isSelectionMode
            ? null
            : FloatingActionButton(
                onPressed: () => SubjectActionsHandler.addSubject(context),
                tooltip: 'Tambah Subject',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
