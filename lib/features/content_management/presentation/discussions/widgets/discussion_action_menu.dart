// lib/features/content_management/presentation/discussions/widgets/discussion_action_menu.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

class DiscussionActionMenu extends StatelessWidget {
  final bool isFinished;
  final bool hasFile;
  final bool canCreateFile;
  final bool hasPoints;
  final DiscussionLinkType linkType;

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
  final VoidCallback onAddPerpuskuQuizQuestion;
  final VoidCallback onGenerateQuizPrompt;

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
    required this.onAddPerpuskuQuizQuestion,
    required this.onGenerateQuizPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final actions = {
          'add_point': onAddPoint,
          'rename': onRename,
          'move': onMove,
          'edit_date': onDateChange,
          'edit_code': onCodeChange,
          'create_file': onCreateFile,
          'set_file_path': onSetFilePath,
          'generate_html': onGenerateHtml,
          'edit_file_path': onEditFile,
          'remove_file_path': onRemoveFilePath,
          'finish': onFinish,
          'reactivate': onReactivate,
          'delete': onDelete,
          'smart_link': onSmartLink,
          'copy': onCopy,
          'reorder_points': onReorderPoints,
          'add_perpusku_quiz_question': onAddPerpuskuQuizQuestion,
          'generate_quiz_prompt': onGenerateQuizPrompt,
        };
        actions[value]?.call();
      },
      itemBuilder: (BuildContext context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    if (linkType == DiscussionLinkType.perpuskuQuiz) {
      return <PopupMenuEntry<String>>[
        _buildMenuItem(
          'add_perpusku_quiz_question',
          Icons.edit_note,
          // ==> PERUBAHAN LABEL DI SINI <==
          'Kelola Pertanyaan Kuis',
        ),
        _buildMenuItem('rename', Icons.drive_file_rename_outline, 'Ubah Nama'),
        _buildMenuItem('move', Icons.move_up_outlined, 'Pindahkan'),
        const PopupMenuDivider(),
        _buildMenuItem(
          'delete',
          Icons.delete_outline,
          'Hapus',
          color: Colors.red,
        ),
      ];
    }

    return <PopupMenuEntry<String>>[
      if (!isFinished)
        _buildMenuItem('add_point', Icons.add_comment_outlined, 'Tambah Poin'),
      if (!isFinished && hasPoints)
        _buildMenuItem('reorder_points', Icons.sort, 'Urutkan Poin'),
      _buildMenuItem('copy', Icons.copy_outlined, 'Salin Judul'),
      _buildMenuItem('move', Icons.move_up_outlined, 'Pindahkan'),
      _buildSubMenu(
        icon: Icons.edit_outlined,
        label: 'Edit',
        children: [
          _buildMenuItem(
            'rename',
            Icons.drive_file_rename_outline,
            'Ubah Nama',
          ),
          if (!hasPoints) ...[
            _buildMenuItem(
              'edit_date',
              Icons.calendar_today_outlined,
              'Ubah Tanggal',
            ),
            _buildMenuItem('edit_code', Icons.code, 'Ubah Kode Repetisi'),
          ],
        ],
      ),
      if (!isFinished)
        _buildSubMenu(
          icon: Icons.description_outlined,
          label: 'File & Kuis',
          children: [
            if (canCreateFile && !hasFile)
              _buildMenuItem(
                'create_file',
                Icons.note_add_outlined,
                'Buat File HTML Baru',
              ),
            _buildMenuItem(
              'set_file_path',
              hasFile
                  ? Icons.folder_open_outlined
                  : Icons.create_new_folder_outlined,
              hasFile ? 'Ubah Path File' : 'Set Path File',
            ),
            if (hasFile) ...[
              _buildMenuItem(
                'generate_html',
                Icons.auto_awesome_outlined,
                'Generate Konten (AI)',
              ),
              _buildMenuItem(
                'edit_file_path',
                Icons.edit_document,
                'Edit File Konten',
              ),
              const PopupMenuDivider(),
              _buildMenuItem(
                'generate_quiz_prompt',
                Icons.copy_all_outlined,
                'Buat Prompt Kuis (dari File)',
              ),
              const PopupMenuDivider(),
              _buildMenuItem(
                'remove_file_path',
                Icons.link_off,
                'Hapus Path File',
                color: Colors.orange,
              ),
            ] else ...[
              _buildMenuItem(
                'smart_link',
                Icons.auto_awesome_outlined,
                'Cari Tautan Cerdas',
                color: Colors.amber,
              ),
            ],
          ],
        ),
      const PopupMenuDivider(),
      if (isFinished)
        _buildMenuItem('reactivate', Icons.replay, 'Aktifkan Lagi')
      else
        _buildMenuItem('finish', Icons.check_circle_outline, 'Tandai Selesai'),
      _buildMenuItem(
        'delete',
        Icons.delete_outline,
        'Hapus',
        color: Colors.red,
      ),
    ];
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
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
      child: SubmenuButton(
        menuChildren: children,
        child: Row(
          children: [Icon(icon), const SizedBox(width: 8), Text(label)],
        ),
      ),
    );
  }
}
