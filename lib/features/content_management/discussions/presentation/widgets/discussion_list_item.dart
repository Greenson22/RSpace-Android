// lib/features/content_management/presentation/discussions/widgets/discussion_list_item.dart
import 'dart:async';
import 'dart:io'; // ==> DITAMBAHKAN: Untuk pengecekan Platform (OS)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// ==> DITAMBAHKAN: Import untuk Preferensi & WebView
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../webview_page/presentation/pages/webview_page.dart';

import '../../../domain/models/discussion_model.dart';
import '../../providers/discussion_provider.dart';
import '../dialogs/discussion_dialogs.dart';
import '../dialogs/generate_html_dialog.dart';
import '../dialogs/smart_link_dialog.dart';
import 'discussion_action_menu.dart';
import 'discussion_point_list.dart';
import 'discussion_subtitle.dart';
import '../../../subjects/presentation/subjects_page.dart';
import '../dialogs/move_discussion_dialog.dart';
import '../dialogs/html_file_picker_dialog.dart';
import '../dialogs/edit_dialogs.dart';

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
  final double? horizontalGap;

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
    this.horizontalGap = 10.0,
  });

  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return Colors.deepPurple;
    final List<Color> themePalettes = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade900,
      Colors.green.shade700,
      Colors.cyan.shade800,
      Colors.orange.shade800,
    ];
    final int hash = title.hashCode;
    final int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }

  void _moveDiscussion(
    BuildContext context,
    DiscussionProvider provider,
  ) async {
    if (!provider.isSelectionMode) {
      provider.toggleSelection(discussion);
    }
    final targetInfo = await showMoveDiscussionDialog(context, subjectName);
    if (!context.mounted) return;

    if (targetInfo != null) {
      try {
        final String log = await provider.moveSelectedDiscussions(
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
      } finally {
        provider.clearSelection();
      }
    } else {
      provider.clearSelection();
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isLong = false,
  }) {
    if (!context.mounted) return;
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
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
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
    _showSnackBar(
      context,
      "Fitur kelola kuis saat ini tidak tersedia.",
      isError: true,
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    _showSnackBar(
      context,
      "Fitur memulai kuis saat ini tidak tersedia.",
      isError: true,
    );
  }

  Future<void> _changeQuizLink(BuildContext context) async {
    _showSnackBar(
      context,
      "Fitur mengubah tautan kuis tidak tersedia.",
      isError: true,
    );
  }

  Future<void> _convertToQuiz(BuildContext context) async {
    _showSnackBar(
      context,
      "Fitur konversi kuis saat ini tidak tersedia.",
      isError: true,
    );
  }

  // ========================================================================
  // LOGIKA YANG DIPERBARUI: Adaptasi Preferensi Tautan Berdasarkan Platform
  // ========================================================================
  Future<void> _openUrlWithOptions(BuildContext context) async {
    if (discussion.url == null || discussion.url!.isEmpty) {
      _showSnackBar(context, 'URL tidak valid atau kosong.', isError: true);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Sinkronisasi Kunci (Key) berdasarkan jenis platform OS
      final String webPreferenceKey = Platform.isAndroid
          ? 'use_internal_web_android'
          : 'use_internal_web';

      // Sinkronisasi Nilai Default (Android: false/external, Desktop: true/internal)
      final bool defaultWebValue = Platform.isAndroid ? false : true;

      // Ambil preferensi tersimpan, jika belum disetel pakai defaultWebValue
      final bool useInternalWeb =
          prefs.getBool(webPreferenceKey) ?? defaultWebValue;

      if (useInternalWeb) {
        if (context.mounted) {
          final provider = Provider.of<DiscussionProvider>(
            context,
            listen: false,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChangeNotifierProvider<DiscussionProvider>.value(
                    value: provider,
                    child: WebViewPage(
                      initialUrl: discussion.url,
                      title: discussion.discussion,
                      discussion: discussion,
                    ),
                  ),
            ),
          );
        }
      } else {
        final uri = Uri.parse(discussion.url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Tidak dapat membuka URL');
        }
      }
    } catch (e) {
      _showSnackBar(
        context,
        'Gagal membuka URL: ${e.toString()}',
        isError: true,
      );
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

  void _createFileForDiscussion(
    BuildContext context,
    DiscussionProvider provider,
    String subjectLinkedPath,
  ) async {
    final isMarkdown = discussion.linkType == DiscussionLinkType.markdown;
    final fileType = isMarkdown ? 'Markdown' : 'HTML';
    final extension = isMarkdown ? '.md' : '.html';

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Buat File $fileType?'),
            content: Text(
              'Ini akan membuat file $extension baru dan menautkannya ke diskusi "${discussion.discussion}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Buat & Tautkan'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      try {
        if (isMarkdown) {
          await provider.createAndLinkMarkdownFile(
            discussion,
            subjectLinkedPath,
          );
        } else {
          await provider.createAndLinkHtmlFile(discussion, subjectLinkedPath);
        }
        _showSnackBar(context, 'File $fileType berhasil dibuat dan ditautkan.');
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
      final isMarkdown = discussion.linkType == DiscussionLinkType.markdown;
      final allowedExtensions = isMarkdown ? ['.md'] : ['.html'];

      final newPath = await showHtmlFilePicker(
        context,
        basePath,
        initialPath: subjectLinkedPath,
        allowedExtensions: allowedExtensions,
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

  void _manageHighlight(BuildContext context, DiscussionProvider provider) {
    showHighlightDialog(
      context: context,
      initialColor: discussion.highlightColor,
      initialLabel: discussion.highlightLabel,
      onSave: (color, label) {
        provider.updateDiscussionHighlight(discussion, color, label);
        _showSnackBar(context, 'Highlight berhasil disimpan.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);

    final isSelected = provider.selectedDiscussions.contains(discussion);
    final isFinished = discussion.finished;
    final isWebLink = discussion.linkType == DiscussionLinkType.link;
    final isQuiz = discussion.linkType == DiscussionLinkType.perpuskuQuiz;
    final isMarkdown = discussion.linkType == DiscussionLinkType.markdown;
    final hasFile =
        (discussion.linkType == DiscussionLinkType.html || isMarkdown) &&
        discussion.filePath != null &&
        discussion.filePath!.isNotEmpty;

    final Color mainThemeColor = _getThemeColorFromTitle(discussion.discussion);
    final Color? textColor = isFinished ? theme.disabledColor : null;

    IconData iconData;
    if (isFinished) {
      iconData = Icons.check_circle;
    } else if (isQuiz) {
      iconData = Icons.assignment_turned_in_outlined;
    } else if (isWebLink) {
      iconData = Icons.link;
    } else if (isMarkdown) {
      iconData = Icons.article;
    } else if (hasFile) {
      iconData = Icons.insert_drive_file_outlined;
    } else {
      iconData = Icons.chat_bubble_outline;
    }

    if (isSelected) {
      iconData = Icons.check_circle_outline;
    }

    final iconColor = isFinished ? Colors.green : mainThemeColor;

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
        tooltip = isMarkdown ? 'Buka Catatan (Markdown)' : 'Buka File (HTML)';
      }
    }

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    const double baseLeadingIconSize = 18.0;
    const double baseTrailingIconSize = 18.0;
    const double baseTrailingSpacing = 0.0;
    const double baseVerticalPadding = 2.0;

    final scaledLeadingIconSize = baseLeadingIconSize * textScaleFactor;
    final scaledTrailingIconSize = baseTrailingIconSize * textScaleFactor;
    final scaledTrailingSpacing = baseTrailingSpacing * textScaleFactor;
    final scaledVerticalPadding = baseVerticalPadding * textScaleFactor;
    final scaledHorizontalGap = (horizontalGap ?? 10.0) * textScaleFactor;

    final Color? highlightColor = discussion.highlightColor != null
        ? Color(discussion.highlightColor!)
        : null;

    final Color cardColor = isSelected
        ? mainThemeColor.withOpacity(0.15)
        : (isFinished ? theme.disabledColor.withOpacity(0.1) : theme.cardColor);

    return Card(
      elevation: isFinished ? 1 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: highlightColor?.withOpacity(0.08) ?? cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isFocused ? mainThemeColor : mainThemeColor.withOpacity(0.35),
          width: isFocused ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: (highlightColor != null && !isFinished) ? 4.0 : 0.0,
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: scaledVerticalPadding,
                    ),
                    horizontalTitleGap: scaledHorizontalGap,
                    visualDensity: VisualDensity.compact,
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
                    leading: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isFinished
                            ? theme.disabledColor.withOpacity(0.1)
                            : mainThemeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        icon: Icon(iconData, color: iconColor),
                        iconSize: scaledLeadingIconSize,
                        onPressed: onPressedAction,
                        tooltip: tooltip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            discussion.discussion,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isFinished
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isFinished ? textColor : mainThemeColor,
                              fontSize: titleFontSize != null
                                  ? titleFontSize! * textScaleFactor
                                  : null,
                            ),
                          ),
                        ),
                        if (discussion.highlightLabel != null &&
                            discussion.highlightLabel!.isNotEmpty &&
                            !isFinished)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: highlightColor ?? mainThemeColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              discussion.highlightLabel!,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DiscussionSubtitle(
                          discussion: discussion,
                          isCompact: true,
                        ),
                        if (isWebLink)
                          Padding(
                            padding: const EdgeInsets.only(top: 1.0),
                            child: Text(
                              discussion.url ?? 'URL tidak valid',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mainThemeColor,
                                fontSize: (11.0 * textScaleFactor),
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!provider.isSelectionMode)
                          Theme(
                            data: theme.copyWith(
                              iconTheme: theme.iconTheme.copyWith(
                                color: mainThemeColor,
                              ),
                              popupMenuTheme: theme.popupMenuTheme.copyWith(
                                textStyle: TextStyle(color: mainThemeColor),
                              ),
                            ),
                            child: DiscussionActionMenu(
                              isFinished: isFinished,
                              hasFile: hasFile,
                              canCreateFile: subjectLinkedPath != null,
                              hasPoints: discussion.points.isNotEmpty,
                              linkType: discussion.linkType,
                              onAddPoint: () => _addPoint(context, provider),
                              onMove: () => _moveDiscussion(context, provider),
                              onRename: () =>
                                  _renameDiscussion(context, provider),
                              onDateChange: () =>
                                  _changeDiscussionDate(context, provider),
                              onCodeChange: () =>
                                  _changeDiscussionCode(context, provider),
                              onCreateFile: () => _createFileForDiscussion(
                                context,
                                provider,
                                subjectLinkedPath!,
                              ),
                              onSetFilePath: () =>
                                  _setFilePath(context, provider),
                              onGenerateHtml: () => _generateHtml(context),
                              onEditFile: () =>
                                  provider.editDiscussionFileWithSelection(
                                    discussion,
                                    context,
                                  ),
                              onRemoveFilePath: () =>
                                  _removeFilePath(context, provider),
                              onSmartLink: () =>
                                  _findSmartLink(context, provider),
                              onFinish: () =>
                                  _markAsFinished(context, provider),
                              onReactivate: () =>
                                  _reactivateDiscussion(context, provider),
                              onDelete: onDelete,
                              onCopy: () =>
                                  _copyDiscussionContent(context, discussion),
                              onReorderPoints: onToggleReorder,
                              onAddQuizQuestion: () =>
                                  _navigateAndEditQuiz(context),
                              onChangeQuizLink: () => _changeQuizLink(context),
                              onConvertToQuiz: () => _convertToQuiz(context),
                              onGenerateQuizPrompt: () {
                                _showSnackBar(
                                  context,
                                  "Fitur pembuat kuis otomatis dari HTML saat ini dinonaktifkan.",
                                  isError: true,
                                );
                              },
                              onHighlight: () =>
                                  _manageHighlight(context, provider),
                              themeColor: mainThemeColor,
                            ),
                          ),
                        if (!provider.isSelectionMode &&
                            discussion.points.isNotEmpty)
                          SizedBox(width: scaledTrailingSpacing),
                        if (discussion.points.isNotEmpty &&
                            !provider.isSelectionMode)
                          IconButton(
                            icon: Icon(
                              (arePointsVisible[index] ?? false)
                                  ? (isPointReorderMode
                                        ? Icons.check
                                        : Icons.expand_less)
                                  : Icons.expand_more,
                              color: isPointReorderMode
                                  ? mainThemeColor
                                  : (isFinished
                                        ? theme.disabledColor
                                        : mainThemeColor.withOpacity(0.7)),
                            ),
                            iconSize: scaledTrailingIconSize,
                            onPressed: () => onToggleVisibility(index),
                            tooltip: isPointReorderMode
                                ? 'Selesai Mengurutkan'
                                : 'Tampilkan/Sembunyikan Poin',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                  if (discussion.points.isNotEmpty &&
                      (arePointsVisible[index] ?? false))
                    const Divider(height: 1, indent: 12, endIndent: 12),
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
            ),
            if (highlightColor != null && !isFinished)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: highlightColor),
              ),
          ],
        ),
      ),
    );
  }
}
