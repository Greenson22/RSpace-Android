// lib/features/content_management/presentation/subjects/widgets/subject_grid_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/subject_provider.dart';
import '../../../domain/models/subject_model.dart';
import '../../discussions/utils/repetition_code_utils.dart';

class SubjectGridTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final VoidCallback onLinkPath;
  final VoidCallback onEditIndexFile;
  final VoidCallback onMove; // ==> TAMBAHKAN CALLBACK BARU
  final bool isFocused;

  const SubjectGridTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    required this.onLinkPath,
    required this.onEditIndexFile,
    required this.onMove, // ==> TAMBAHKAN DI KONSTRUKTOR
    this.isFocused = false,
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          subject.icon,
                          style: TextStyle(fontSize: 32, color: textColor),
                        ),
                        if (subject.linkedPath != null)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Icon(
                              Icons.link,
                              color: theme.primaryColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'change_icon') onIconChange();
                      if (value == 'toggle_visibility') onToggleVisibility();
                      if (value == 'delete') onDelete();
                      if (value == 'link_path') onLinkPath();
                      if (value == 'edit_index') onEditIndexFile();
                      if (value == 'move') onMove(); // ==> TAMBAHKAN AKSI BARU
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
                      // ==> TAMBAHKAN ITEM MENU BARU DI SINI <==
                      const PopupMenuItem<String>(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.move_up_outlined),
                            SizedBox(width: 8),
                            Text('Pindahkan'),
                          ],
                        ),
                      ),
                      // ==> AKHIR PENAMBAHAN <==
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
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }

  Widget _buildStatsInfo(BuildContext context, Color? textColor) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 10, color: textColor);
    // ==> DAPATKAN URUTAN TAMPILAN DARI PROVIDER <==
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final displayOrder = provider.repetitionCodeDisplayOrder;

    final codeEntries = subject.repetitionCodeCounts.entries.toList()
      ..sort((a, b) {
        int indexA = displayOrder.indexOf(a.key);
        int indexB = displayOrder.indexOf(b.key);
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        return indexA.compareTo(indexB);
      });

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
