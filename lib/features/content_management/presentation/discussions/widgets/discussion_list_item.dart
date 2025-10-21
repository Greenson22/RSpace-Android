// lib/features/content_management/presentation/discussions/widgets/discussion_list_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../../../../settings/application/theme_provider.dart';
import '../../../../webview_page/presentation/pages/webview_page.dart';
import '../dialogs/discussion_dialogs.dart';
import '../dialogs/generate_html_dialog.dart';
import '../dialogs/smart_link_dialog.dart';
import 'discussion_action_menu.dart'; // Pastikan DiscussionActionMenu diimpor
import 'discussion_point_list.dart';
import 'discussion_subtitle.dart';
import '../../subjects/subjects_page.dart';
import 'package:my_aplication/features/quiz/presentation/pages/quiz_question_list_page.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/features/quiz/presentation/dialogs/generate_quiz_from_html_dialog.dart';
import 'package:my_aplication/features/quiz/application/quiz_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/quiz/presentation/pages/quiz_player_page.dart';
import 'package:my_aplication/features/quiz/presentation/dialogs/quiz_picker_dialog.dart';

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
  final double? titleFontSize;
  final double? horizontalGap; // <<< Jarak antara leading dan title

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
    this.titleFontSize = 14.0,
    this.horizontalGap = 14.0, // <<< Nilai default jarak leading-title
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

  void _navigateAndEditQuiz(BuildContext context) {
    final quizSubjectPath = discussion.filePath;
    if (quizSubjectPath == null || discussion.quizName == null) {
      _showSnackBar(
        context,
        "Informasi tautan kuis tidak lengkap.",
        isError: true,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => QuizDetailProvider(quizSubjectPath),
          child: QuizQuestionListPage(quizName: discussion.quizName!),
        ),
      ),
    ).then((_) {
      Provider.of<DiscussionProvider>(context, listen: false).loadDiscussions();
    });
  }

  Future<void> _startQuiz(BuildContext context) async {
    final quizSubjectPath = discussion.filePath;
    if (quizSubjectPath == null || discussion.quizName == null) {
      _showSnackBar(
        context,
        "Informasi tautan kuis tidak lengkap.",
        isError: true,
      );
      return;
    }

    try {
      final quizService = QuizService();
      final List<QuizSet> allQuizzesInSubject = await quizService.loadQuizzes(
        quizSubjectPath,
      );

      final QuizSet currentQuizSet;
      try {
        currentQuizSet = allQuizzesInSubject.firstWhere(
          (qs) => qs.name == discussion.quizName,
        );
      } catch (e) {
        throw Exception(
          "Kuis '${discussion.quizName}' tidak ditemukan di subjek ini.",
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

  Future<void> _changeQuizLink(BuildContext context) async {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final result = await showQuizPickerDialog(context);
    if (result != null) {
      await provider.updateQuizLink(discussion, result);
      _showSnackBar(context, 'Tautan kuis berhasil diubah.');
    }
  }

  Future<void> _convertToQuiz(BuildContext context) async {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Jadikan Kuis'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'link'),
            child: const ListTile(
              leading: Icon(Icons.link),
              title: Text('Tautkan ke Kuis yang Ada'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'create'),
            child: const ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Buat Kuis Baru'),
              subtitle: Text('Dengan nama yang sama seperti diskusi ini.'),
            ),
          ),
        ],
      ),
    );

    if (choice == 'link' && context.mounted) {
      final result = await showQuizPickerDialog(context);
      if (result != null) {
        await provider.convertToQuiz(discussion, linkTo: result);
        _showSnackBar(context, 'Diskusi berhasil diubah menjadi tautan kuis.');
      }
    } else if (choice == 'create' && context.mounted) {
      try {
        await provider.convertToQuiz(discussion, createNew: true);
        _showSnackBar(context, 'Kuis baru berhasil dibuat dan ditautkan.');
      } catch (e) {
        _showSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isSelected = provider.selectedDiscussions.contains(discussion);
    final isFinished = discussion.finished;
    final isWebLink = discussion.linkType == DiscussionLinkType.link;
    final isQuiz = discussion.linkType == DiscussionLinkType.perpuskuQuiz;
    final hasFile =
        discussion.linkType == DiscussionLinkType.html &&
        discussion.filePath != null &&
        discussion.filePath!.isNotEmpty;

    final iconColor = isFinished
        ? Colors.green
        : (isSelected ? theme.primaryColor : null);

    IconData iconData;
    if (isFinished) {
      iconData = Icons.check_circle;
    } else if (isQuiz) {
      iconData = Icons.assignment_turned_in_outlined;
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
      if (isQuiz) {
        onPressedAction = () => _startQuiz(context);
        tooltip = 'Mulai Kuis';
      } else if (isWebLink) {
        onPressedAction = () => _openUrlWithOptions(context);
        tooltip = 'Buka Tautan';
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

    // === PERBAIKAN UTAMA: Hitung Ukuran Ikon & Jarak Berdasarkan Skala ===
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseLeadingIconSize = 24.0;
    const double baseTrailingIconSize =
        24.0; // Ukuran dasar untuk ikon panah expand/collapse
    const double baseTrailingSpacing = 0.0; // Jarak dasar antar ikon trailing

    final scaledLeadingIconSize = baseLeadingIconSize * textScaleFactor;
    final scaledTrailingIconSize =
        baseTrailingIconSize * textScaleFactor; // Ukuran untuk panah
    final scaledTrailingSpacing = baseTrailingSpacing * textScaleFactor;
    // === AKHIR PERBAIKAN UTAMA ===

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
            horizontalTitleGap: horizontalGap,
            onTap: () {
              if (provider.isSelectionMode) {
                provider.toggleSelection(discussion);
              } else {
                if (isQuiz) {
                  _startQuiz(context);
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
              // Gunakan ukuran ikon kiri yang sudah diskalakan
              iconSize: scaledLeadingIconSize,
              onPressed: onPressedAction,
              tooltip: tooltip,
            ),
            title: Text(
              discussion.discussion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isFinished ? TextDecoration.lineThrough : null,
                fontSize: titleFontSize,
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
                // DiscussionActionMenu sekarang akan menghitung ukurannya sendiri
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
                    onAddQuizQuestion: () => _navigateAndEditQuiz(context),
                    onChangeQuizLink: () => _changeQuizLink(context),
                    onConvertToQuiz: () => _convertToQuiz(context),
                    onGenerateQuizPrompt: () {
                      try {
                        final correctPath = provider.getCorrectRelativePath(
                          discussion,
                        );
                        showGenerateQuizFromHtmlDialog(
                          context,
                          relativeHtmlPath: correctPath,
                          discussionTitle: discussion.discussion,
                        );
                      } catch (e) {
                        _showSnackBar(context, e.toString(), isError: true);
                      }
                    },
                  ),
                // Gunakan jarak trailing yang sudah diskalakan
                if (!provider.isSelectionMode && discussion.points.isNotEmpty)
                  SizedBox(width: scaledTrailingSpacing),
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
                    // Gunakan ukuran ikon kanan yang sudah diskalakan
                    iconSize: scaledTrailingIconSize,
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
