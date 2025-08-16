// lib/presentation/pages/2_subjects_page/widgets/subject_grid_tile.dart
import 'package:flutter/material.dart';
import '../../../../data/models/subject_model.dart';
import '../../3_discussions_page/utils/repetition_code_utils.dart';

class SubjectGridTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final bool isFocused; // ==> TAMBAHKAN PROPERTI isFocused

  const SubjectGridTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    this.isFocused = false, // ==> SET NILAI DEFAULT
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHidden = subject.isHidden;
    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;
    final bool hasSubtitle =
        subject.date != null || subject.repetitionCode != null;

    final tileContent = Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      subject.icon,
                      style: TextStyle(fontSize: 32, color: textColor),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'change_icon') onIconChange();
                      if (value == 'toggle_visibility') onToggleVisibility();
                      if (value == 'delete') onDelete();
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
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                subject.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 6),
                _buildSubtitle(context, textColor, 11),
              ],
              const SizedBox(height: 6),
              _buildStatsInfo(context, textColor),
              const Spacer(),
            ],
          ),
        ),
      ),
    );

    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // ==> TAMBAHKAN LOGIKA UNTUK BORDER <==
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }

  Widget _buildStatsInfo(BuildContext context, Color? textColor) {
    // ... (kode tidak berubah)
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 10, color: textColor);

    final codeEntries = subject.repetitionCodeCounts.entries.toList()
      ..sort(
        (a, b) => getRepetitionCodeIndex(
          a.key,
        ).compareTo(getRepetitionCodeIndex(b.key)),
      );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              '${subject.discussionCount} Discussions (${subject.finishedDiscussionCount} ✔)',
              style: textStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6.0,
          runSpacing: 2.0,
          alignment: WrapAlignment.center,
          children: codeEntries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();
            return Text.rich(
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
                    style: textStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    Color? textColor,
    double fontSize,
  ) {
    // ... (kode tidak berubah)
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
            const TextSpan(text: ' | '),
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
