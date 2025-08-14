import 'package:flutter/material.dart';
import '../../../../data/models/subject_model.dart';
import '../../3_discussions_page/utils/repetition_code_utils.dart';

class SubjectListTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility; // ==> DITAMBAHKAN

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility, // ==> DITAMBAHKAN
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasSubtitle =
        subject.date != null || subject.repetitionCode != null;

    // ==> PERUBAHAN Tampilan untuk item yang tersembunyi <==
    final bool isHidden = subject.isHidden;
    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    return Card(
      elevation: elevation, // DIUBAH
      color: cardColor, // DIUBAH
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: theme.primaryColor.withOpacity(0.1),
        highlightColor: theme.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subject.icon,
                  style: TextStyle(fontSize: 28, color: textColor), // DIUBAH
                ),
              ),
              const SizedBox(width: 16),
              // Name and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor, // DIUBAH
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 4),
                      _buildSubtitle(context, textColor), // DIUBAH
                    ],
                  ],
                ),
              ),
              // Popup Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                  if (value == 'change_icon') onIconChange();
                  if (value == 'toggle_visibility') {
                    onToggleVisibility(); // ==> DIPANGGIL
                  }
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
                  // ==> OPSI MENU BARU <==
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
  }

  Widget _buildSubtitle(BuildContext context, Color? textColor) {
    // DIUBAH
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: textColor,
        ), // DIUBAH
        children: [
          if (subject.date != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: subject.isHidden
                      ? textColor
                      : Colors.amber[800], // DIUBAH
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (subject.date != null)
            TextSpan(
              text: subject.date,
              style: TextStyle(
                color: subject.isHidden
                    ? textColor
                    : Colors.amber[800], // DIUBAH
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
                  size: 12,
                  color: subject.isHidden
                      ? textColor
                      : getColorForRepetitionCode(
                          subject.repetitionCode!,
                        ), // DIUBAH
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
                    : getColorForRepetitionCode(
                        subject.repetitionCode!,
                      ), // DIUBAH
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
