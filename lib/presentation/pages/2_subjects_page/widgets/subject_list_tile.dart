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

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
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
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 4),
                      _buildSubtitle(context, textColor, subtitleFontSize),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                  if (value == 'change_icon') onIconChange();
                  if (value == 'toggle_visibility') onToggleVisibility();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Ubah Nama'),
                  ),
                  const PopupMenuItem(
                    value: 'change_icon',
                    child: Text('Ubah Ikon'),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_visibility',
                    child: Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
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
        side: BorderSide.none,
      ),
      child: tileContent,
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
