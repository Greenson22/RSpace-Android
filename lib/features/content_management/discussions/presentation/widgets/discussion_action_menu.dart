// lib/features/content_management/presentation/discussions/widgets/discussion_action_menu.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/discussions/models/discussion_model.dart';

class DiscussionActionMenu extends StatelessWidget {
  final bool isFinished;
  final bool hasFile;
  final bool canCreateFile;
  final bool hasPoints;
  final DiscussionLinkType linkType;

  // Callbacks
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
  final VoidCallback onCopy;
  final VoidCallback onReorderPoints;
  final VoidCallback onAddQuizQuestion;
  final VoidCallback onGenerateQuizPrompt;
  final VoidCallback onChangeQuizLink;
  final VoidCallback onConvertToQuiz;
  final VoidCallback onHighlight;

  // Properti warna tema utama
  final Color themeColor;

  const DiscussionActionMenu({
    super.key,
    required this.isFinished,
    required this.hasFile,
    required this.canCreateFile,
    required this.hasPoints,
    required this.linkType,
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
    required this.onCopy,
    required this.onReorderPoints,
    required this.onAddQuizQuestion,
    required this.onGenerateQuizPrompt,
    required this.onChangeQuizLink,
    required this.onConvertToQuiz,
    required this.onHighlight,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double basePopupIconSize = 18.0;
    final scaledPopupIconSize = basePopupIconSize * textScaleFactor;

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          textStyle: TextStyle(color: themeColor, fontSize: 14),
        ),
        iconTheme: theme.iconTheme.copyWith(color: themeColor),
      ),
      child: PopupMenuButton<String>(
        iconSize: scaledPopupIconSize,
        icon: Icon(
          Icons.more_vert,
          color:
              theme.iconTheme.color?.withOpacity(0.7) ??
              themeColor.withOpacity(0.7),
        ),
        padding: const EdgeInsets.all(12.0),
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        onSelected: (value) {
          switch (value) {
            case 'add_point':
              onAddPoint();
              break;
            case 'reorder_points':
              onReorderPoints();
              break;
            case 'move':
              onMove();
              break;
            case 'rename':
              onRename();
              break;
            case 'date_change':
              onDateChange();
              break;
            case 'code_change':
              onCodeChange();
              break;
            case 'create_file':
              onCreateFile();
              break;
            case 'set_file_path':
              onSetFilePath();
              break;
            case 'generate_html':
              onGenerateHtml();
              break;
            case 'edit_file':
              onEditFile();
              break;
            case 'remove_file_path':
              onRemoveFilePath();
              break;
            case 'smart_link':
              onSmartLink();
              break;
            case 'finish':
              onFinish();
              break;
            case 'reactivate':
              onReactivate();
              break;
            case 'delete':
              onDelete();
              break;
            case 'copy':
              onCopy();
              break;
            case 'add_quiz_question':
              onAddQuizQuestion();
              break;
            case 'generate_quiz_prompt':
              onGenerateQuizPrompt();
              break;
            case 'change_quiz_link':
              onChangeQuizLink();
              break;
            case 'convert_to_quiz':
              onConvertToQuiz();
              break;
            case 'highlight':
              onHighlight();
              break;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          _buildMenuItem('add_point', Icons.add_circle_outline, 'Tambah Poin'),
          if (hasPoints)
            _buildMenuItem('reorder_points', Icons.reorder, 'Urutkan Poin'),
          _buildMenuItem('copy', Icons.copy, 'Salin Diskusi'),
          _buildMenuItem('highlight', Icons.star_border, 'Sorot Diskusi'),
          const PopupMenuDivider(height: 8),

          _buildSubMenu(
            icon: Icons.edit_outlined,
            label: 'Ubah Data',
            children: [
              _buildMenuItem('rename', Icons.text_fields, 'Ubah Judul'),
              _buildMenuItem(
                'date_change',
                Icons.calendar_today_outlined,
                'Ubah Tanggal',
              ),
              _buildMenuItem('code_change', Icons.repeat, 'Ubah Kode'),
              _buildMenuItem('move', Icons.move_up_outlined, 'Pindahkan'),
            ],
          ),

          _buildSubMenu(
            icon: Icons.insert_drive_file_outlined,
            label: 'File & Dokumen',
            children: [
              if (!hasFile && canCreateFile)
                _buildMenuItem(
                  'create_file',
                  Icons.note_add_outlined,
                  'Buat File Otomatis',
                ),
              if (!hasFile)
                _buildMenuItem(
                  'set_file_path',
                  Icons.file_open_outlined,
                  'Tautkan File Manual',
                ),
              // FIX: Mengubah DiscussionLinkType.htmlLocal menjadi DiscussionLinkType.html sesuai model
              if (hasFile && linkType == DiscussionLinkType.html) ...[
                _buildMenuItem(
                  'edit_file',
                  Icons.edit_document,
                  'Edit File HTML',
                ),
                _buildMenuItem(
                  'generate_html',
                  Icons.auto_awesome_outlined,
                  'Regenerate HTML AI',
                ),
              ],
              if (hasFile)
                _buildMenuItem(
                  'remove_file_path',
                  Icons.link_off,
                  'Putus Tautan File',
                  color: Colors.red,
                ),
            ],
          ),

          if (linkType == DiscussionLinkType.perpuskuQuiz)
            _buildSubMenu(
              icon: Icons.quiz_outlined,
              label: 'Menu Kuis',
              children: [
                _buildMenuItem(
                  'add_quiz_question',
                  Icons.add_box_outlined,
                  'Tambah Soal',
                ),
                _buildMenuItem(
                  'generate_quiz_prompt',
                  Icons.psychology_outlined,
                  'Generate Prompt Kuis',
                ),
                _buildMenuItem(
                  'change_quiz_link',
                  Icons.edit_road_outlined,
                  'Ubah Link Folder',
                ),
              ],
            )
          // FIX: Mengubah DiscussionLinkType.htmlLocal menjadi DiscussionLinkType.html sesuai model
          else if (hasFile && linkType == DiscussionLinkType.html)
            _buildSubMenu(
              icon: Icons.extension_outlined,
              label: 'Ekstensi Modul',
              children: [
                _buildMenuItem(
                  'convert_to_quiz',
                  Icons.transform,
                  'Konversi ke Kuis',
                ),
                if (linkType != DiscussionLinkType.perpuskuQuiz)
                  _buildMenuItem(
                    'smart_link',
                    Icons.auto_awesome_outlined,
                    'Cari Tautan Cerdas',
                    color: Colors.amber,
                  ),
              ],
            ),

          const PopupMenuDivider(height: 8),
          if (isFinished)
            _buildMenuItem('reactivate', Icons.replay, 'Aktifkan Lagi')
          else
            _buildMenuItem(
              'finish',
              Icons.check_circle_outline,
              'Tandai Selesai',
            ),
          _buildMenuItem(
            'delete',
            Icons.delete_outline,
            'Hapus',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildSubMenu({
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<String>> children,
  }) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: EdgeInsets.zero,
      height: 40,
      child: SubmenuButton(
        menuChildren: children,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
