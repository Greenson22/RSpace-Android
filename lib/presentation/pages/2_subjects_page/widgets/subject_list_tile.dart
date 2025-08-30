// lib/presentation/pages/2_subjects_page/widgets/subject_list_tile.dart
import 'package:flutter/material.dart';
import '../../../../data/models/subject_model.dart';
import '../../3_discussions_page/utils/repetition_code_utils.dart';

class SubjectListTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final VoidCallback onLinkPath;
  // ==> TAMBAHKAN CALLBACK BARU <==
  final VoidCallback onEditIndexFile;
  final bool isFocused;

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    required this.onLinkPath,
    // ==> TAMBAHKAN DI KONSTRUKTOR <==
    required this.onEditIndexFile,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasSubtitle =
        subject.date != null || subject.repetitionCode != null;
    final bool isHidden = subject.isHidden;
    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    final double verticalMargin = 8;
    final double horizontalMargin = 16;
    final EdgeInsets padding = const EdgeInsets.all(16.0);
    final double iconFontSize = 28;
    final double titleFontSize = 18;
    final double subtitleFontSize = 12;

    final tileContent = Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: theme.primaryColor.withOpacity(0.1),
        highlightColor: theme.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subject.icon,
                  style: TextStyle(fontSize: iconFontSize, color: textColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (subject.linkedPath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.link,
                              color: theme.primaryColor,
                              size: 18,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 4),
                      _buildSubtitle(context, textColor, subtitleFontSize),
                    ],
                    const SizedBox(height: 6),
                    _buildStatsRow(context, textColor),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                  if (value == 'change_icon') onIconChange();
                  if (value == 'toggle_visibility') onToggleVisibility();
                  if (value == 'link_path') onLinkPath();
                  // ==> TAMBAHKAN AKSI BARU <==
                  if (value == 'edit_index') onEditIndexFile();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Ubah Nama'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'change_icon',
                    child: Row(
                      children: [
                        Icon(Icons.emoji_emotions_outlined),
                        SizedBox(width: 8),
                        Text('Ubah Ikon'),
                      ],
                    ),
                  ),
                  // ==> TAMBAHKAN ITEM MENU BARU DI SINI <==
                  if (subject.linkedPath != null &&
                      subject.linkedPath!.isNotEmpty)
                    const PopupMenuItem<String>(
                      value: 'edit_index',
                      child: Row(
                        children: [
                          Icon(Icons.code_outlined),
                          SizedBox(width: 8),
                          Text('Edit Template Induk'),
                        ],
                      ),
                    ),
                  // ==> AKHIR PENAMBAHAN <==
                  PopupMenuItem<String>(
                    value: 'link_path',
                    child: Row(
                      children: [
                        const Icon(Icons.link_outlined),
                        const SizedBox(width: 8),
                        Text(
                          subject.linkedPath == null
                              ? 'Link ke PerpusKu'
                              : 'Ubah Link PerpusKu',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_visibility',
                    child: Row(
                      children: [
                        Icon(
                          isHidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Card(
      elevation: elevation,
      color: cardColor,
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }

  Widget _buildStatsRow(BuildContext context, Color? textColor) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 11, color: textColor);

    final codeEntries = subject.repetitionCodeCounts.entries.toList()
      ..sort(
        (a, b) => getRepetitionCodeIndex(
          a.key,
        ).compareTo(getRepetitionCodeIndex(b.key)),
      );

    return Row(
      children: [
        Icon(Icons.chat_bubble_outline, size: 12, color: textColor),
        const SizedBox(width: 4),
        Text(
          '${subject.discussionCount} (${subject.finishedDiscussionCount} ✔)',
          style: textStyle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: codeEntries.map((entry) {
                if (entry.value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${entry.key}:',
                          style: textStyle?.copyWith(
                            color: subject.isHidden
                                ? textColor
                                : getColorForRepetitionCode(entry.key),
                          ),
                        ),
                        TextSpan(
                          text: ' ${entry.value}',
                          style: textStyle?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    Color? textColor,
    double fontSize,
  ) {
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: fontSize, color: textColor),
        children: [
          if (subject.date != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: fontSize,
                  color: subject.isHidden ? textColor : Colors.amber[800],
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (subject.date != null)
            TextSpan(
              text: subject.date,
              style: TextStyle(
                color: subject.isHidden ? textColor : Colors.amber[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subject.date != null && subject.repetitionCode != null)
            const TextSpan(text: '  |  '),
          if (subject.repetitionCode != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.repeat,
                  size: fontSize,
                  color: subject.isHidden
                      ? textColor
                      : getColorForRepetitionCode(subject.repetitionCode!),
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (subject.repetitionCode != null)
            TextSpan(
              text: subject.repetitionCode,
              style: TextStyle(
                color: subject.isHidden
                    ? textColor
                    : getColorForRepetitionCode(subject.repetitionCode!),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
