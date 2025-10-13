// lib/features/content_management/presentation/discussions/widgets/discussion_list_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../../../../quiz/application/quiz_service.dart';
import '../../../../quiz/presentation/pages/quiz_player_page.dart';
import '../../../../settings/application/theme_provider.dart';
import '../../../../webview_page/presentation/pages/webview_page.dart';
import '../dialogs/discussion_dialogs.dart';
import '../dialogs/generate_html_dialog.dart';
import '../dialogs/smart_link_dialog.dart';
import 'discussion_action_menu.dart';
import 'discussion_point_list.dart';
import 'discussion_subtitle.dart';
import '../../subjects/subjects_page.dart';
import 'package:my_aplication/features/perpusku/presentation/pages/perpusku_quiz_question_list_page.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_detail_provider.dart';
import 'package:my_aplication/features/perpusku/presentation/dialogs/generate_prompt_from_html_dialog.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';

class DiscussionListItem extends StatelessWidget {
  final Discussion discussion;
  final int index;
  final bool isFocused;
  final Map<int, bool> arePointsVisible;
  final Function(int) onToggleVisibility;
  final String subjectName;
  final String? subjectLinkedPath;
  final VoidCallback onDelete;
  final bool isPointReorderMode;
  final VoidCallback onToggleReorder;

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
    required this.isPointReorderMode,
    required this.onToggleReorder,
  });

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isLong = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: isLong
            ? const Duration(seconds: 10)
            : const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : null,
        action: isLong
            ? SnackBarAction(
                label: 'TUTUP',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  void _copyDiscussionContent(BuildContext context, Discussion discussion) {
    Clipboard.setData(ClipboardData(text: discussion.discussion));
    _showSnackBar(context, 'Judul diskusi disalin ke clipboard.');
  }

  void _navigateAndEditPerpuskuQuiz(BuildContext context) {
    if (subjectLinkedPath == null || discussion.perpuskuQuizName == null) {
      _showSnackBar(context, "Informasi kuis tidak lengkap.", isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PerpuskuQuizDetailProvider(subjectLinkedPath!),
          child: PerpuskuQuizQuestionListPage(
            quizName: discussion.perpuskuQuizName!,
          ),
        ),
      ),
    ).then((_) {
      Provider.of<DiscussionProvider>(context, listen: false).loadDiscussions();
    });
  }

  // ==> FUNGSI INI DIPERBARUI TOTAL <==
  Future<void> _startPerpuskuQuiz(BuildContext context) async {
    if (subjectLinkedPath == null || discussion.perpuskuQuizName == null) {
      _showSnackBar(context, "Informasi kuis tidak lengkap.", isError: true);
      return;
    }

    try {
      final perpuskuQuizService = PerpuskuQuizService();
      final List<QuizSet> allQuizzesInSubject = await perpuskuQuizService
          .loadQuizzes(subjectLinkedPath!);

      final QuizSet currentQuizSet;
      try {
        currentQuizSet = allQuizzesInSubject.firstWhere(
          (qs) => qs.name == discussion.perpuskuQuizName,
        );
      } catch (e) {
        throw Exception(
          "Kuis '${discussion.perpuskuQuizName}' tidak ditemukan di subjek ini.",
        );
      }

      if (currentQuizSet.questions.isEmpty) {
        _showSnackBar(
          context,
          "Kuis ini belum memiliki pertanyaan. Tambahkan pertanyaan terlebih dahulu melalui menu 'Kelola Pertanyaan Kuis'.",
          isError: true,
          isLong: true,
        );
        return;
      }

      // Gunakan helper toQuizTopic dari model QuizSet
      final quizTopic = currentQuizSet.toQuizTopic(subjectName);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPlayerPage(
            topic: quizTopic,
            questions: currentQuizSet.questions,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(
        context,
        "Gagal memulai kuis: ${e.toString()}",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isSelected = provider.selectedDiscussions.contains(discussion);
    final isFinished = discussion.finished;
    final hasFile =
        discussion.filePath != null && discussion.filePath!.isNotEmpty;
    final isQuizLink = discussion.linkType == DiscussionLinkType.quiz;
    final isWebLink = discussion.linkType == DiscussionLinkType.link;
    final isPerpuskuQuiz =
        discussion.linkType == DiscussionLinkType.perpuskuQuiz;

    final iconColor = isFinished
        ? Colors.green
        : (isSelected ? theme.primaryColor : null);

    IconData iconData;
    if (isFinished) {
      iconData = Icons.check_circle;
    } else if (isPerpuskuQuiz) {
      iconData = Icons.assignment_turned_in_outlined;
    } else if (isQuizLink) {
      iconData = Icons.quiz_outlined;
    } else if (isWebLink) {
      iconData = Icons.link;
    } else if (hasFile) {
      iconData = Icons.insert_drive_file_outlined;
    } else {
      iconData = Icons.chat_bubble_outline;
    }

    if (isSelected) {
      iconData = Icons.check_circle_outline;
    }

    VoidCallback? onPressedAction;
    String? tooltip;

    if (!provider.isSelectionMode) {
      if (isPerpuskuQuiz) {
        onPressedAction = () => _startPerpuskuQuiz(context);
        tooltip = 'Mulai Kuis';
      } else if (isWebLink) {
        onPressedAction = () => _openUrlWithOptions(context);
        tooltip = 'Buka Tautan';
      } else if (isQuizLink) {
        onPressedAction = () => _startQuiz(context);
        tooltip = 'Mulai Kuis';
      } else if (hasFile) {
        onPressedAction = () async {
          try {
            await provider.openDiscussionFile(discussion, context);
          } catch (e) {
            _showSnackBar(context, e.toString(), isError: true);
          }
        };
        tooltip = 'Buka File';
      }
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
                if (isPerpuskuQuiz) {
                  _startPerpuskuQuiz(context);
                } else {
                  onToggleVisibility(index);
                }
              }
            },
            onLongPress: () {
              provider.toggleSelection(discussion);
            },
            leading: IconButton(
              icon: Icon(iconData, color: iconColor),
              onPressed: onPressedAction,
              tooltip: tooltip,
            ),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiscussionSubtitle(discussion: discussion, isCompact: true),
                if (isWebLink)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      discussion.url ?? 'URL tidak valid',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.primaryColor, fontSize: 12),
                    ),
                  ),
              ],
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
                    linkType: discussion.linkType,
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
                    onCopy: () => _copyDiscussionContent(context, discussion),
                    onReorderPoints: onToggleReorder,
                    onAddPerpuskuQuizQuestion: () =>
                        _navigateAndEditPerpuskuQuiz(context),
                    onGenerateQuizPrompt: () {
                      try {
                        final correctPath = provider.getCorrectRelativePath(
                          discussion,
                        );
                        showGeneratePromptFromHtmlDialog(
                          context,
                          relativeHtmlPath: correctPath,
                          discussionTitle: discussion.discussion,
                        );
                      } catch (e) {
                        _showSnackBar(context, e.toString(), isError: true);
                      }
                    },
                  ),
                if (discussion.points.isNotEmpty && !provider.isSelectionMode)
                  IconButton(
                    icon: Icon(
                      (arePointsVisible[index] ?? false)
                          ? (isPointReorderMode
                                ? Icons.check
                                : Icons.expand_less)
                          : Icons.expand_more,
                      color: isPointReorderMode ? theme.primaryColor : null,
                    ),
                    onPressed: () => onToggleVisibility(index),
                    tooltip: isPointReorderMode
                        ? 'Selesai Mengurutkan'
                        : 'Tampilkan/Sembunyikan Poin',
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
              child: DiscussionPointList(
                discussion: discussion,
                isReorderMode: isPointReorderMode,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUrlWithOptions(BuildContext context) async {
    if (discussion.url == null || discussion.url!.isEmpty) {
      _showSnackBar(context, 'URL tidak valid atau kosong.', isError: true);
      return;
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final uri = Uri.parse(discussion.url!);

    if (themeProvider.openInAppBrowser &&
        (Platform.isAndroid || Platform.isIOS)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: WebViewPage(
              initialUrl: uri.toString(),
              title: discussion.discussion,
              discussion: discussion,
            ),
          ),
        ),
      );
    } else {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Tidak dapat membuka URL');
        }
      } catch (e) {
        _showSnackBar(
          context,
          'Gagal membuka URL: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

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
        _showSnackBar(context, log, isLong: true);
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
