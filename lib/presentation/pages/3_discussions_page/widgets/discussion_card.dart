// lib/presentation/pages/3_discussions_page/widgets/discussion_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../../presentation/providers/discussion_provider.dart';
import '../../../../presentation/widgets/edit_popup_menu.dart';
import '../dialogs/discussion_dialogs.dart';
import '../dialogs/generate_html_dialog.dart';
import '../utils/repetition_code_utils.dart';
import 'discussion_subtitle.dart';
import 'point_tile.dart';

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final bool isFocused;
  final Map<int, bool> arePointsVisible;
  final Function(int) onToggleVisibility;
  final String? subjectLinkedPath;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.index,
    this.isFocused = false,
    required this.arePointsVisible,
    required this.onToggleVisibility,
    this.subjectLinkedPath,
  });

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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

  void _addPoint(BuildContext context, DiscussionProvider provider) {
    showTextInputDialog(
      context: context,
      title: 'Tambah Poin Baru',
      label: 'Teks Poin',
      onSave: (text) {
        provider.addPoint(discussion, text);
        _showSnackBar(context, 'Poin berhasil ditambahkan.');
      },
    );
  }

  void _deleteDiscussion(BuildContext context, DiscussionProvider provider) {
    showDeleteDiscussionConfirmationDialog(
      context: context,
      discussionName: discussion.discussion,
      onDelete: () {
        provider.deleteDiscussion(discussion);
        _showSnackBar(
          context,
          'Diskusi "${discussion.discussion}" berhasil dihapus.',
        );
      },
    );
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
      _showSnackBar(context, 'Gagal membuka pemilih file: ${e.toString()}');
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

  void _openFile(BuildContext context, DiscussionProvider provider) async {
    try {
      await provider.openDiscussionFile(discussion);
    } catch (e) {
      _showSnackBar(context, e.toString());
    }
  }

  void _editFile(BuildContext context, DiscussionProvider provider) async {
    try {
      await provider.editDiscussionFile(discussion);
    } catch (e) {
      _showSnackBar(context, e.toString());
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);
    bool arePointsVisibleForThisCard = arePointsVisible[index] ?? false;
    final bool isFinished = discussion.finished;
    final iconColor = isFinished ? Colors.green : Colors.blue;
    final bool hasFile =
        discussion.filePath != null && discussion.filePath!.isNotEmpty;
    final IconData iconData = isFinished
        ? Icons.check_circle
        : (hasFile ? Icons.link : Icons.chat_bubble_outline);

    final sortedPoints = List<Point>.from(discussion.points);
    final sortType = provider.sortType;
    final sortAscending = provider.sortAscending;

    Comparator<Point> comparator;
    switch (sortType) {
      case 'name':
        comparator = (a, b) =>
            a.pointText.toLowerCase().compareTo(b.pointText.toLowerCase());
        break;
      case 'code':
        comparator = (a, b) => getRepetitionCodeIndex(
          a.repetitionCode,
        ).compareTo(getRepetitionCodeIndex(b.repetitionCode));
        break;
      default: // date
        comparator = (a, b) {
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return sortAscending ? 1 : -1;
          if (dateB == null) return sortAscending ? -1 : 1;
          return dateA.compareTo(dateB);
        };
        break;
    }
    sortedPoints.sort(comparator);
    if (!sortAscending) {
      final reversedPoints = sortedPoints.reversed.toList();
      sortedPoints.clear();
      sortedPoints.addAll(reversedPoints);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            leading: IconButton(
              icon: Icon(iconData, color: iconColor, size: 24),
              onPressed: hasFile ? () => _openFile(context, provider) : null,
              tooltip: hasFile ? 'Buka File' : null,
            ),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: DiscussionSubtitle(discussion: discussion),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditPopupMenu(
                  isFinished: isFinished,
                  hasPoints: discussion.points.isNotEmpty,
                  hasFilePath: hasFile,
                  onAddPoint: () => _addPoint(context, provider),
                  onSetFilePath: () => _setFilePath(context, provider),
                  onRemoveFilePath: () => _removeFilePath(context, provider),
                  onEditFilePath: () => _editFile(context, provider),
                  onGenerateHtml: () => _generateHtml(context),
                  onDateChange: () => _changeDiscussionDate(context, provider),
                  onCodeChange: () => _changeDiscussionCode(context, provider),
                  onRename: () => _renameDiscussion(context, provider),
                  onMarkAsFinished: () => _markAsFinished(context, provider),
                  onReactivate: () => _reactivateDiscussion(context, provider),
                  onDelete: () => _deleteDiscussion(context, provider),
                ),
                if (discussion.points.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      arePointsVisibleForThisCard
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onPressed: () => onToggleVisibility(index),
                  ),
              ],
            ),
          ),
          if (discussion.points.isNotEmpty)
            Visibility(
              visible: arePointsVisibleForThisCard,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 8.0, 16.0, 8.0),
                child: Column(
                  children: [
                    for (var i = 0; i < sortedPoints.length; i++) ...[
                      PointTile(
                        discussion: discussion,
                        point: sortedPoints[i],
                        isActive: provider.doesPointMatchFilter(
                          sortedPoints[i],
                        ),
                      ),
                      if (i < sortedPoints.length - 1)
                        Divider(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : null,
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
