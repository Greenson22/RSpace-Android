// lib/features/content_management/presentation/discussions/widgets/discussion_list_item.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/add_point_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/confirmation_dialogs.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/edit_dialogs.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/html_file_picker_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/move_discussion_dialog.dart';
import 'package:my_aplication/features/quiz/application/quiz_service.dart';
import 'package:my_aplication/features/quiz/presentation/pages/quiz_player_page.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../dialogs/generate_html_dialog.dart';
import '../dialogs/smart_link_dialog.dart';
import 'discussion_action_menu.dart';
import 'discussion_point_list.dart';
import 'discussion_subtitle.dart';
import '../../subjects/subjects_page.dart';

class DiscussionListItem extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final bool isFocused;
  final Map<int, bool> arePointsVisible;
  final Function(int) onToggleVisibility;
  final String subjectName;
  final String? subjectLinkedPath;
  final VoidCallback onDelete;

  const DiscussionListItem({
    super.key,
    required this.discussion,
    required this.index,
    this.isFocused = false,
    required this.arePointsVisible,
    required this.onToggleVisibility,
    required this.subjectName,
    this.subjectLinkedPath,
    required this.onDelete,
  });

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isSelected = provider.selectedDiscussions.contains(discussion);
    final isFinished = discussion.finished;
    final hasFile =
        discussion.filePath != null && discussion.filePath!.isNotEmpty;
    // ==> VARIABEL BARU
    final isQuizLink = discussion.linkType == DiscussionLinkType.quiz;
    final iconColor = isFinished
        ? Colors.green
        : (isSelected ? theme.primaryColor : null);

    // ==> LOGIKA IKON DIPERBARUI
    IconData iconData;
    if (isFinished) {
      iconData = Icons.check_circle;
    } else if (isQuizLink) {
      iconData = Icons.quiz_outlined;
    } else if (hasFile) {
      iconData = Icons.link;
    } else {
      iconData = Icons.chat_bubble_outline;
    }

    if (isSelected) {
      iconData = Icons.check_circle_outline;
    }

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
          ListTile(
            onTap: () {
              if (provider.isSelectionMode) {
                provider.toggleSelection(discussion);
              } else {
                onToggleVisibility(index);
              }
            },
            onLongPress: () {
              provider.toggleSelection(discussion);
            },
            leading: IconButton(
              icon: Icon(iconData, color: iconColor),
              // ==> LOGIKA ONPRESSED DIPERBARUI
              onPressed: () {
                if (isQuizLink) {
                  _startQuiz(context);
                } else if (hasFile) {
                  provider.openDiscussionFile(discussion, context);
                }
              },
              tooltip: isQuizLink
                  ? 'Mulai Kuis'
                  : (hasFile ? 'Buka File' : null),
            ),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: DiscussionSubtitle(
              discussion: discussion,
              isCompact: true,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!provider.isSelectionMode)
                  DiscussionActionMenu(
                    isFinished: isFinished,
                    hasFile: hasFile,
                    canCreateFile: subjectLinkedPath != null,
                    hasPoints: discussion.points.isNotEmpty,
                    onAddPoint: () => _addPoint(context, provider),
                    onMove: () => _moveDiscussion(context, provider),
                    onRename: () => _renameDiscussion(context, provider),
                    onDateChange: () =>
                        _changeDiscussionDate(context, provider),
                    onCodeChange: () =>
                        _changeDiscussionCode(context, provider),
                    onCreateFile: () => _createHtmlFileForDiscussion(
                      context,
                      provider,
                      subjectLinkedPath!,
                    ),
                    onSetFilePath: () => _setFilePath(context, provider),
                    onGenerateHtml: () => _generateHtml(context),
                    onEditFile: () => provider.editDiscussionFileWithSelection(
                      discussion,
                      context,
                    ),
                    onRemoveFilePath: () => _removeFilePath(context, provider),
                    onSmartLink: () => _findSmartLink(context, provider),
                    onFinish: () => _markAsFinished(context, provider),
                    onReactivate: () =>
                        _reactivateDiscussion(context, provider),
                    onDelete: onDelete,
                  ),
                if (discussion.points.isNotEmpty && !provider.isSelectionMode)
                  IconButton(
                    icon: Icon(
                      (arePointsVisible[index] ?? false)
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onPressed: () => onToggleVisibility(index),
                  ),
              ],
            ),
          ),
          if (discussion.points.isNotEmpty &&
              (arePointsVisible[index] ?? false))
            const Divider(height: 1, indent: 16, endIndent: 16),
          if (discussion.points.isNotEmpty)
            Visibility(
              visible: arePointsVisible[index] ?? false,
              child: DiscussionPointList(discussion: discussion),
            ),
        ],
      ),
    );
  }

  // --- FUNGSI BARU UNTUK MEMULAI KUIS ---
  void _startQuiz(BuildContext context) async {
    if (discussion.quizTopicPath == null) return;
    final pathParts = discussion.quizTopicPath!.split('/');
    if (pathParts.length != 2) return;

    final categoryName = pathParts[0];
    final topicName = pathParts[1];

    try {
      final quizService = QuizService();
      final topic = await quizService.getTopic(categoryName, topicName);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizPlayerPage(topic: topic)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat kuis: $e")));
    }
  }

  // --- PRIVATE HELPER METHODS FOR ACTIONS (TIDAK BERUBAH) ---
  void _addPoint(BuildContext context, DiscussionProvider provider) {
    showAddPointDialog(
      context: context,
      discussion: discussion,
      title: 'Tambah Poin Baru',
      label: 'Teks Poin',
      onSave: (text, repetitionCode) {
        provider.addPoint(discussion, text, repetitionCode: repetitionCode);
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
        _showSnackBar(
          context,
          'Gagal memindahkan: ${e.toString()}',
          isError: true,
        );
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
        _showSnackBar(
          context,
          'Gagal membuat file: ${e.toString()}',
          isError: true,
        );
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
      _showSnackBar(context, 'Gagal: ${e.toString()}', isError: true);
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
}
