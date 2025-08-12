import 'package:flutter/material.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../widgets/edit_popup_menu.dart';
import 'discussion_subtitle.dart'; // <-- IMPORT WIDGET BARU
import 'point_tile.dart';

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final Map<int, bool> arePointsVisible;

  final VoidCallback onAddPoint;
  final VoidCallback onMarkAsFinished;
  final VoidCallback onRename;
  final VoidCallback onDiscussionDateChange;
  final VoidCallback onDiscussionCodeChange;
  final Function(Point) onPointDateChange;
  final Function(Point) onPointCodeChange;
  final Function(Point) onPointRename;
  final Function(int) onToggleVisibility;
  // HAPUS: final Color Function(String) getColorForRepetitionCode;
  // HAPUS: final Widget Function(Discussion) getSubtitleRichText;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.index,
    required this.arePointsVisible,
    required this.onAddPoint,
    required this.onMarkAsFinished,
    required this.onRename,
    required this.onDiscussionDateChange,
    required this.onDiscussionCodeChange,
    required this.onPointDateChange,
    required this.onPointCodeChange,
    required this.onPointRename,
    required this.onToggleVisibility,
    // HAPUS: required this.getColorForRepetitionCode,
    // HAPUS: required this.getSubtitleRichText,
  });

  @override
  Widget build(BuildContext context) {
    bool arePointsVisibleForThisCard = arePointsVisible[index] ?? false;
    final bool isFinished = discussion.finished;
    final iconColor = isFinished ? Colors.green : Colors.blue;
    final iconData = isFinished
        ? Icons.check_circle
        : Icons.chat_bubble_outline;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(iconData, color: iconColor),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: DiscussionSubtitle(
              discussion: discussion,
            ), // <-- GUNAKAN WIDGET BARU
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditPopupMenu(
                  isFinished: isFinished,
                  onAddPoint: onAddPoint,
                  onDateChange: onDiscussionDateChange,
                  onCodeChange: onDiscussionCodeChange,
                  onRename: onRename,
                  onMarkAsFinished: onMarkAsFinished,
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
                padding: const EdgeInsets.only(
                  left: 30.0,
                  top: 8.0,
                  right: 16.0,
                  bottom: 8.0,
                ),
                child: Column(
                  children: discussion.points
                      .map(
                        (point) => PointTile(
                          point: point,
                          onDateChange: () => onPointDateChange(point),
                          onCodeChange: () => onPointCodeChange(point),
                          onRename: () => onPointRename(point),
                          // HAPUS: getColorForRepetitionCode, karena sudah dihandle di dalam PointTile
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
