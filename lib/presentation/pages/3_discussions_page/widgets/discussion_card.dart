import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../../presentation/providers/discussion_provider.dart';
import '../../../../presentation/widgets/edit_popup_menu.dart';
import '../dialogs/discussion_dialogs.dart';
import '../utils/repetition_code_utils.dart';
import 'discussion_subtitle.dart';
import 'point_tile.dart';

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final Map<int, bool> arePointsVisible;
  final Function(int) onToggleVisibility;
  final double? panelWidth;
  final bool isLinux;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.index,
    required this.arePointsVisible,
    required this.onToggleVisibility,
    this.panelWidth,
    this.isLinux = false,
  });

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    DiscussionProvider provider,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final bool isFinished = discussion.finished;
    final bool hasPoints = discussion.points.isNotEmpty;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: [
        if (!isFinished)
          const PopupMenuItem<String>(
            value: 'add_point',
            child: Text('Tambah Poin'),
          ),
        if (!hasPoints) ...[
          const PopupMenuItem<String>(
            value: 'edit_date',
            child: Text('Ubah Tanggal'),
          ),
          const PopupMenuItem<String>(
            value: 'edit_code',
            child: Text('Ubah Kode Repetisi'),
          ),
        ],
        const PopupMenuItem<String>(value: 'rename', child: Text('Ubah Nama')),
        const PopupMenuDivider(),
        if (!isFinished && !hasPoints)
          const PopupMenuItem<String>(
            value: 'finish',
            child: Text('Tandai Selesai'),
          ),
        if (isFinished)
          const PopupMenuItem<String>(
            value: 'reactivate',
            child: Text('Aktifkan Lagi'),
          ),
        // Tambahkan opsi hapus di sini
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == 'add_point') _addPoint(context, provider);
      if (value == 'edit_date') _changeDiscussionDate(context, provider);
      if (value == 'edit_code') _changeDiscussionCode(context, provider);
      if (value == 'rename') _renameDiscussion(context, provider);
      if (value == 'finish') _markAsFinished(context, provider);
      if (value == 'reactivate') _reactivateDiscussion(context, provider);
      if (value == 'delete')
        _deleteDiscussion(context, provider); // Panggil fungsi hapus
    });
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

  //==> FUNGSI BARU UNTUK HAPUS DISKUSI <==
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

  @override
  Widget build(BuildContext context) {
    final bool isCompact = panelWidth != null && panelWidth! < 450;

    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    bool arePointsVisibleForThisCard = arePointsVisible[index] ?? false;
    final bool isFinished = discussion.finished;
    final iconColor = isFinished ? Colors.green : Colors.blue;
    final iconData = isFinished
        ? Icons.check_circle
        : Icons.chat_bubble_outline;

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

    final cardContent = Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              iconData,
              color: iconColor,
              size: isCompact ? 22 : 24,
            ),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
                fontSize: isCompact ? 14.5 : 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: DiscussionSubtitle(
              discussion: discussion,
              isCompact: isCompact,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLinux)
                  EditPopupMenu(
                    isFinished: isFinished,
                    hasPoints: discussion.points.isNotEmpty,
                    onAddPoint: () => _addPoint(context, provider),
                    onDateChange: () =>
                        _changeDiscussionDate(context, provider),
                    onCodeChange: () =>
                        _changeDiscussionCode(context, provider),
                    onRename: () => _renameDiscussion(context, provider),
                    onMarkAsFinished: () => _markAsFinished(context, provider),
                    onReactivate: () =>
                        _reactivateDiscussion(context, provider),
                    onDelete: () =>
                        _deleteDiscussion(context, provider), // ==> DITAMBAHKAN
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
                  children: sortedPoints.map((point) {
                    final bool isPointActive = provider.doesPointMatchFilter(
                      point,
                    );
                    return PointTile(point: point, isActive: isPointActive);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );

    if (isLinux) {
      return GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition, provider);
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
