// lib/features/content_management/presentation/discussions/widgets/discussion_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import 'discussion_action_menu.dart';
import 'discussion_subtitle.dart';

class DiscussionTile extends StatelessWidget {
  final Discussion discussion;
  final bool isSelected;
  final bool arePointsVisible;
  final String? subjectLinkedPath;
  final VoidCallback onToggleVisibility;

  // Callbacks for the action menu
  final VoidCallback onAddPoint;
  final VoidCallback onMove;
  final VoidCallback onRename;
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback onCreateFile;
  final VoidCallback onSetFilePath;
  final VoidCallback onGenerateHtml;
  final VoidCallback onEditFile;
  final VoidCallback onRemoveFilePath;
  final VoidCallback onSmartLink;
  final VoidCallback onFinish;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final VoidCallback onAddPerpuskuQuizQuestion;
  // ==> TAMBAHKAN DUA CALLBACK BERIKUT <==
  final VoidCallback onGenerateQuizPrompt;
  final VoidCallback onReorderPoints;

  const DiscussionTile({
    super.key,
    required this.discussion,
    required this.isSelected,
    required this.arePointsVisible,
    this.subjectLinkedPath,
    required this.onToggleVisibility,
    required this.onAddPoint,
    required this.onMove,
    required this.onRename,
    required this.onDateChange,
    required this.onCodeChange,
    required this.onCreateFile,
    required this.onSetFilePath,
    required this.onGenerateHtml,
    required this.onEditFile,
    required this.onRemoveFilePath,
    required this.onSmartLink,
    required this.onFinish,
    required this.onReactivate,
    required this.onDelete,
    required this.onAddPerpuskuQuizQuestion,
    // ==> TAMBAHKAN DI KONSTRUKTOR <==
    required this.onGenerateQuizPrompt,
    required this.onReorderPoints,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);

    final bool isFinished = discussion.finished;
    final bool hasFile =
        discussion.filePath != null && discussion.filePath!.isNotEmpty;
    final iconColor = isFinished
        ? Colors.green
        : (isSelected ? theme.primaryColor : Colors.blue);

    IconData iconData = isFinished
        ? Icons.check_circle
        : (hasFile ? Icons.link : Icons.chat_bubble_outline);
    if (isSelected) {
      iconData = Icons.check_circle;
    }

    return ListTile(
      onTap: () {
        if (provider.isSelectionMode) {
          provider.toggleSelection(discussion);
        } else {
          onToggleVisibility();
        }
      },
      onLongPress: () {
        provider.toggleSelection(discussion);
      },
      leading: IconButton(
        icon: Icon(iconData, color: iconColor, size: 24),
        onPressed: hasFile
            ? () => provider.openDiscussionFile(discussion, context)
            : null,
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
          if (!provider.isSelectionMode)
            DiscussionActionMenu(
              isFinished: isFinished,
              hasFile: hasFile,
              canCreateFile: subjectLinkedPath != null,
              hasPoints: discussion.points.isNotEmpty,
              linkType: discussion.linkType,
              onAddPoint: onAddPoint,
              onMove: onMove,
              onRename: onRename,
              onDateChange: onDateChange,
              onCodeChange: onCodeChange,
              onCreateFile: onCreateFile,
              onSetFilePath: onSetFilePath,
              onGenerateHtml: onGenerateHtml,
              onEditFile: onEditFile,
              onRemoveFilePath: onRemoveFilePath,
              onSmartLink: onSmartLink,
              onFinish: onFinish,
              onReactivate: onReactivate,
              onDelete: onDelete,
              onCopy: () {},
              // ==> PERBAIKAN DI SINI <==
              onReorderPoints: onReorderPoints,
              onAddPerpuskuQuizQuestion: onAddPerpuskuQuizQuestion,
              onGenerateQuizPrompt: onGenerateQuizPrompt,
            ),
          if (discussion.points.isNotEmpty && !provider.isSelectionMode)
            IconButton(
              icon: Icon(
                arePointsVisible ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: onToggleVisibility,
            ),
        ],
      ),
    );
  }
}
