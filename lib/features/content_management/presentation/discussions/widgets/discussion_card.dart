// lib/presentation/pages/3_discussions_page/widgets/discussion_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../dialogs/discussion_dialogs.dart';
import '../dialogs/generate_html_dialog.dart';
import '../dialogs/smart_link_dialog.dart';
import 'discussion_point_list.dart';
import 'discussion_tile.dart';
import '../../subjects/subjects_page.dart';

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final bool isFocused;
  final Map<int, bool> arePointsVisible;
  final Function(int) onToggleVisibility;
  final String subjectName;
  final String? subjectLinkedPath;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.index,
    this.isFocused = false,
    required this.arePointsVisible,
    required this.onToggleVisibility,
    required this.subjectName,
    this.subjectLinkedPath,
  });

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isSelected = provider.selectedDiscussions.contains(discussion);

    return Card(
      color: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          DiscussionTile(
            discussion: discussion,
            isSelected: isSelected,
            arePointsVisible: arePointsVisible[index] ?? false,
            subjectLinkedPath: subjectLinkedPath,
            onToggleVisibility: () => onToggleVisibility(index),
            onAddPoint: () => _addPoint(context, provider),
            onMove: () => _moveDiscussion(context, provider),
            onRename: () => _renameDiscussion(context, provider),
            onDateChange: () => _changeDiscussionDate(context, provider),
            onCodeChange: () => _changeDiscussionCode(context, provider),
            onCreateFile: () => _createHtmlFileForDiscussion(
              context,
              provider,
              subjectLinkedPath!,
            ),
            onSetFilePath: () => _setFilePath(context, provider),
            onGenerateHtml: () => _generateHtml(context),
            onEditFile: () => _editFile(context, provider),
            onRemoveFilePath: () => _removeFilePath(context, provider),
            onSmartLink: () => _findSmartLink(context, provider),
            onFinish: () => _markAsFinished(context, provider),
            onReactivate: () => _reactivateDiscussion(context, provider),
            onDelete: () => _deleteDiscussion(context, provider),
          ),
          if (discussion.points.isNotEmpty)
            Visibility(
              visible: arePointsVisible[index] ?? false,
              child: DiscussionPointList(discussion: discussion),
            ),
        ],
      ),
    );
  }

  // --- PRIVATE HELPER METHODS FOR ACTIONS ---

  void _addPoint(BuildContext context, DiscussionProvider provider) {
    showAddPointDialog(
      context: context,
      title: 'Tambah Poin Baru',
      label: 'Teks Poin',
      onSave: (text, inheritCode) {
        provider.addPoint(discussion, text, inheritRepetitionCode: inheritCode);
        _showSnackBar(context, 'Poin berhasil ditambahkan.');
      },
    );
  }

  void _moveDiscussion(
    BuildContext context,
    DiscussionProvider provider,
  ) async {
    if (!provider.isSelectionMode) {
      provider.toggleSelection(discussion);
    }
    final targetInfo = await showMoveDiscussionDialog(context);
    if (targetInfo != null && context.mounted) {
      try {
        final log = await provider.moveSelectedDiscussions(
          targetInfo['jsonPath']!,
          targetInfo['linkedPath'],
        );
        _showSnackBar(context, log);
      } catch (e) {
        _showSnackBar(context, 'Gagal memindahkan: ${e.toString()}');
      }
    }
  }

  void _renameDiscussion(BuildContext context, DiscussionProvider provider) {
    showTextInputDialog(
      context: context,
      title: 'Ubah Nama Diskusi',
      label: 'Nama Baru',
      initialValue: discussion.discussion,
      onSave: (newName) {
        provider.renameDiscussion(discussion, newName);
        _showSnackBar(context, 'Nama diskusi berhasil diubah.');
      },
    );
  }

  void _changeDiscussionDate(
    BuildContext context,
    DiscussionProvider provider,
  ) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(discussion.date ?? '') ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (newDate != null) {
      provider.updateDiscussionDate(discussion, newDate);
      _showSnackBar(context, 'Tanggal diskusi berhasil diubah.');
    }
  }

  void _changeDiscussionCode(
    BuildContext context,
    DiscussionProvider provider,
  ) {
    showRepetitionCodeDialog(
      context,
      discussion.repetitionCode,
      provider.repetitionCodes,
      (newCode) {
        provider.updateDiscussionCode(discussion, newCode);
        _showSnackBar(context, 'Kode repetisi berhasil diubah.');
      },
    );
  }

  void _createHtmlFileForDiscussion(
    BuildContext context,
    DiscussionProvider provider,
    String subjectLinkedPath,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Buat File HTML?'),
            content: Text(
              'Ini akan membuat file .html baru dan menautkannya ke diskusi "${discussion.discussion}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Buat & Tautkan'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      try {
        await provider.createAndLinkHtmlFile(discussion, subjectLinkedPath);
        _showSnackBar(context, 'File HTML berhasil dibuat dan ditautkan.');
      } catch (e) {
        _showSnackBar(context, 'Gagal membuat file: ${e.toString()}');
      }
    }
  }

  void _setFilePath(BuildContext context, DiscussionProvider provider) async {
    try {
      final basePath = await provider.getPerpuskuHtmlBasePath();
      final newPath = await showHtmlFilePicker(
        context,
        basePath,
        initialPath: subjectLinkedPath,
      );
      if (newPath != null) {
        provider.updateDiscussionFilePath(discussion, newPath);
        _showSnackBar(context, 'Path file berhasil disimpan.');
      }
    } catch (e) {
      _showSnackBar(context, 'Gagal: ${e.toString()}');
    }
  }

  void _generateHtml(BuildContext context) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: Provider.of<DiscussionProvider>(context, listen: false),
        child: GenerateHtmlDialog(
          discussionName: discussion.discussion,
          filePath: discussion.filePath,
        ),
      ),
    );
    if (success == true && context.mounted) {
      _showSnackBar(context, 'Konten HTML berhasil dibuat!');
    }
  }

  void _editFile(BuildContext context, DiscussionProvider provider) async {
    try {
      await provider.editDiscussionFile(discussion);
    } catch (e) {
      _showSnackBar(context, e.toString());
    }
  }

  void _removeFilePath(
    BuildContext context,
    DiscussionProvider provider,
  ) async {
    final confirmed = await showRemoveFilePathConfirmationDialog(context);
    if (confirmed) {
      provider.removeDiscussionFilePath(discussion);
      _showSnackBar(context, 'Path file berhasil dihapus.');
    }
  }

  void _findSmartLink(BuildContext context, DiscussionProvider provider) async {
    final subjectsPage = context.findAncestorWidgetOfExactType<SubjectsPage>();
    final topicName = subjectsPage?.topicName ?? 'Unknown';
    final success = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: provider,
        child: SmartLinkDialog(
          discussion: discussion,
          topicName: topicName,
          subjectName: subjectName,
        ),
      ),
    );
    if (success == true && context.mounted) {
      _showSnackBar(context, 'Diskusi berhasil ditautkan.');
    }
  }

  void _markAsFinished(BuildContext context, DiscussionProvider provider) {
    provider.markAsFinished(discussion);
    _showSnackBar(context, 'Diskusi ditandai selesai.');
  }

  void _reactivateDiscussion(
    BuildContext context,
    DiscussionProvider provider,
  ) {
    provider.reactivateDiscussion(discussion);
    _showSnackBar(context, 'Diskusi diaktifkan kembali.');
  }

  void _deleteDiscussion(BuildContext context, DiscussionProvider provider) {
    showDeleteDiscussionConfirmationDialog(
      context: context,
      discussionName: discussion.discussion,
      hasLinkedFile:
          discussion.filePath != null && discussion.filePath!.isNotEmpty,
      onDelete: () async {
        try {
          await provider.deleteDiscussion(discussion);
          if (context.mounted) {
            _showSnackBar(
              context,
              'Diskusi "${discussion.discussion}" berhasil dihapus.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            _showSnackBar(context, "Gagal menghapus: ${e.toString()}");
          }
        }
      },
    );
  }
}
